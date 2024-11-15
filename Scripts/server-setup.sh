#!/bin/bash

# =========================================
#           Add user to sudoers
# =========================================

# Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root. Please run it with sudo or as the root user."
    exit 1
fi

# Check internet connection
if ping -c 1 google.com &> /dev/null; then
    echo "Internet is available."
else
    echo "No internet connection. Exiting..."
    exit 1
fi

echo -e "\033[0;35m"
cat << "EOF"
   ___      __   _                                     
  / _ \___ / /  (_)__ ____    ___ ___ _____  _____ ____
 / // / -_) _ \/ / _ `/ _ \  (_-</ -_) __/ |/ / -_) __/
/____/\__/_.__/_/\_,_/_//_/ /___/\__/_/  |___/\__/_/   
                                                       
EOF
echo -e "\033[0m"
echo -e "Welcome to Debian Installer!"
echo -e "This script will install everything for you. Sit back and relax."
sleep 5

echo "Running setup script as root."
apt install sudo

add_user_to_sudo() {
    local username=$1
    if id "$username" &>/dev/null; then
        if groups "$username" | grep -q '\bsudo\b'; then
            echo "$username is already in the sudo group. Skipping..."
            return 0  # User is already in the group, skip adding
        else
            echo "Adding $username to the sudo group..."
            /usr/sbin/usermod -aG sudo "$username"
            echo "$username has been added to the sudo group."
        fi
    else
        echo "User $username does not exist."
        return 1  # User does not exist
    fi
}

read -p "Enter the username to add to the sudo group: " username

# Add user to sudo group
add_user_to_sudo "$username"
