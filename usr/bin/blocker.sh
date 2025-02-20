#!/bin/bash

# The Savage Blocker -- a Debian/Ubuntu Tool (Version 1.0)
# This Script will prevent access to unwanted websites.
# It gathers a merged collection from various sources.
# It includes lists from Steven Black, Malwaredomains,
# and other reputable sources.
# By Mike Savage (GNU/General Public License version 2.0)

# Check if zenity is installed, if not, install it
if [ ! -x "$(command -v zenity)" ]; then
  sudo apt-get -qq update && sudo apt-get install -yqq zenity
fi

# Function to pull blocked data list
data_pull() {
    (
    if [[ " ${types[@]} " =~ "  Reduce Ads and Malware" ]]; then
        echo "10" ; echo "# Downloading the Ads and Malware websites to block list..."
        wget -O /usr/share/blocker/hosts-malware https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts && sed -i '/#/d' /usr/share/blocker/hosts-malware && sed -i '/^\s*$/d' /usr/share/blocker/hosts-malware && sed -i '1,14d' /usr/share/blocker/hosts-malware && sleep 1
    fi

    if [[ " ${types[@]} " =~ "  Reduce Ransomware websites" ]]; then
        echo "25" ; echo "# Downloading the Ransomware websites to block list..."
        wget -O /usr/share/blocker/hosts-ransom https://raw.githubusercontent.com/blocklistproject/Lists/refs/heads/master/ransomware.txt && wget -O /usr/share/blocker/hosts-ransom1 https://raw.githubusercontent.com/blocklistproject/Lists/refs/heads/master/piracy.txt && sleep 1
    fi

    if [[ " ${types[@]} " =~ "  Reduce Tracking websites" ]]; then
        echo "40" ; echo "# Downloading the Tracking websites to block list..."
        wget -O /usr/share/blocker/hosts-tracking https://raw.githubusercontent.com/blocklistproject/Lists/refs/heads/master/tracking.txt && sleep 1
    fi

    if [[ " ${types[@]} " =~ "  Reduce Pornography websites" ]]; then
        echo "55" ; echo "# Downloading the Pornography websites to block list..."
        wget -O /usr/share/blocker/hosts-porn https://raw.githubusercontent.com/blocklistproject/Lists/refs/heads/master/porn.txt && sleep 1
    fi

    if [[ " ${types[@]} " =~ "  Reduce Gambling websites" ]]; then
        echo "65" ; echo "# Downloading the Gambling websites to block list..."
        wget -O /usr/share/blocker/hosts-gambling https://raw.githubusercontent.com/blocklistproject/Lists/refs/heads/master/gambling.txt && sleep 1
    fi

    if [[ " ${types[@]} " =~ "  Reduce Social Media websites" ]]; then
        echo "80" ; echo "# Downloading the Social Media websites to block list..."
        wget -O /usr/share/blocker/hosts-social https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/social-only/hosts && sleep 1
    fi

    if [[ " ${types[@]} " =~ "  Help prevent Bitcoin Miners from accessing your system" ]]; then
        echo "90" ; echo "# Downloading the Bitcoin Miners websites to block list..."
        wget -O /usr/share/blocker/hosts-bitcoin1 https://raw.githubusercontent.com/hoshsadiq/adblock-nocoin-list/master/hosts.txt
        wget -O /usr/share/blocker/hosts-bitcoin2 https://raw.githubusercontent.com/greatis/Anti-WebMiner/master/hosts && sleep 1
    fi
    echo "100" ; echo "# Block lists download completed!"
    ) | zenity --progress --title="The Savage Spam Blocker: Your Ultimate Web Protection Tool!" --text="Initializing..." --width=530 --height=150 --percentage=0 --auto-close && sleep 1

    # Hosts file configuration and Cleanup
    zenity --info --title="The Savage Spam Blocker: Your Ultimate Web Protection Tool!" --text="Configuring and cleaning up hosts file..." --width=530 --height=100 --timeout=2

    cat /usr/share/blocker/hosts-* > /usr/share/blocker/hosts-1
    cat /usr/share/blocker/extra >> /usr/share/blocker/hosts-1
    sed -i '/#/d' /usr/share/blocker/hosts-1
    sed -i '/^\s*$/d' /usr/share/blocker/hosts-1
    sort /usr/share/blocker/hosts-1 | uniq > /usr/share/blocker/hosts-2
    cat /usr/share/blocker/header /usr/share/blocker/hosts-2 > /usr/share/blocker/hosts
    sed -i "29i # Updated on $(date) #" /usr/share/blocker/hosts
    cp /usr/share/blocker/hosts /etc/
    rm -f /usr/share/blocker/hosts-*

    zenity --info --title="The Savage Spam Blocker: Your Ultimate Web Protection Tool!" --text="\nTo keep your system free from unwanted websites, run this app at least once a month.\n\nNew websites are getting added daily." --width=530 --height=150 --timeout=4
}

