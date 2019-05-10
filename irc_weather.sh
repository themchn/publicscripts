#!/bin/bash

# define location with zip or major city
location="$1"

# create array from wttr.in output
readarray -t weather_vars < <( curl -s -N wttr.in/"$location"?0?Q?T | cut -c 16- | sed 's/ *$//')

# print it out
echo "Conditions: "${weather_vars[0]}" • Temp: "${weather_vars[1]}" • Wind: "${weather_vars[2]}" • Visibility: "${weather_vars[3]}" • Rainfall: "${weather_vars[4]}""
