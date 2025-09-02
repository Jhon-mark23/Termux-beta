#!/bin/bash

# Storage file for DNS and NameServer
DNS_FILE="dns_data.txt"

# Default settings
DIG_INTERVAL=3  # Default dig interval in seconds
SCRIPT_VERSION="1.9"  # Updated version

# ANSI color codes
GREEN="\e[32m" YELLOW="\e[33m" RED="\e[31m" BLUE="\e[34m" CYAN="\e[36m" MAGENTA="\e[35m" RESET="\e[0m"

# GitHub raw URL for updates
SCRIPT_URL="https://raw.githubusercontent.com/Jhon-mark23/Termux-beta/Test/install.sh"
BIN_PATH="/data/data/com.termux/files/usr/bin/menu"

# Load DNS and NS from file
declare -a DNS_LIST NS_LIST
if [[ -f "$DNS_FILE" ]]; then
    if ! source "$DNS_FILE" 2>/dev/null; then
        echo -e "${RED}Error: Corrupted or invalid $DNS_FILE. Starting with empty lists.${RESET}"
        DNS_LIST=()
        NS_LIST=()
    fi
else
    DNS_LIST=()
    NS_LIST=()
fi

# Save DNS and NS to file
save_data() {
    echo "DNS_LIST=(${DNS_LIST[@]})" > "$DNS_FILE"
    echo "NS_LIST=(${NS_LIST[@]})" >> "$DNS_FILE"
}

# Function to validate IP address
validate_ip() {
    local ip=$1
    if [[ $ip =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        IFS='.' read -r -a octets <<< "$ip"
        for octet in "${octets[@]}"; do
            if (( octet < 0 || octet > 255 )); then
                return 1
            fi
        done
        return 0
    else
        return 1
    fi
}

# Function to validate domain
validate_domain() {
    local domain=$1
    if [[ $domain =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        return 0
    else
        return 1
    fi
}

# Function to check dependencies
check_dependencies() {
    local deps=("dig" "ping" "curl")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            echo -e "${RED}Error: $dep is not installed. Please install it and try again.${RESET}"
            exit 1
        fi
    done
}

# Function to display the main menu
main_menu() {
    clear
    echo -e "${MAGENTA}=========================================${RESET}"
    echo -e "     ${CYAN}GTM DNSTT${RESET}"
    echo -e "${MAGENTA}=========================================${RESET}"
    echo -e "${BLUE}1)${RESET} DNS Settings"
    echo -e "${BLUE}2)${RESET} NS Settings"
    echo -e "${BLUE}3)${RESET} Set Dig Interval"
    echo -e "${BLUE}4)${RESET} Start"
    echo -e "${BLUE}5)${RESET} Update Script"
    echo -e "${BLUE}6)${RESET} Exit"
    echo -e "${MAGENTA}-----------------------------------------${RESET}"
    echo -e "${YELLOW}Stored DNS IPs:${RESET} ${#DNS_LIST[@]} (${DNS_LIST[*]})"
    echo -e "${YELLOW}Stored NameServers:${RESET} ${#NS_LIST[@]} (${NS_LIST[*]})"
    echo -e "${YELLOW}Interval:${RESET} ${DIG_INTERVAL} sec"
    echo -e "${YELLOW}Version:${RESET} $SCRIPT_VERSION"
    echo -e "${MAGENTA}=========================================${RESET}"
    echo -n "Choose an option (Press Enter to Start Checking): "
    read -r option

    case $option in
        1) dns_settings_menu ;;
        2) ns_settings_menu ;;
        3) set_interval ;;
        4) start_dig ;;
        5) update_script ;;
        6) exit 0 ;;
        "") start_dig ;;
        *) main_menu ;;
    esac
}

# DNS Settings submenu
dns_settings_menu() {
    clear
    echo -e "${MAGENTA}=========================================${RESET}"
    echo -e "     ${CYAN}DNS Settings${RESET}"
    echo -e "${MAGENTA}=========================================${RESET}"
    echo -e "${BLUE}1)${RESET} Add DNS IP"
    echo -e "${BLUE}2)${RESET} List DNS IPs"
    echo -e "${BLUE}3)${RESET} Edit DNS IP"
    echo -e "${BLUE}4)${RESET} Delete DNS IP"
    echo -e "${BLUE}5)${RESET} Back to Main Menu"
    echo -e "${MAGENTA}=========================================${RESET}"
    echo -n "Choose an option: "
    read -r option

    case $option in
        1) add_dns ;;
        2) list_dns ;;
        3) edit_dns ;;
        4) delete_dns ;;
        5) main_menu ;;
        *) dns_settings_menu ;;
    esac
}