# Function to add a website to the block list
add_website() {
    website=$(zenity --entry --title="The Savage Spam Blocker: Your Ultimate Web Protection Tool!" --text="     Enter the full domain name of the website you want to block (e.g., example.com) \n     to prevent this computer from accessing the website.\n" --width=530 --height=150)
    answer=$?
    if [ "$answer" -eq 0 ]; then
        echo "0.0.0.0 $website" >> /usr/share/blocker/extra
        zenity --info --title="The Savage Spam Blocker: Your Ultimate Web Protection Tool!" --text="\nThe website has been added to the block list.\n" --width=530 --height=100 --timeout=2 --icon-name=dialog-information
    fi
    # Run the Launch The Savage Blocker selection after adding the website
    types=$(zenity --list --checklist --title="The Savage Spam Blocker: Your Ultimate Web Protection Tool!" --text="Choose the types of websites to block:" \
        --column="" --column="  Website Type" \
        TRUE "  Reduce Ads and Malware" \
        TRUE "  Reduce Ransomware websites" \
        TRUE "  Reduce Tracking websites" \
        TRUE "  Reduce Pornography websites" \
        TRUE "  Reduce Gambling websites" \
        TRUE "  Reduce Social Media websites" \
        TRUE "  Help prevent Bitcoin Miners from accessing your system" --height=280 --width=530 --icon-name=dialog-question)

    # Split the selected types into an array
    IFS="|" read -r -a types <<< "$types"
    data_pull
}

# Function no blocked websites
remove_domain() {
# Get the domain to search for from the user using zenity
    domain=$(zenity --entry --title="Remove a website that is blocked" --text "     Enter the full domain name of the website\n     you want to block (e.g., example.com)")

# Check if the user entered any domain
    if [[ -z "$domain" ]]; then
    zenity --error --text "No domain entered."
    exit 1
    fi

# Find lines containing the specified domain using grep
    matching_lines=$(grep -F "$domain" /etc/hosts)

# Check if any lines were found
    if [[ -z "$matching_lines" ]]; then
    zenity --info --text "The domain '$domain' was not found. Please verify your spelling."
    exit 0
    fi

# Inform the user that the process may take some time
    zenity --info --text "This process may take some time. Please be patient.\n" --timeout=2

# Create a temporary copy of /etc/hosts
    temp_hosts_file=$(mktemp)
    cp -a /etc/hosts "$temp_hosts_file"

# Delete the lines containing the domain from the temporary copy
    while IFS= read -r line; do
# Escape special characters in the line
    escaped_line=$(echo "$line" | sed 's/[\/&]/\\&/g')
    echo "Deleting line: ${line}" # Debugging line
    sed -i "/$escaped_line/d" "$temp_hosts_file"
    sed -i "/$escaped_line/d" "/usr/share/blocker/extra"
    done <<< "$matching_lines"

# Replace the original /etc/hosts file with the modified one
    sudo cp -a "$temp_hosts_file" /etc/hosts

# Inform the user of successful deletion
    zenity --info --text "Lines containing the domain '$domain' have been removed. Try to access the website now." --timeout=4

# Remove temporary files
    rm "$temp_hosts_file"
}

# Function no blocked websites
basic_host() {
    cat /usr/share/blocker/blank > /usr/share/blocker/hosts
    cp /usr/share/blocker/hosts /etc/
    zenity --warning --title="The Savage Spam Blocker: Your Ultimate Web Protection Tool!" --text="\nNo websites are being blocked.\n" --width=530 --height=100 --timeout=3 --icon-name=dialog-warning
}

# Ask question on how to proceed
cmd1="data_pull"
cmd2="add_website"
cmd3="remove_domain"
cmd4="basic_host"
cmd5="exit"

# Define friendly names for the commands
name1="    Launch The Savage Blocker"
name2="    Add any website of your choice to block. The malicious domain list may be insufficient for you."
name3="    Remove a blocked website from the list. You may need to access a reliable website that is blocked."
name4="    Remove all website blocking"
name5="    Exit and do not change"

# Intro - Use Zenity to create a radiolist dialog
names=$(zenity --list --radiolist --title="Welcome to The Savage Spam Blocker: Your Ultimate Web Protection Tool!" --text="          This tool works to improve your online experience by enhancing privacy and website security, reducing\n          online annoyances and distractions, saving bandwidth, and speeding up the rate of web browsing." \
    --column="" --column="" \
    TRUE "$name1" FALSE "$name2" FALSE "$name3" FALSE "$name4" FALSE "$name5" --height=240 --width=700)

# Execute the corresponding command for each selected name
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
            TRUE "  Help prevent Bitcoin Miners from accessing your system" --height=280 --width=530 --icon-name=dialog-question)

        # Split the selected types into an array
        IFS="|" read -r -a types <<< "$types"
        data_pull
        ;;
    "$name2") eval "$cmd2" ;;
    "$name3") eval "$cmd3" ;;
    "$name4") eval "$cmd4" ;;
    "$name4") eval "$cmd5" ;;
esac

