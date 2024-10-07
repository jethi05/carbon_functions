#!/usr/bin/bash

# Define color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color (reset)

# Get battery percentage
percentage=$(upower -d | grep percentage | awk -F: '/percentage/ {print int($2)}' | sort -u)

# Get charging state, clean it, and ensure only one match is used
state=$(upower -d | grep state | awk '{print $2}' | head -n 1 | tr -d '[:space:]')

# Debugging: Display the captured state
#echo "Captured state: '$state'"

# Display the appropriate emote based on charging state
if [[ "$state" == "charging" ]]; then
    echo -e "${GREEN}"
    echo -e "                                            |   |   |            "       #--------------------/
    echo -e "                                            |/| |/| |/|            "     #                   /
    echo -e "                                              |   |   |        ${NC}" #                  /__________
elif [[ "$state" == "discharging" ]]; then
    echo -e "${RED}"
    echo -e "                                            ._________."
    echo -e "                                            | Batrery |+"
    echo -e "                                            |_________|-"
else
    echo "State: $state (not charging or discharging)"  # Handle other states, if any
fi

# Display battery level with pipes
counter=0
while [ $counter -lt $percentage ]; do
    echo -ne "${GREEN}|${NC}"  # Green pipes for current percentage
    counter=$((counter + 1))
done

# Print red pipes for the remaining percentage to 100
while [ $counter -lt 100 ]; do
    echo -ne "${RED}|${NC}"  # Red pipes for remaining percentage
    counter=$((counter + 1))
done

# Print the final percentage
echo
echo "Battery percentage: $percentage%"

