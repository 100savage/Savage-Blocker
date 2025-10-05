#!/bin/bash

# The Savage Blocker -- a Debian/Ubuntu Tool (Version 2.8)
# This script prevents access to unwanted websites by merging blocklists from reputable sources.
# By Mike Savage (GNU/General Public License version 2.0)

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

# Function to pull blocked data list
data_pull() {
    (
    echo "0" ; echo "# Initializing..."
    echo "Starting data_pull" >> "$DEBUG_LOG"
    echo "Types selected: $types" >> "$DEBUG_LOG"

    # Use temporary files in /tmp to avoid deleting files in $BLOCKER_DIR
    TEMP_DIR=$(mktemp -d)
    echo "Using temporary directory: $TEMP_DIR" >> "$DEBUG_LOG"

    if [[ " ${types[@]} " =~ "  Reduce Ads and Malware" ]]; then
        echo "10" ; echo "# Downloading the Ads and Malware websites to block list..."
        if wget -O "$TEMP_DIR/hosts-malware" https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts >> "$DEBUG_LOG" 2>&1 && \
           sed -i '/#/d; /^\s*$/d; 1,14d' "$TEMP_DIR/hosts-malware" >> "$DEBUG_LOG" 2>&1; then
            sleep 1
        else
            echo "Warning: Failed to download Ads and Malware list." >> "$DEBUG_LOG"
        fi
    fi

    if [[ " ${types[@]} " =~ "  Reduce Ransomware websites" ]]; then
        echo "25" ; echo "# Downloading the Ransomware websites to block list..."
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

    if [[ " ${types[@]} " =~ "  Reduce Tracking websites" ]]; then
        echo "40" ; echo "# Downloading the Tracking websites to block list..."
        if wget -O "$TEMP_DIR/hosts-tracking" https://blocklistproject.github.io/Lists/tracking.txt >> "$DEBUG_LOG" 2>&1; then
            sleep 1
        else
            echo "Warning: Failed to download Tracking list." >> "$DEBUG_LOG"
        fi
    fi

    if [[ " ${types[@]} " =~ "  Reduce Pornography websites" ]]; then
        echo "55" ; echo "# Downloading the Pornography websites to block list..."
        if wget -O "$TEMP_DIR/hosts-porn" https://blocklistproject.github.io/Lists/porn.txt >> "$DEBUG_LOG" 2>&1; then
            sleep 1
        else
            echo "Warning: Failed to download Pornography list." >> "$DEBUG_LOG"
        fi
    fi

    if [[ " ${types[@]} " =~ "  Reduce Gambling websites" ]]; then
        echo "65" ; echo "# Downloading the Gambling websites to block list..."
        if wget -O "$TEMP_DIR/hosts-gambling" https://blocklistproject.github.io/Lists/gambling.txt >> "$DEBUG_LOG" 2>&1; then
            sleep 1
        else
            echo "Warning: Failed to download Gambling list." >> "$DEBUG_LOG"
        fi
    fi

    if [[ " ${types[@]} " =~ "  Reduce Social Media websites" ]]; then
        echo "80" ; echo "# Downloading the Social Media websites to block list..."
        if wget -O "$TEMP_DIR/hosts-social" https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/social-only/hosts >> "$DEBUG_LOG" 2>&1; then
            sleep 1
        else
            echo "Warning: Failed to download Social Media list." >> "$DEBUG_LOG"
        fi
    fi

    if [[ " ${types[@]} " =~ "  Help prevent Bitcoin Miners from accessing your system" ]]; then
        echo "90" ; echo "# Downloading the Bitcoin Miners websites to block list..."
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
    if cat "$TEMP_DIR/hosts-"* "$BLOCKER_DIR/extra" 2>/dev/null > "$TEMP_DIR/hosts-1" && \
       sed -i '/#/d; /^\s*$/d' "$TEMP_DIR/hosts-1" >> "$DEBUG_LOG" 2>&1 && \
       sort "$TEMP_DIR/hosts-1" | uniq > "$TEMP_DIR/hosts-2" && \
       cat "$BLOCKER_DIR/header" "$TEMP_DIR/hosts-2" > "$BLOCKER_DIR/hosts" && \
       sed -i "29i # Updated on $(date) #" "$BLOCKER_DIR/hosts" >> "$DEBUG_LOG" 2>&1 && \
       cp "$BLOCKER_DIR/hosts" /etc/hosts >> "$DEBUG_LOG" 2>&1; then
        echo "Hosts file updated successfully" >> "$DEBUG_LOG"
    else
        echo "Warning: Failed to update hosts file" >> "$DEBUG_LOG"
    fi

    # Clean up temporary directory
    rm -rf "$TEMP_DIR" >> "$DEBUG_LOG" 2>&1
    echo "Cleaned up temporary directory $TEMP_DIR" >> "$DEBUG_LOG"

    echo "100" ; echo "# Block lists download completed!"
    ) | zenity --progress --title="The Savage Spam Blocker: Your Ultimate Web Protection Tool!" --text="Initializing..." --width=530 --height=150 --percentage=0 --auto-close || {
        echo "Zenity progress dialog failed" >> "$DEBUG_LOG"
        echo "Error: Failed to display progress dialog. Check Zenity installation or display environment." >&2
        return 1
    }

    zenity --info --title="The Savage Spam Blocker: Your Ultimate Web Protection Tool!" --text="\nTo keep your system free from unwanted websites, run this app at least once a month.\n\nNew websites are getting added daily." --width=530 --height=150 --timeout=4 || {
        echo "Zenity info dialog failed" >> "$DEBUG_LOG"
    }
}

