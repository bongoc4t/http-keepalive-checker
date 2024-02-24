#!/bin/bash

# Default values for IP address, SNI, and interface
IP_ADDRESS=""
SNI=""
INTERFACE=""

# Function to display usage information
usage() {
    echo "Usage: $0 [-a <IP address>] [-s <SNI>] [-i <interface>]"
    echo "Options:"
    echo "  -a <IP address>:     Specify the IP address of the server"
    echo "  -s <SNI>:            Specify the Server Name Indication"
    echo "  -i <interface>:      Specify the network interface (optional)"
    exit 1
}

# Parse command-line options
while getopts ":a:s:i:" opt; do
    case $opt in
        a)
            IP_ADDRESS="$OPTARG"
            ;;
        s)
            SNI="$OPTARG"
            ;;
        i)
            INTERFACE="$OPTARG"
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            usage
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            usage
            ;;
    esac
done

# Check if required options are provided
if [[ -z "$IP_ADDRESS" || -z "$SNI" ]]; then
    echo "IP address and SNI are required options." >&2
    usage
fi

# Capture TCP packets using tcpdump
tcpdump_output=$(tcpdump -i "$INTERFACE" -n -A -s0 "tcp dst host $IP_ADDRESS and dst port 443" 2>/dev/null)

# Find the FIN packet and extract its timestamp, source IP address, and SNI
fin_packet=$(echo "$tcpdump_output" | grep "Flags \[F\]" | head -n 1)
fin_timestamp=$(echo "$fin_packet" | awk '{print $1 " " $2}')
source_ip=$(echo "$fin_packet" | awk '{print $3}')

# Extract the timestamp components
fin_time=$(echo "$fin_timestamp" | cut -d' ' -f2)
fin_date=$(echo "$fin_timestamp" | cut -d' ' -f1)

# Convert the FIN timestamp to epoch time
fin_epoch=$(date -d "$fin_date $fin_time" +%s.%N)

# Calculate the keep-alive time
keepalive_time=$(echo "$(date +%s.%N) - $fin_epoch" | bc)

echo "FIN received at $fin_date $fin_time"
echo "Source IP address: $source_ip"
echo "SNI: $SNI"
echo "Keep-alive time is estimated to be around $keepalive_time seconds"
