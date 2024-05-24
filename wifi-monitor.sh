#!/bin/bash

# Check if the correct number of arguments is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <log_file>"
    exit 1
fi

# Assign argument to variable
LOG_FILE=$1

# Get the initial list of devices
INITIAL_DEVICES=$(arp-scan --localnet | grep -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}')

echo -e "Monitoring network for new devices...\n"
echo -e "Initial devices:\n$INITIAL_DEVICES\n"

# Print header for log file
echo -e "Timestamp\tIP Address\tMAC Address\tManufacturer" | tee -a "$LOG_FILE"

while true; do
    # Scan the network for devices
    CURRENT_DEVICES=$(arp-scan --localnet)

    # Extract MAC addresses and IP addresses
    CURRENT_MACS=$(echo "$CURRENT_DEVICES" | grep -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}')
    CURRENT_IPS=$(echo "$CURRENT_DEVICES" | grep -o -E '([0-9]{1,3}\.){3}[0-9]{1,3}')

    # Find new devices
    NEW_MACS=$(comm -13 <(echo "$INITIAL_DEVICES" | sort) <(echo "$CURRENT_MACS" | sort))

    if [ ! -z "$NEW_MACS" ]; then
        # Log the new devices with a timestamp
        for MAC in $NEW_MACS; do
            IP=$(echo "$CURRENT_DEVICES" | grep "$MAC" | awk '{print $1}')
            MANUFACTURER=$(arp-scan --localnet | grep "$MAC" | awk -F'\t' '{print $3}')
            TIMESTAMP=$(date)
            LOG_ENTRY="$TIMESTAMP\t$IP\t$MAC\t$MANUFACTURER"
            echo -e "$LOG_ENTRY" | tee -a "$LOG_FILE"
        done
        # Update the initial devices list
        INITIAL_DEVICES="$CURRENT_MACS"
    fi

    # Wait for a minute before scanning again
    sleep 60
done