# Function to add a website to the block list
add_website() {
    echo "Starting add_website" >> "$DEBUG_LOG"
    website=$(zenity --entry --title="The Savage Spam Blocker: Your Ultimate Web Protection Tool!" --text="     Enter the full domain name of the website you want to block (e.g., example.com) \n     to prevent this computer from accessing the website.\n" --width=530 --height=150) || {
        echo "Zenity entry dialog failed" >> "$DEBUG_LOG"
        return
    }
    answer=$?
    if [ "$answer" -eq 0 ] && [ -n "$website" ]; then
        if echo "0.0.0.0 $website" >> "$BLOCKER_DIR/extra" 2>> "$DEBUG_LOG"; then
            zenity --info --title="The Savage Spam Blocker: Your Ultimate Web Protection Tool!" --text="\nThe website has been added to the block list.\n" --width=530 --height=100 --timeout=2 --icon-name=dialog-information || {
                echo "Zenity info dialog failed" >> "$DEBUG_LOG"
            }
        else
            echo "Failed to write to $BLOCKER_DIR/extra" >> "$DEBUG_LOG"
        fi
    fi
    types=$(zenity --list --checklist --title="The Savage Spam Blocker: Your Ultimate Web Protection Tool!" --text="Choose the types of websites to block:" \
        --column="" --column="  Website Type" \
        TRUE "  Reduce Ads and Malware" \
        TRUE "  Reduce Ransomware websites" \
        TRUE "  Reduce Tracking websites" \
        TRUE "  Reduce Pornography websites" \
        TRUE "  Reduce Gambling websites" \
        TRUE "  Reduce Social Media websites" \
        TRUE "  Help prevent Bitcoin Miners from accessing your system" --height=280 --width=530 --icon-name=dialog-question) || {
        echo "Zenity checklist dialog failed" >> "$DEBUG_LOG"
        return
    }
    echo "Selected types: $types" >> "$DEBUG_LOG"
    IFS="|" read -r -a types <<< "$types"
    data_pull
}

