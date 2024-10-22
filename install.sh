#!/bin/bash

# Quit if any command returns a non-zero status (errors).
set -e

MBOT_TYPE=""

print_usage() {
    echo "Usage:"
    echo
    echo "  ./install.sh -t <TYPE>"
    echo
    echo "with <TYPE> set to either OMNI or DIFF."
}

while getopts ":t:" opt; do
    case $opt in
        t)
            MBOT_TYPE=$OPTARG
            ;;
        \?)
            echo "Invalid option: -$OPTARG"
            ;;
    esac
done

if [ -z "$MBOT_TYPE" ]; then
    echo "Error: MBot type is required."
    print_usage
    exit 1
fi

if [[ "$MBOT_TYPE" != "DIFF" ]] && [[ "$MBOT_TYPE" != "OMNI" ]]; then
    echo "Error: Unrecognized MBot type: $MBOT_TYPE"
    print_usage
    exit 1
fi

# Services to install.
SERVICE_LIST="mbot-motion-controller
              mbot-slam"

# First, stop the services.
for serv in $SERVICE_LIST
do
    if [ -f "/etc/systemd/system/$serv.service" ]; then
        echo "Stopping service $serv.service."
        sudo systemctl stop $serv.service
    fi
done

# Convert the type to lowercase to use as a suffix.
SUFFIX=$(echo "$MBOT_TYPE" | tr '[:upper:]' '[:lower:]')
echo "Installing MBot Autonomy binaries for MBot $MBOT_TYPE..."
echo

sudo cp mbot_slam_$SUFFIX /usr/local/bin/mbot_slam
sudo cp mbot_motion_controller_$SUFFIX /usr/local/bin/mbot_motion_controller

echo "Installed mbot_slam_$SUFFIX to /usr/local/bin/mbot_slam"
echo "Installed mbot_motion_controller_$SUFFIX to /usr/local/bin/mbot_motion_controller"

for serv in $SERVICE_LIST
do
    sudo cp services/$serv.service /etc/systemd/system/$serv.service
done

# Enable the services.
sudo systemctl daemon-reload

echo
if [[ "$@" == *"--no-enable"* ]]; then
    echo "Services installed but not enabled."
else
    echo "Enabling and starting services..."
    # Enable all the services.
    for serv in $SERVICE_LIST
    do
        sudo systemctl enable $serv.service
        sudo systemctl restart $serv.service
    done
fi

# Success message.
echo "Installed the following services:"
echo
for serv in $SERVICE_LIST
do
    echo "    $serv.service"
done
echo

echo "Done!"
