#!/bin/bash

# Storage file for DNS and NameServer
DNS_FILE="dns_data.txt"

# Default settings
DIG_INTERVAL=3  # Default dig interval in seconds (Minimum: 2s)

# ANSI color codes
GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
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
    echo -e "1) Add DNS IP (${#DNS_LIST[@]} added)"
    echo -e "2) Add NameServer (${#NS_LIST[@]} added)"
    echo -e "3) Set Dig Interval (Current: ${YELLOW}${DIG_INTERVAL}s${RESET})"
    echo -e "4) Start Checking DNS"
    echo -e "5) Exit"
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

# Set Dig Interval
set_interval() {
    echo -n "Enter dig interval (min 2s): "
    read -r new_interval
    if (( new_interval >= 2 )); then
        DIG_INTERVAL=$new_interval
    else
        DIG_INTERVAL=2
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
            PING_OUTPUT=$(ping -c 1 "$DNS_IP" | grep "time=" | awk -F'time=' '{print $2}' | awk '{print $1}')

            # Determine status
            if [[ -n "$QUERY_TIME" ]]; then
                STATUS="${GREEN}✔ SUCCESS${RESET}"
                PING_COLOR=${GREEN}
                ((SUCCESS_COUNT++))
            else
                STATUS="${RED}✖ FAILED${RESET}"
                PING_COLOR=${RED}
                ((FAIL_COUNT++))
            fi

            # Display results
            echo -e "DNS IP: ${BLUE}$DNS_IP${RESET} | NameServer: ${YELLOW}$NS${RESET}"
            echo -e "Status: $STATUS | Query Time: ${YELLOW}${QUERY_TIME:-N/A}ms${RESET} | Ping: ${PING_COLOR}${PING_OUTPUT:-N/A}ms${RESET}"
            echo "-------------------------------------------"
        done

        echo -e "Total Success: ${GREEN}$SUCCESS_COUNT${RESET} | Total Failed: ${RED}$FAIL_COUNT${RESET}"
        sleep "$DIG_INTERVAL"
    done
}

# Run Menu
menu