# Function to remove a blocked website
remove_domain() {
    echo "Starting remove_domain" >> "$DEBUG_LOG"
    domain=$(zenity --entry --title="The Savage Spam Blocker: Your Ultimate Web Protection Tool!" --text="     Enter the full domain name of the website\n     to unblock (e.g., example.com)") || {
        echo "Zenity entry dialog failed" >> "$DEBUG_LOG"
        return
    }
    if [[ -z "$domain" ]]; then
        zenity --error --title="The Savage Spam Blocker: Your Ultimate Web Protection Tool!" --text="No domain entered." --width=530 --height=100 || {
            echo "Zenity error dialog failed" >> "$DEBUG_LOG"
        }
        echo "No domain entered" >> "$DEBUG_LOG"
        return 1
    fi
    matching_lines=$(grep -F "$domain" /etc/hosts 2>> "$DEBUG_LOG")
    if [[ -z "$matching_lines" ]]; then
        zenity --info --title="The Savage Spam Blocker: Your Ultimate Web Protection Tool!" --text="The domain '$domain' was not found. Please verify your spelling." --width=530 --height=100 --timeout=4 || {
            echo "Zenity info dialog failed" >> "$DEBUG_LOG"
        }
        echo "Domain $domain not found in /etc/hosts" >> "$DEBUG_LOG"
        return 0
    fi
    zenity --info --title="The Savage Spam Blocker: Your Ultimate Web Protection Tool!" --text="This process may take some time. Please be patient.\n" --width=530 --height=100 --timeout=2 || {
        echo "Zenity info dialog failed" >> "$DEBUG_LOG"
    }
    temp_hosts_file=$(mktemp)
    if ! cp -a /etc/hosts "$temp_hosts_file" >> "$DEBUG_LOG" 2>&1; then
        echo "Failed to copy /etc/hosts to $temp_hosts_file" >> "$DEBUG_LOG"
        rm -f "$temp_hosts_file"
        zenity --error --title="The Savage Spam Blocker: Your Ultimate Web Protection Tool!" --text="Failed to copy /etc/hosts. Check permissions or run with sudo." --width=530 --height=100 || {
            echo "Zenity error dialog failed" >> "$DEBUG_LOG"
        }
        return 1
    fi
    while IFS= read -r line; do
        escaped_line=$(echo "$line" | sed 's/[\/&]/\\&/g')
        sed -i "/$escaped_line/d" "$temp_hosts_file" >> "$DEBUG_LOG" 2>&1
        sed -i "/$escaped_line/d" "$BLOCKER_DIR/extra" 2>> "$DEBUG_LOG"
    done <<< "$matching_lines"
    if ! cp -a "$temp_hosts_file" /etc/hosts >> "$DEBUG_LOG" 2>&1; then
        echo "Failed to copy $temp_hosts_file to /etc/hosts" >> "$DEBUG_LOG"
        rm -f "$temp_hosts_file"
        zenity --error --title="The Savage Spam Blocker: Your Ultimate Web Protection Tool!" --text="Failed to update /etc/hosts. Check permissions or run with sudo." --width=530 --height=100 || {
            echo "Zenity error dialog failed" >> "$DEBUG_LOG"
        }
        return 1
    fi
    rm -f "$temp_hosts_file"
    zenity --info --title="The Savage Spam Blocker: Your Ultimate Web Protection Tool!" --text="Lines containing the domain '$domain' have been removed. Try to access the website now." --width=530 --height=100 --timeout=4 || {
        echo "Zenity info dialog failed" >> "$DEBUG_LOG"
    }
}

# Function to reset hosts file
basic_host() {
    echo "Starting basic_host" >> "$DEBUG_LOG"
    if [ ! -f "$BLOCKER_DIR/blank" ]; then
        echo "Error: $BLOCKER_DIR/blank does not exist" >> "$DEBUG_LOG"
        zenity --error --title="The Savage Spam Blocker: Your Ultimate Web Protection Tool!" --text="Error: $BLOCKER_DIR/blank does not exist. Please create it with 'echo \"127.0.0.1 localhost\" > $BLOCKER_DIR/blank' and try again." --width=530 --height=100 || {
            echo "Zenity error dialog failed" >> "$DEBUG_LOG"
        }
        return 1
    fi
    if [ ! -w /etc/hosts ]; then
        echo "Error: /etc/hosts is not writable" >> "$DEBUG_LOG"
        zenity --error --title="The Savage Spam Blocker: Your Ultimate Web Protection Tool!" --text="Error: /etc/hosts is not writable. Fix permissions with 'sudo chmod u+w /etc/hosts' or run with sudo." --width=530 --height=100 || {
            echo "Zenity error dialog failed" >> "$DEBUG_LOG"
        }
        return 1
    fi
    if ! cp "$BLOCKER_DIR/blank" /etc/hosts >> "$DEBUG_LOG" 2>&1; then
        echo "Failed to copy $BLOCKER_DIR/blank to /etc/hosts" >> "$DEBUG_LOG"
        zenity --error --title="The Savage Spam Blocker: Your Ultimate Web Protection Tool!" --text="Failed to copy $BLOCKER_DIR/blank to /etc/hosts. Check permissions or run with sudo." --width=530 --height=100 || {
            echo "Zenity error dialog failed" >> "$DEBUG_LOG"
        }
        return 1
    fi
    zenity --warning --title="The Savage Spam Blocker: Your Ultimate Web Protection Tool!" --text="\nNo websites are being blocked. All files in $BLOCKER_DIR are preserved.\n" --width=530 --height=100 --timeout=3 --icon-name=dialog-warning || {
        echo "Zenity warning dialog failed" >> "$DEBUG_LOG"
    }
}

