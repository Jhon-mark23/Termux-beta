#!/bin/bash

# Storage file for DNS and NameServer
DNS_FILE="dns_data.txt"

# Default settings
DIG_INTERVAL=3  # Default dig interval in seconds

# ANSI color codes
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
BLUE="\e[34m"
RESET="\e[0m"

# Load DNS and NS from file
declare -a DNS_LIST NS_LIST
if [[ -f "$DNS_FILE" ]]; then
    source "$DNS_FILE"
fi

# Save DNS and NS to file
save_data() {
    echo "DNS_LIST=(${DNS_LIST[@]})" > "$DNS_FILE"
    echo "NS_LIST=(${NS_LIST[@]})" >> "$DNS_FILE"
}

# Display Menu
menu() {
    clear
    echo -e "\n===== ${BLUE}DNS & NameServer Checker Panel${RESET} ====="
    echo "-------------------------------------------"
    echo -e "1) Add DNS IP"
    echo -e "2) Add NameServer"
    echo -e "3) Set Dig Interval"
    echo -e "4) Start Checking DNS"
    echo -e "5) Exit"
    echo "-------------------------------------------"
    echo -e "Stored DNS IPs: ${YELLOW}${#DNS_LIST[@]}${RESET}"
    echo -e "Stored NameServers: ${YELLOW}${#NS_LIST[@]}${RESET}"
    echo -e "Interval: ${YELLOW}${DIG_INTERVAL} sec${RESET}"
    echo -e "Version 1.2"
    echo "-------------------------------------------"
    echo -n "Choose an option (Press Enter to Start Checking): "
    read -r option

    case $option in
        1) add_dns ;;
        2) add_ns ;;
        3) set_interval ;;
        4) start_dig ;;
        5) exit 0 ;;
        *) start_dig ;;
    esac
}

# Add DNS IP
add_dns() {
    echo -n "Enter DNS IP: "
    read -r dns
    DNS_LIST+=("$dns")
    save_data
    menu
}

# Add NameServer
add_ns() {
    echo -n "Enter NameServer: "
    read -r ns
    NS_LIST+=("$ns")
    save_data
    menu
}

# Set Dig Interval (0 - 10 seconds)
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
    else
        echo -e "${RED}Invalid input. Please enter a number between 0 and 10.${RESET}"
    fi
    menu
}

# Start DNS Checking (Live Logs)
start_dig() {
    clear
    echo -e "\n===== ${BLUE}DNS Status Check${RESET} ====="
    echo -e "Checking every ${YELLOW}${DIG_INTERVAL}${RESET} seconds..."
    echo "-------------------------------------------"

    SUCCESS_COUNT=0
    FAIL_COUNT=0

    while true; do
        for ((i = 0; i < ${#DNS_LIST[@]}; i++)); do
            DNS_IP="${DNS_LIST[i]}"
            NS="${NS_LIST[i]:-None}"
            
            # Run dig and extract query time
            DIG_OUTPUT=$(dig @"$DNS_IP" google.com +noall +stats)
            QUERY_TIME=$(echo "$DIG_OUTPUT" | grep "Query time" | awk '{print $4}')

            # Run ping test
            PING_OUTPUT=$(ping -c 1 "$DNS_IP" 2>/dev/null | grep "time=" | awk -F'time=' '{print $2}' | awk '{print $1}')

            # Set default values if empty
            [[ -z "$QUERY_TIME" ]] && QUERY_TIME="N/A"
            [[ -z "$PING_OUTPUT" ]] && PING_OUTPUT="N/A"

            # Get colored outputs
            QUERY_TIME_COLOR=$(get_color "$QUERY_TIME")
            PING_TIME_COLOR=$(get_color "$PING_OUTPUT")

            # Determine status
            if [[ "$QUERY_TIME" != "N/A" ]]; then
                STATUS="${GREEN}✔ SUCCESS${RESET}"
                ((SUCCESS_COUNT++))
            else
                STATUS="${RED}✖ FAILED${RESET}"
                ((FAIL_COUNT++))
            fi

            # Display results
            echo -e "DNS IP: ${BLUE}$DNS_IP${RESET} | NameServer: ${YELLOW}$NS${RESET}"
            echo -e "Status: $STATUS | Query Time: $QUERY_TIME_COLOR | Ping: $PING_TIME_COLOR"
            echo "-------------------------------------------"
        done

        echo -e "Total Success: ${GREEN}$SUCCESS_COUNT${RESET} | Total Failed: ${RED}$FAIL_COUNT${RESET}"
        
        # Sleep only if interval is > 0
        (( DIG_INTERVAL > 0 )) && sleep "$DIG_INTERVAL"
    done
}

# Function to determine color based on value
get_color() {
    local value=$1
    if [[ -z "$value" || "$value" == "N/A" ]]; then
        echo -e "${RED}${value}${RESET}"  # Red for failed
    elif (( $(echo "$value <= 50" | bc -l) )); then
        echo -e "${GREEN}${value}ms${RESET}"  # Green for fast response
    elif (( $(echo "$value > 50 && $value <= 100" | bc -l) )); then
        echo -e "${YELLOW}${value}ms${RESET}"  # Yellow for moderate response
    else
        echo -e "${RED}${value}ms${RESET}"  # Red for slow response
    fi
}

# Run Menu
menu
