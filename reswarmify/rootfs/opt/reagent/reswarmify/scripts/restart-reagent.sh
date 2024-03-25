#!/bin/bash

LGFL="/var/log/nm-dispatcher.log"
schedule_lock_file="/opt/reagent/schedule-lock"

if [ -f "$schedule_lock_file" ]; then
    echo "A restart has already been scheduled" >>"${LGFL}"
    exit 0
fi

touch $schedule_lock_file
echo "Restarting reagent in 3 seconds..." >>"${LGFL}"

sleep 3
systemctl restart reagent

echo "Restarted the agent service!" >>"${LGFL}"

rm $schedule_lock_file