# Main menu
cmd1="data_pull"
cmd2="add_website"
cmd3="remove_domain"
cmd4="basic_host"
cmd5="exit"

name1="    Launch The Savage Blocker"
name2="    Add any website of your choice to block. The malicious domain list may be insufficient for you."
name3="    Remove a blocked website from the list. You may need to access a reliable website that is blocked."
name4="    Remove all website blocking"
name5="    Exit and do not change"

echo "Attempting to display main menu" >> "$DEBUG_LOG"
echo "Zenity command: zenity --list --radiolist --title=\"Welcome to The Savage Spam Blocker: Your Ultimate Web Protection Tool!\" --text=\"          This tool works to improve your online experience by enhancing privacy and website security, reducing\n          online annoyances and distractions, saving bandwidth, and speeding up the rate of web browsing.\" --column=\"\" --column=\"\" TRUE \"$name1\" FALSE \"$name2\" FALSE \"$name3\" FALSE \"$name4\" FALSE \"$name5\" --height=240 --width=700" >> "$DEBUG_LOG"
names=$(bash -c "zenity --list --radiolist --title=\"Welcome to The Savage Spam Blocker: Your Ultimate Web Protection Tool!\" --text=\"          This tool works to improve your online experience by enhancing privacy and website security, reducing\n          online annoyances and distractions, saving bandwidth, and speeding up the rate of web browsing.\" --column=\"\" --column=\"\" TRUE \"$name1\" FALSE \"$name2\" FALSE \"$name3\" FALSE \"$name4\" FALSE \"$name5\" --height=240 --width=700" 2>> "$DEBUG_LOG") || {
    echo "Zenity main menu dialog failed" >> "$DEBUG_LOG"
    echo "Error: Failed to display main menu. Check Zenity installation, display environment, or run with sudo." >&2
    exit 1
}
echo "Main menu selection: $names" >> "$DEBUG_LOG"

case "$names" in
    "$name1")
        types=$(zenity --list --checklist --title="The Savage Spam Blocker: Your Ultimate Web Protection Tool!" --text="Choose the types of websites you want to block:" \
            --column="" --column="  Website Type you want to block" \
            TRUE "  Reduce Ads and Malware" \
            TRUE "  Reduce Ransomware websites" \
            TRUE "  Reduce Tracking websites" \
            TRUE "  Reduce Pornography websites" \
            TRUE "  Reduce Gambling websites" \
            TRUE "  Reduce Social Media websites" \
            TRUE "  Help prevent Bitcoin Miners from accessing your system" --height=280 --width=530 --icon-name=dialog-question) || {
            echo "Zenity checklist dialog failed" >> "$DEBUG_LOG"
            exit 1
        }
        echo "Selected types: $types" >> "$DEBUG_LOG"
        IFS="|" read -r -a types <<< "$types"
        data_pull
        ;;
    "$name2") eval "$cmd2" ;;
    "$name3") eval "$cmd3" ;;
    "$name4") eval "$cmd4" ;;
    "$name5") exit 0 ;;
esac