# NS Settings submenu
ns_settings_menu() {
    clear
    echo -e "${MAGENTA}=========================================${RESET}"
    echo -e "     ${CYAN}NS Settings${RESET}"
    echo -e "${MAGENTA}=========================================${RESET}"
    echo -e "${BLUE}1)${RESET} Add NameServer"
    echo -e "${BLUE}2)${RESET} List NameServers"
    echo -e "${BLUE}3)${RESET} Edit NameServer"
    echo -e "${BLUE}4)${RESET} Delete NameServer"
    echo -e "${BLUE}5)${RESET} Back to Main Menu"
    echo -e "${MAGENTA}=========================================${RESET}"
    echo -n "Choose an option: "
    read -r option

    case $option in
        1) add_ns ;;
        2) list_ns ;;
        3) edit_ns ;;
        4) delete_ns ;;
        5) main_menu ;;
        *) ns_settings_menu ;;
    esac
}

# Function to add a DNS IP
add_dns() {
    echo -n "Enter DNS IP: "
    read -r dns
    if validate_ip "$dns"; then
        if [[ " ${DNS_LIST[*]} " =~ " $dns " ]]; then
            echo -e "${RED}DNS IP already exists!${RESET}"
        else
            DNS_LIST+=("$dns")
            # Add empty NS if needed to keep arrays aligned
            if [[ ${#NS_LIST[@]} -lt ${#DNS_LIST[@]} ]]; then
                NS_LIST+=("")
            fi
            save_data
            echo -e "${GREEN}DNS IP added successfully!${RESET}"
        fi
    else
        echo -e "${RED}Invalid IP address!${RESET}"
    fi
    sleep 1
    dns_settings_menu
}

# Function to add a NameServer
add_ns() {
    echo -n "Enter NameServer: "
    read -r ns
    if validate_domain "$ns"; then
        if [[ " ${NS_LIST[*]} " =~ " $ns " ]]; then
            echo -e "${RED}NameServer already exists!${RESET}"
        else
            NS_LIST+=("$ns")
            # Add empty DNS if needed to keep arrays aligned
            if [[ ${#DNS_LIST[@]} -lt ${#NS_LIST[@]} ]]; then
                DNS_LIST+=("")
            fi
            save_data
            echo -e "${GREEN}NameServer added successfully!${RESET}"
        fi
    else
        echo -e "${RED}Invalid domain name!${RESET}"
    fi
    sleep 1
    ns_settings_menu
}

# Function to list DNS IPs
list_dns() {
    clear
    echo -e "${MAGENTA}=========================================${RESET}"
    echo -e "     ${CYAN}Stored DNS IPs${RESET}"
    echo -e "${MAGENTA}=========================================${RESET}"
    
    if [[ ${#DNS_LIST[@]} -eq 0 ]]; then
        echo -e "${YELLOW}No DNS IPs stored.${RESET}"
    else
        for i in "${!DNS_LIST[@]}"; do
            [[ -n "${DNS_LIST[i]}" ]] && echo -e "${BLUE}$((i+1)))${RESET} ${DNS_LIST[i]}"
        done
    fi
    
    echo -e "${MAGENTA}=========================================${RESET}"
    echo -n "Press Enter to return to DNS settings..."
    read -r
    dns_settings_menu
}

# Function to list NameServers
list_ns() {
    clear
    echo -e "${MAGENTA}=========================================${RESET}"
    echo -e "     ${CYAN}Stored NameServers${RESET}"
    echo -e "${MAGENTA}=========================================${RESET}"
    
    if [[ ${#NS_LIST[@]} -eq 0 ]]; then
        echo -e "${YELLOW}No NameServers stored.${RESET}"
    else
        for i in "${!NS_LIST[@]}"; do
            [[ -n "${NS_LIST[i]}" ]] && echo -e "${BLUE}$((i+1)))${RESET} ${NS_LIST[i]}"
        done
    fi
    
    echo -e "${MAGENTA}=========================================${RESET}"
    echo -n "Press Enter to return to NS settings..."
    read -r
    ns_settings_menu
}

# Function to edit a DNS IP
edit_dns() {
    clear
    echo -e "${MAGENTA}=========================================${RESET}"
    echo -e "     ${CYAN}Edit DNS IP${RESET}"
    echo -e "${MAGENTA}=========================================${RESET}"
    
    if [[ ${#DNS_LIST[@]} -eq 0 ]]; then
        echo -e "${YELLOW}No DNS IPs stored.${RESET}"
        echo -e "${MAGENTA}=========================================${RESET}"
        sleep 1
        dns_settings_menu
    fi
    
    for i in "${!DNS_LIST[@]}"; do
        [[ -n "${DNS_LIST[i]}" ]] && echo -e "${BLUE}$((i+1)))${RESET} ${DNS_LIST[i]}"
    done
    
    echo -e "${MAGENTA}=========================================${RESET}"
    echo -n "Enter the number of the DNS IP to edit: "
    read -r index
    
    if [[ ! "$index" =~ ^[0-9]+$ ]] || [[ "$index" -lt 1 ]] || [[ "$index" -gt ${#DNS_LIST[@]} ]] || [[ -z "${DNS_LIST[$((index-1))]}" ]]; then
        echo -e "${RED}Invalid selection!${RESET}"
        sleep 1
        dns_settings_menu
    fi
    
    echo -n "Enter new DNS IP: "
    read -r new_dns
    if validate_ip "$new_dns"; then
        if [[ " ${DNS_LIST[*]} " =~ " $new_dns " && "${DNS_LIST[$((index-1))]}" != "$new_dns" ]]; then
            echo -e "${RED}DNS IP already exists!${RESET}"
        else
            DNS_LIST[$((index-1))]="$new_dns"
            save_data
            echo -e "${GREEN}DNS IP updated successfully!${RESET}"
        fi
    else
        echo -e "${RED}Invalid IP address!${RESET}"
    fi
    sleep 1
    dns_settings_menu
}

# Function to edit a NameServer
edit_ns() {
    clear
    echo -e "${MAGENTA}=========================================${RESET}"
    echo -e "     ${CYAN}Edit NameServer${RESET}"
    echo -e "${MAGENTA}=========================================${RESET}"
    
    if [[ ${#NS_LIST[@]} -eq 0 ]]; then
        echo -e "${YELLOW}No NameServers stored.${RESET}"
        echo -e "${MAGENTA}=========================================${RESET}"
        sleep 1
        ns_settings_menu
    fi
    
    for i in "${!NS_LIST[@]}"; do
        [[ -n "${NS_LIST[i]}" ]] && echo -e "${BLUE}$((i+1)))${RESET} ${NS_LIST[i]}"
    done
    
    echo -e "${MAGENTA}=========================================${RESET}"
    echo -n "Enter the number of the NameServer to edit: "
    read -r index
    
    if [[ ! "$index" =~ ^[0-9]+$ ]] || [[ "$index" -lt 1 ]] || [[ "$index" -gt ${#NS_LIST[@]} ]] || [[ -z "${NS_LIST[$((index-1))]}" ]]; then
        echo -e "${RED}Invalid selection!${RESET}"
        sleep 1
        ns_settings_menu
    fi
    
    echo -n "Enter new NameServer: "
    read -r new_ns
    if validate_domain "$new_ns"; then
        if [[ " ${NS_LIST[*]} " =~ " $new_ns " && "${NS_LIST[$((index-1))]}" != "$new_ns" ]]; then
            echo -e "${RED}NameServer already exists!${RESET}"
        else
            NS_LIST[$((index-1))]="$new_ns"
            save_data
            echo -e "${GREEN}NameServer updated successfully!${RESET}"
        fi
    else
        echo -e "${RED}Invalid domain name!${RESET}"
    fi
    sleep 1
    ns_settings_menu
}

# Function to delete a DNS IP
delete_dns() {
    clear
    echo -e "${MAGENTA}=========================================${RESET}"
    echo -e "     ${CYAN}Delete DNS IP${RESET}"
    echo -e "${MAGENTA}=========================================${RESET}"
    
    if [[ ${#DNS_LIST[@]} -eq 0 ]]; then
        echo -e "${YELLOW}No DNS IPs stored.${RESET}"
        echo -e "${MAGENTA}=========================================${RESET}"
        sleep 1
        dns_settings_menu
    fi
    
    for i in "${!DNS_LIST[@]}"; do
        [[ -n "${DNS_LIST[i]}" ]] && echo -e "${BLUE}$((i+1)))${RESET} ${DNS_LIST[i]}"
    done
    
    echo -e "${MAGENTA}=========================================${RESET}"
    echo -n "Enter the number of the DNS IP to delete: "
    read -r index
    
    if [[ ! "$index" =~ ^[0-9]+$ ]] || [[ "$index" -lt 1 ]] || [[ "$index" -gt ${#DNS_LIST[@]} ]] || [[ -z "${DNS_LIST[$((index-1))]}" ]]; then
        echo -e "${RED}Invalid selection!${RESET}"
        sleep 1
        dns_settings_menu
    fi
    
    # Create new arrays without the deleted item
    local new_dns_list=() new_ns_list=()
    for i in "${!DNS_LIST[@]}"; do
        if [[ $((i+1)) -ne $index ]]; then
            new_dns_list+=("${DNS_LIST[i]}")
            new_ns_list+=("${NS_LIST[i]}")
        fi
    done
    
    # Replace the original arrays
    DNS_LIST=("${new_dns_list[@]}")
    NS_LIST=("${new_ns_list[@]}")
    
    save_data
    echo -e "${GREEN}DNS IP deleted successfully!${RESET}"
    sleep 1
    dns_settings_menu
}

# Function to delete a NameServer
delete_ns() {
    clear
    echo -e "${MAGENTA}=========================================${RESET}"
    echo -e "     ${CYAN}Delete NameServer${RESET}"
    echo -e "${MAGENTA}=========================================${RESET}"
    
    if [[ ${#NS_LIST[@]} -eq 0 ]]; then
        echo -e "${YELLOW}No NameServers stored.${RESET}"
        echo -e "${MAGENTA}=========================================${RESET}"
        sleep 1
        ns_settings_menu
    fi
    
    for i in "${!NS_LIST[@]}"; do
        [[ -n "${NS_LIST[i]}" ]] && echo -e "${BLUE}$((i+1)))${RESET} ${NS_LIST[i]}"
    done
    
    echo -e "${MAGENTA}=========================================${RESET}"
    echo -n "Enter the number of the NameServer to delete: "
    read -r index
    
    if [[ ! "$index" =~ ^[0-9]+$ ]] || [[ "$index" -lt 1 ]] || [[ "$index" -gt ${#NS_LIST[@]} ]] || [[ -z "${NS_LIST[$((index-1))]}" ]]; then
        echo -e "${RED}Invalid selection!${RESET}"
        sleep 1
        ns_settings_menu
    fi
    
    # Create new arrays without the deleted item
    local new_dns_list=() new_ns_list=()
    for i in "${!NS_LIST[@]}"; do
        if [[ $((i+1)) -ne $index ]]; then
            new_dns_list+=("${DNS_LIST[i]}")
            new_ns_list+=("${NS_LIST[i]}")
        fi
    done
    
    # Replace the original arrays
    DNS_LIST=("${new_dns_list[@]}")
    NS_LIST=("${new_ns_list[@]}")
    
    save_data
    echo -e "${GREEN}NameServer deleted successfully!${RESET}"
    sleep 1
    ns_settings_menu
}

# Function to set the Dig Interval
set_interval() {
    echo -n "Enter dig interval (0-10s): "
    read -r new_interval
    if [[ "$new_interval" =~ ^[0-9]+$ ]]; then
        if (( new_interval < 0 )); then
            DIG_INTERVAL=0
        elif (( new_interval > 10 )); then
            DIG_INTERVAL=10
        else
            DIG_INTERVAL=$new_interval
        fi
        echo -e "${GREEN}Interval set to ${DIG_INTERVAL} seconds.${RESET}"
    else
        echo -e "${RED}Invalid input. Please enter a number between 0 and 10.${RESET}"
    fi
    sleep 1
    main_menu
}

# Function to start checking DNS
start_dig() {
    check_dependencies
    clear
    echo -e "${MAGENTA}=========================================${RESET}"
    echo -e "       ${CYAN}GTM DNSTT SCRIPT START${RESET}"
    echo -e "${MAGENTA}=========================================${RESET}"
    
    if [[ ${#DNS_LIST[@]} -eq 0 ]]; then
        echo -e "${YELLOW}No DNS IPs to check. Please add some first.${RESET}"
        echo -e "${MAGENTA}=========================================${RESET}"
        sleep 2
        main_menu
    fi
    
    echo -e "Checking every ${YELLOW}${DIG_INTERVAL}${RESET} seconds..."
    echo -e "${MAGENTA}-----------------------------------------${RESET}"

    # Handle CTRL+C (SIGINT) to return to menu
    trap 'clear; main_menu' SIGINT

    # Handle CTRL+X (SIGTSTP) to exit logs
    trap 'clear; exit 0' SIGTSTP

    while true; do
        SUCCESS_COUNT=0
        FAIL_COUNT=0
        
        # Print timestamp for this iteration
        echo -e "${CYAN}Check at $(date "+%Y-%m-%d %H:%M:%S")${RESET}"

        for ((i = 0; i < ${#DNS_LIST[@]}; i++)); do
            DNS_IP="${DNS_LIST[i]}"
            NS="${NS_LIST[i]:-google.com}"

            # Skip empty DNS entries
            if [[ -z "$DNS_IP" ]]; then
                continue
            fi

            # Run dig to check if it resolves
            DIG_OUTPUT=$(dig @"$DNS_IP" "$NS" +noall +stats 2>/dev/null)
            # Check if dig was successful (non-empty output indicates success)
            if [[ -n "$DIG_OUTPUT" ]]; then
                STATUS="${GREEN}✔ SUCCESS${RESET}"
                ((SUCCESS_COUNT++))
            else
                STATUS="${RED}✖ FAILED${RESET}"
                ((FAIL_COUNT++))
            fi

            # Run ping test
            PING_OUTPUT=$(ping -c 1 -W 1 "$DNS_IP" 2>/dev/null | grep "time=" | awk -F'time=' '{print $2}' | awk '{print $1}')

            # Set default value if empty
            [[ -z "$PING_OUTPUT" ]] && PING_OUTPUT="N/A"

            # Get colored output for ping
            PING_TIME_COLOR=$(get_color "$PING_OUTPUT")

            # Display results
            echo -e "DNS IP: ${BLUE}$DNS_IP${RESET} | NameServer: ${YELLOW}$NS${RESET}"
            echo -e "Status: $STATUS | Ping: ${PING_TIME_COLOR}"
            echo -e "${MAGENTA}-----------------------------------------${RESET}"
        done

        echo -e "Total Success: ${GREEN}$SUCCESS_COUNT${RESET} | Total Failed: ${RED}$FAIL_COUNT${RESET}"
        echo -e "${MAGENTA}-----------------------------------------${RESET}"
        echo -e "${CYAN}Press Ctrl+C to return to the menu or Ctrl+X to exit.${RESET}"
        echo ""  # Add a blank line for readability

        # Sleep only if interval is > 0
        (( DIG_INTERVAL > 0 )) && sleep "$DIG_INTERVAL"
    done
}

# Function to determine color based on value
get_color() {
    local value=$1
    if [[ -z "$value" || "$value" == "N/A" ]]; then
        echo -e "${RED}${value}${RESET}"  # Red for failed
    else
        # Remove non-numeric characters (like decimal points) for comparison
        local numeric_value=$(echo "$value" | sed 's/[^0-9.]//g')
        
        # Use bc for floating point comparison
        if (( $(echo "$numeric_value <= 50" | bc -l) )); then
            echo -e "${GREEN}${value}ms${RESET}"  # Green for fast response
        elif (( $(echo "$numeric_value > 50 && $numeric_value <= 100" | bc -l) )); then
            echo -e "${YELLOW}${value}ms${RESET}"  # Yellow for moderate response
        else
            echo -e "${RED}${value}ms${RESET}"  # Red for slow response
        fi
    fi
}

# Function to update the script
update_script() {
    echo -e "${YELLOW}Checking for updates...${RESET}"
    # Download the new script to a temporary file
    TEMP_SCRIPT=$(mktemp)
    if curl -s -o "$TEMP_SCRIPT" "$SCRIPT_URL"; then
        # Check if the script is different
        if ! cmp -s "$TEMP_SCRIPT" "$BIN_PATH"; then
            # Backup the current script
            cp "$BIN_PATH" "${BIN_PATH}.backup"
            mv "$TEMP_SCRIPT" "$BIN_PATH"
            chmod +x "$BIN_PATH"
            echo -e "${GREEN}Update successful! Backup saved to ${BIN_PATH}.backup${RESET}"
        else
            echo -e "${YELLOW}No updates available. You are running the latest version.${RESET}"
            rm "$TEMP_SCRIPT"
        fi
    else
        echo -e "${RED}Failed to download update. Check your internet connection or the URL.${RESET}"
        rm "$TEMP_SCRIPT"
    fi
    sleep 2
    main_menu
}

# Check dependencies and run the main menu
check_dependencies
main_menu
