#!/bin/bash

# The Savage Blocker (Version 3.0)
# A powerful tool for Linux systems to block ads, malware, and more.
# Licensed under the GNU General Public License v3.0
# Project: https://github.com/100savage/Savage-Blocker

# Debug log file
DEBUG_LOG="/tmp/savage-blocker.log"
echo "Script started at $(date)" > "$DEBUG_LOG"
echo "Environment: DISPLAY=$DISPLAY, PATH=$PATH" >> "$DEBUG_LOG"

# Check if zenity is installed
if ! command -v zenity >/dev/null 2>> "$DEBUG_LOG"; then
    echo "Zenity not found" >> "$DEBUG_LOG"
    echo "Error: Zenity is not installed. Please install it with 'sudo apt-get install zenity' and try again." >&2
    exit 1
fi
echo "Zenity check passed, version: $(zenity --version 2>> "$DEBUG_LOG")" >> "$DEBUG_LOG"

# Check and attempt to set display environment
if [ -z "$DISPLAY" ]; then
    echo "DISPLAY environment variable not set, attempting to set to :0" >> "$DEBUG_LOG"
    export DISPLAY=:0
    if ! xset q >/dev/null 2>> "$DEBUG_LOG"; then
        echo "Error: DISPLAY=:0 is invalid" >> "$DEBUG_LOG"
        echo "Error: No graphical display environment found. Please run this script in a graphical session (e.g., GNOME, KDE, XFCE) or enable X11 forwarding for SSH with 'ssh -X'. Alternatively, set DISPLAY manually (e.g., 'export DISPLAY=:0')." >&2
        exit 1
    fi
fi
echo "Display environment check passed: DISPLAY=$DISPLAY" >> "$DEBUG_LOG"

# Ensure blocker directory is writable
BLOCKER_DIR="/usr/share/blocker"
if [ ! -w "$BLOCKER_DIR" ]; then
    echo "Directory $BLOCKER_DIR is not writable" >> "$DEBUG_LOG"
    echo "Error: Directory $BLOCKER_DIR is not writable. Fix permissions with 'sudo chmod -R u+w $BLOCKER_DIR' or run with sudo." >&2
    exit 1
fi
echo "Directory $BLOCKER_DIR exists and is writable" >> "$DEBUG_LOG"

# Function to check for internet connectivity
check_connectivity() {
    echo "Checking internet connectivity..." >> "$DEBUG_LOG"
    if ! wget -q --spider example.com; then
        echo "No internet connectivity detected" >> "$DEBUG_LOG"
        zenity --error --title="The Savage Blocker" --text="No internet connection detected. Please check your network and try again." --width=400
        return 1
    fi
    echo "Internet connectivity confirmed" >> "$DEBUG_LOG"
    return 0
}

# Function to select website categories to block
select_categories() {
    types=$(zenity --list --checklist --title="The Savage Blocker" --text="Select categories to block:" \
        --column="Select" --column="Category" \
        TRUE "Ads and Malware" \
        TRUE "Ransomware" \
        TRUE "Tracking" \
        TRUE "Pornography" \
        TRUE "Gambling" \
        TRUE "Social Media" \
        TRUE "Bitcoin Miners" --height=350 --width=500) || {
        echo "Zenity checklist dialog failed" >> "$DEBUG_LOG"
        return 1
    }
    echo "Selected types: $types" >> "$DEBUG_LOG"
    IFS="|" read -r -a types <<< "$types"
    return 0
}

