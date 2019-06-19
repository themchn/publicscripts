#!/bin/bash

# define location with zip or major city
location="$1"

# create array from wttr.in output
readarray -t weather_vars < <( curl -s -N wttr.in/"$location"?0?Q?T | cut -c 16- | sed 's/ *$//')

# add emoji of weather condition
case "${weather_vars[0]}" in
Sunny*|Clear*)
    weather_vars[0]=$(echo -n "☀️ ${weather_vars[0]}")
    ;;
Light*Rain*)
    weather_vars[0]=$(echo -n "🌦️ ${weather_vars[0]}")
    ;;
Overcast*)
    weather_vars[0]=$(echo -n "☁️ ${weather_vars[0]}")
    ;; 
Partly*cloudy*)
    weather_vars[0]=$(echo -n "⛅ ${weather_vars[0]}")
    ;;    
esac
# print it out
 printf "\\x02Conditions:\\x0f ${weather_vars[0]} \\x02• Temp:\\x0f ${weather_vars[1]} \\x02• Wind:\\x0f ${weather_vars[2]} \\x02• Visibility:\\x0f ${weather_vars[3]} \\x02• Rainfall:\\x0f ${weather_vars[4]}"
