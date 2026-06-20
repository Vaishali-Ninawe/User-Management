#!/bin/bash

# Check if script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "Please run this script as root."
    exit 1
fi

LOGFILE="/var/log/user_management.log"

####################################################
# Password Validation Function
####################################################
validate_password() {
    local password="$1"

    if [[ ${#password} -lt 8 ]]; then
        echo "Password must be at least 8 characters long."
        return 1
    fi

    if [[ ! "$password" =~ [A-Z] ]]; then
        echo "Password must contain at least one uppercase letter."
        return 1
    fi

    if [[ ! "$password" =~ [a-z] ]]; then
        echo "Password must contain at least one lowercase letter."
        return 1
    fi

    if [[ ! "$password" =~ [0-9] ]]; then
        echo "Password must contain at least one number."
        return 1
    fi

    if [[ ! "$password" =~ [^a-zA-Z0-9] ]]; then
        echo "Password must contain at least one special character."
        return 1
    fi

    return 0
}

while true
do
    clear

    echo "==================================="
    echo "     User Management Automation"
    echo "==================================="
    echo "1. Create User"
    echo "2. Delete User"
    echo "3. Lock User"
    echo "4. Unlock User"
    echo "5. Reset Password"
    echo "6. Check User"
    echo "7. Exit"
    echo "==================================="

    read -p "Enter Choice: " choice

    case $choice in

####################################################
# Create User
####################################################
1)
    read -p "Enter username: " username

    if [[ -z "$username" ]]; then
        echo "Username cannot be empty."
        read -p "Press Enter to continue..."
        continue
    fi

    if id "$username" &>/dev/null
    then
        echo "User '$username' already exists."
    else
        if useradd -m "$username"
        then
            echo "User '$username' created successfully."

            while true
            do
                echo
                read -s -p "Enter Password: " password
                echo
                read -s -p "Confirm Password: " confirm
                echo

                if [[ "$password" != "$confirm" ]]; then
                    echo "Passwords do not match."
                    continue
                fi

                validate_password "$password"

                if [[ $? -eq 0 ]]; then
                    echo "$username:$password" | chpasswd

                    if [[ $? -eq 0 ]]; then
                        echo "Password set successfully."
                        echo "$(date): User '$username' created." >> "$LOGFILE"
                    else
                        echo "Failed to set password."
                    fi
                    break
                fi
            done
        else
            echo "Failed to create user."
        fi
    fi
    ;;

####################################################
# Delete User
####################################################
2)
    read -p "Enter username: " username

    if id "$username" &>/dev/null
    then
        if userdel -r "$username" &>/dev/null
        then
            echo "User '$username' deleted successfully."
            echo "$(date): User '$username' deleted." >> "$LOGFILE"
        else
            echo "Failed to delete user."
        fi
    else
        echo "User '$username' does not exist."
    fi
    ;;

####################################################
# Lock User
####################################################
3)
    read -p "Enter username: " username

    if id "$username" &>/dev/null
    then
        if passwd -S "$username" | grep -q " L "; then
            echo "User '$username' is already locked."
        else
            if passwd -l "$username" &>/dev/null
            then
                echo "User '$username' locked successfully."
                echo "$(date): User '$username' locked." >> "$LOGFILE"
            else
                echo "Failed to lock user."
            fi
        fi
    else
        echo "User '$username' does not exist."
    fi
    ;;

####################################################
# Unlock User
####################################################
4)
    read -p "Enter username: " username

    if id "$username" &>/dev/null
    then
        if passwd -S "$username" | grep -q " P "; then
            echo "User '$username' is already unlocked."
        else
            if passwd -u "$username" &>/dev/null
            then
                echo "User '$username' unlocked successfully."
                echo "$(date): User '$username' unlocked." >> "$LOGFILE"
            else
                echo "Failed to unlock user."
            fi
        fi
    else
        echo "User '$username' does not exist."
    fi
    ;;

####################################################
# Reset Password
####################################################
5)
    read -p "Enter username: " username

    if id "$username" &>/dev/null
    then
        while true
        do
            echo
            read -s -p "Enter New Password: " password
            echo
            read -s -p "Confirm New Password: " confirm
            echo

            if [[ "$password" != "$confirm" ]]; then
                echo "Passwords do not match."
                continue
            fi

            validate_password "$password"

            if [[ $? -eq 0 ]]; then
                echo "$username:$password" | chpasswd

                if [[ $? -eq 0 ]]; then
                    echo "Password reset successfully."
                    echo "$(date): Password reset for '$username'." >> "$LOGFILE"
                else
                    echo "Password reset failed."
                fi
                break
            fi
        done
    else
        echo "User '$username' does not exist."
    fi
    ;;

####################################################
# Check User
####################################################
6)
    read -p "Enter username: " username

    if id "$username" &>/dev/null
    then
        echo
        echo "User Details:"
        id "$username"
        echo
        passwd -S "$username"
    else
        echo "User '$username' does not exist."
    fi
    ;;

####################################################
# Exit
####################################################
7)
    echo "Exiting..."
    exit 0
    ;;

####################################################
# Invalid Choice
####################################################
*)
    echo "Invalid choice! Please enter a number between 1 and 7."
    ;;
esac

echo
read -p "Press Enter to continue..."

done