# Function to pull blocked data list
data_pull() {
    if ! check_connectivity; then
        return 1
    fi
    (
    echo "0" ; echo "# Initializing..."
    echo "Starting data_pull" >> "$DEBUG_LOG"
    echo "Types selected: $types" >> "$DEBUG_LOG"

    # Use temporary files in /tmp to avoid removing files in $BLOCKER_DIR
    TEMP_DIR=$(mktemp -d)
    echo "Using temporary directory: $TEMP_DIR" >> "$DEBUG_LOG"

    if [[ " ${types[@]} " =~ "Ads and Malware" ]]; then
        echo "10" ; echo "# Downloading Ads and Malware block lists..."
        if wget -O "$TEMP_DIR/hosts-malware" https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts >> "$DEBUG_LOG" 2>&1; then
            sleep 1
        else
            echo "Warning: Failed to download Ads and Malware list." >> "$DEBUG_LOG"
        fi
    fi

    if [[ " ${types[@]} " =~ "Ransomware" ]]; then
        echo "25" ; echo "# Downloading Ransomware block lists..."
        if wget -O "$TEMP_DIR/hosts-ransom" https://blocklistproject.github.io/Lists/ransomware.txt >> "$DEBUG_LOG" 2>&1; then
            sleep 1
        else
            echo "Warning: Failed to download Ransomware list." >> "$DEBUG_LOG"
        fi
        if wget -O "$TEMP_DIR/hosts-ransom1" https://blocklistproject.github.io/Lists/piracy.txt >> "$DEBUG_LOG" 2>&1; then
            sleep 1
        else
            echo "Warning: Failed to download Piracy list." >> "$DEBUG_LOG"
        fi
    fi

    if [[ " ${types[@]} " =~ "Tracking" ]]; then
        echo "40" ; echo "# Downloading Tracking block lists..."
        if wget -O "$TEMP_DIR/hosts-tracking" https://blocklistproject.github.io/Lists/tracking.txt >> "$DEBUG_LOG" 2>&1; then
            sleep 1
        else
            echo "Warning: Failed to download Tracking list." >> "$DEBUG_LOG"
        fi
    fi

    if [[ " ${types[@]} " =~ "Pornography" ]]; then
        echo "55" ; echo "# Downloading Pornography block lists..."
        if wget -O "$TEMP_DIR/hosts-porn" https://blocklistproject.github.io/Lists/porn.txt >> "$DEBUG_LOG" 2>&1; then
            sleep 1
        else
            echo "Warning: Failed to download Pornography list." >> "$DEBUG_LOG"
        fi
    fi

    if [[ " ${types[@]} " =~ "Gambling" ]]; then
        echo "65" ; echo "# Downloading Gambling block lists..."
        if wget -O "$TEMP_DIR/hosts-gambling" https://blocklistproject.github.io/Lists/gambling.txt >> "$DEBUG_LOG" 2>&1; then
            sleep 1
        else
            echo "Warning: Failed to download Gambling list." >> "$DEBUG_LOG"
        fi
    fi

    if [[ " ${types[@]} " =~ "Social Media" ]]; then
        echo "80" ; echo "# Downloading Social Media block lists..."
        if wget -O "$TEMP_DIR/hosts-social" https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/social-only/hosts >> "$DEBUG_LOG" 2>&1; then
            sleep 1
        else
            echo "Warning: Failed to download Social Media list." >> "$DEBUG_LOG"
        fi
    fi

    if [[ " ${types[@]} " =~ "Bitcoin Miners" ]]; then
        echo "90" ; echo "# Downloading Bitcoin Miners block lists..."
        if wget -O "$TEMP_DIR/hosts-bitcoin1" https://raw.githubusercontent.com/hoshsadiq/adblock-nocoin-list/master/hosts.txt >> "$DEBUG_LOG" 2>&1; then
            sleep 1
        else
            echo "Warning: Failed to download Bitcoin Miners list 1." >> "$DEBUG_LOG"
        fi
        if wget -O "$TEMP_DIR/hosts-bitcoin2" https://raw.githubusercontent.com/greatis/Anti-WebMiner/master/hosts >> "$DEBUG_LOG" 2>&1; then
            sleep 1
        else
            echo "Warning: Failed to download Bitcoin Miners list 2." >> "$DEBUG_LOG"
        fi
    fi

    echo "95" ; echo "# Configuring and cleaning up hosts file..."
    # Extract domains (0.0.0.0 domain or 127.0.0.1 domain) and format as 0.0.0.0 domain
    if cat "$TEMP_DIR/hosts-"* "$BLOCKER_DIR/extra" 2>/dev/null | \
       awk '/^(0\.0\.0\.0|127\.0\.0\.1) /' | \
       awk '{print "0.0.0.0 " $2}' | \
       awk '!/ (localhost|localhost\.localdomain|local)$/' | \
       sort | uniq > "$TEMP_DIR/hosts-2" && \
       cat "$BLOCKER_DIR/header" "$TEMP_DIR/hosts-2" > "$BLOCKER_DIR/hosts" && \
       sed -i "s/{{TIMESTAMP}}/# Updated on $(date) #/" "$BLOCKER_DIR/hosts" >> "$DEBUG_LOG" 2>&1 && \
       cp "$BLOCKER_DIR/hosts" /etc/hosts >> "$DEBUG_LOG" 2>&1; then
        echo "Hosts file updated successfully" >> "$DEBUG_LOG"
    else
        echo "Warning: Failed to update hosts file" >> "$DEBUG_LOG"
    fi

    # Clean up temporary directory
    rm -rf "$TEMP_DIR" >> "$DEBUG_LOG" 2>&1
    echo "Cleaned up temporary directory $TEMP_DIR" >> "$DEBUG_LOG"

    echo "100" ; echo "# Block lists updated successfully!"
    ) | zenity --progress --title="The Savage Blocker" --text="Initializing..." --width=500 --height=150 --percentage=0 --auto-close || {
        echo "Zenity progress dialog failed" >> "$DEBUG_LOG"
        echo "Error: Failed to display progress dialog. Check Zenity installation or display environment." >&2
        return 1
    }

    zenity --info --title="The Savage Blocker" --text="Block lists have been updated. Your system is now more secure.\n\nRun this tool monthly to stay up-to-date with the latest block lists." --width=500 --icon-name=dialog-information
}

