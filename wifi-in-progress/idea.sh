#!/bin/bash

# Function to enable Wi-Fi if it is off
enable_wifi_if_off() {
    current_status=$(nmcli radio wifi)
    if [ "$current_status" == "disabled" ]; then
        nmcli radio wifi on
        echo "Wi-Fi was off. Enabling Wi-Fi..."
        sleep 1  # Wait for a second to let Wi-Fi networks become available
    fi
}

# Function to toggle Wi-Fi on/off
toggle_wifi() {
    current_status=$(nmcli radio wifi)
    if [ "$current_status" == "enabled" ]; then
        nmcli radio wifi off
        echo "Wi-Fi turned off."
    else
        nmcli radio wifi on
        echo "Wi-Fi turned on."
    fi
}

# Function to enable airplane mode (turn off all radios)
airplane_mode() {
    nmcli radio all off
    echo "Airplane mode activated (all radios off)."
    exit 0
}

# Function to connect to a new Wi-Fi network with a password prompt
connect_to_new_network() {
    local network=$1
    echo -n "Enter password for $network: "
    read -s password  # Hide input while typing the password
    echo
    nmcli dev wifi connect "$network" password "$password"
    if [ $? -eq 0 ]; then
        echo "Successfully connected to $network."
    else
        echo "Failed to connect to $network. Check password or signal."
    fi
    read -n 1 -s -r -p "Press any key to close"
    exit 0
}

# Function to display connection options for a selected known network
network_options_menu() {
    local network=$1
    local options=("Connect to $network" "Delete $network" "Change password for $network" "Back to main menu")
    local current_index=0
    local num_options=${#options[@]}

    while true; do
        clear
        echo "Selected Network: $network"
        # Display the menu options, highlight the currently selected one
        for i in "${!options[@]}"; do
            if [ $i -eq $current_index ]; then
                echo -e "\033[1;32m> ${options[$i]}\033[0m"  # Highlight selected option
            else
                echo "  ${options[$i]}"
            fi
        done

        echo "Use 'j' to move down, 'k' to move up. Press Enter to select."

        # Capture user input for navigation
        read -rsn1 input
        case $input in
            j)  # Move down
                ((current_index = (current_index + 1) % num_options))
                ;;
            k)  # Move up
                ((current_index = (current_index - 1 + num_options) % num_options))
                ;;
            '') # Enter key
                case $current_index in
                    0)  # Connect to network
                        echo "Connecting to $network..."
                        nmcli dev wifi connect "$network"
                        read -n 1 -s -r -p "Press any key to return to the menu."
                        return 0
                        ;;
                    1)  # Delete network
                        echo "Deleting Wi-Fi network: $network"
                        nmcli connection delete "$network"
                        read -n 1 -s -r -p "Press any key to return to the menu."
                        return 0
                        ;;
                    2)  # Change password
                        echo "Changing password for $network"
                        echo -n "Enter new password: "
                        read -s new_password
                        echo
                        nmcli connection modify "$network" wifi-sec.key-mgmt wpa-psk
                        nmcli connection modify "$network" wifi-sec.psk "$new_password"
                        echo "Password updated successfully."
                        read -n 1 -s -r -p "Press any key to return to the menu."
                        return 0
                        ;;
                    3)  # Back to main menu
                        return 0
                        ;;
                esac
                ;;
        esac
    done
}


# Enable Wi-Fi if it is off at program start
enable_wifi_if_off

# Get known (saved) Wi-Fi networks
known_networks=($(nmcli connection show --active | grep wifi | awk '{print $1}'))

# Get all available Wi-Fi networks
all_networks=($(nmcli -f SSID dev wifi list | tail -n +2 | awk '{print $1}'))

# Get available networks that are not in known (saved) networks
unknown_networks=()
for network in "${all_networks[@]}"; do
    if [[ ! " ${known_networks[*]} " =~ " ${network} " ]]; then
        unknown_networks+=("$network")
    fi
done

# Add custom options for Wi-Fi Off, Airplane Mode, and Other Networks
menu_items=("Wi-Fi Off" "Airplane Mode" "${known_networks[@]}" "Other Networks")

# Menu navigation variables
current_index=0
num_items=${#menu_items[@]}

# Function to print the menu
print_menu() {
    clear
    echo "Use 'j' to move down, 'k' to move up. Press Enter to select."
    for i in "${!menu_items[@]}"; do
        if [ $i -eq $current_index ]; then
            echo -e "\033[1;32m> ${menu_items[$i]}\033[0m"  # Highlight the selected option
        else
            echo "  ${menu_items[$i]}"
        fi
    done
}

# Menu loop
while true; do
    print_menu
    read -rsn1 input  # Read single character input
    case $input in
        j)  # Move down
            ((current_index = (current_index + 1) % num_items))
            ;;
        k)  # Move up
            ((current_index = (current_index - 1 + num_items) % num_items))
            ;;
        '') # Enter key
            selected_item="${menu_items[$current_index]}"
            if [ "$selected_item" == "Wi-Fi Off" ]; then
                toggle_wifi
            elif [ "$selected_item" == "Airplane Mode" ]; then
                airplane_mode
            elif [ "$selected_item" == "Other Networks" ]; then
                if [ ${#unknown_networks[@]} -eq 0 ]; then
                    echo "No other networks available."
                    read -n 1 -s -r -p "Press any key to return to the menu."
                else
                    # Show a menu for "Other Networks"
                    while true; do
                        clear
                        echo "Other available networks:"
                        for i in "${!unknown_networks[@]}"; do
                            if [ $i -eq $current_index ]; then
                                echo -e "\033[1;32m> ${unknown_networks[$i]}\033[0m"
                            else
                                echo "  ${unknown_networks[$i]}"
                            fi
                        done
                        echo "Press 'Enter' to connect or 'b' to go back."
                        read -rsn1 input
                        if [[ $input == "b" ]]; then
                            break
                        elif [[ $input == "" ]]; then
                            connect_to_new_network "${unknown_networks[$current_index]}"
                            break
                        fi
                    done
                fi
            else
                network_options_menu "$selected_item"
            fi
            ;;
    esac
done