# Function to add a website to the block list
add_website() {
    echo "Starting add_website" >> "$DEBUG_LOG"
    website=$(zenity --entry --title="The Savage Blocker" --text="Enter the domain name to block (e.g., example.com):" --width=400) || {
        echo "Zenity entry dialog failed" >> "$DEBUG_LOG"
        return
    }
    if [ -n "$website" ]; then
        if echo "0.0.0.0 $website" >> "$BLOCKER_DIR/extra" 2>> "$DEBUG_LOG"; then
            zenity --info --title="The Savage Blocker" --text="Domain '$website' added to block list." --width=400 --icon-name=dialog-information
        else
            echo "Failed to write to $BLOCKER_DIR/extra" >> "$DEBUG_LOG"
        fi
    fi
    if select_categories; then
        data_pull
    fi
}

# Function to remove a blocked website
remove_domain() {
    echo "Starting remove_domain" >> "$DEBUG_LOG"
    domain=$(zenity --entry --title="The Savage Blocker" --text="Enter the domain name to unblock (e.g., example.com):" --width=400) || {
        echo "Zenity entry dialog failed" >> "$DEBUG_LOG"
        return
    }
    if [[ -z "$domain" ]]; then
        zenity --error --title="The Savage Blocker" --text="No domain entered." --width=400
        echo "No domain entered" >> "$DEBUG_LOG"
        return 1
    fi

    # Escape domain for regex
    escaped_domain=$(echo "$domain" | sed 's/\./\\./g')

    if ! awk "/(^|[[:space:]])$escaped_domain([[:space:]]|$)/ {found=1; exit} END {exit !found}" /etc/hosts; then
        zenity --info --title="The Savage Blocker" --text="The domain '$domain' was not found in /etc/hosts." --width=400 --icon-name=dialog-information
        echo "Domain $domain not found in /etc/hosts" >> "$DEBUG_LOG"
        return 0
    fi

    if [ ! -w /etc/hosts ]; then
        zenity --error --title="The Savage Blocker" --text="Error: /etc/hosts is not writable. Please run with sudo." --width=400
        return 1
    fi

    zenity --info --title="The Savage Blocker" --text="Removing '$domain' from block lists. Please wait..." --width=400 --timeout=2

    # Remove from /etc/hosts
    sed -i -E "/(^|[[:space:]])$escaped_domain([[:space:]]|$)/d" /etc/hosts >> "$DEBUG_LOG" 2>&1
    # Remove from extra list
    sed -i -E "/(^|[[:space:]])$escaped_domain([[:space:]]|$)/d" "$BLOCKER_DIR/extra" >> "$DEBUG_LOG" 2>&1

    zenity --info --title="The Savage Blocker" --text="The domain '$domain' has been unblocked." --width=400 --icon-name=dialog-information
}

# Function to reset hosts file
basic_host() {
    echo "Starting basic_host" >> "$DEBUG_LOG"
    if [ ! -f "$BLOCKER_DIR/blank" ]; then
        echo "Error: $BLOCKER_DIR/blank does not exist" >> "$DEBUG_LOG"
        zenity --error --title="The Savage Blocker" --text="Error: $BLOCKER_DIR/blank does not exist." --width=400
        return 1
    fi
    if [ ! -w /etc/hosts ]; then
        echo "Error: /etc/hosts is not writable" >> "$DEBUG_LOG"
        zenity --error --title="The Savage Blocker" --text="Error: /etc/hosts is not writable. Please run with sudo." --width=400
        return 1
    fi
    if ! cp "$BLOCKER_DIR/blank" /etc/hosts >> "$DEBUG_LOG" 2>&1; then
        echo "Failed to copy $BLOCKER_DIR/blank to /etc/hosts" >> "$DEBUG_LOG"
        zenity --error --title="The Savage Blocker" --text="Failed to reset hosts file." --width=400
        return 1
    fi
    zenity --warning --title="The Savage Blocker" --text="Website blocking has been disabled. Your hosts file has been reset." --width=400 --icon-name=dialog-warning
}

# Main menu
name1="Update Block Lists"
name2="Add a Website to Block"
name3="Unblock a Website"
name4="Disable All Blocking"
name5="Exit"

echo "Attempting to display main menu" >> "$DEBUG_LOG"
names=$(zenity --list --radiolist --title="The Savage Blocker" \
    --text="Protect your system from ads, malware, and more.\nSelect an action:" \
    --column="Select" --column="Action" \
    TRUE "$name1" FALSE "$name2" FALSE "$name3" FALSE "$name4" FALSE "$name5" \
    --height=300 --width=500) || {
    echo "Zenity main menu dialog failed" >> "$DEBUG_LOG"
    echo "Error: Failed to display main menu. Check Zenity installation, display environment, or run with sudo." >&2
    exit 1
}
echo "Main menu selection: $names" >> "$DEBUG_LOG"

case "$names" in
    "$name1")
        if select_categories; then
            data_pull
        fi
        ;;
    "$name2") add_website ;;
    "$name3") remove_domain ;;
    "$name4") basic_host ;;
    "$name5") exit 0 ;;
esac
