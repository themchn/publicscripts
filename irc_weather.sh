#!/bin/bash

# define location with zip or major city
location="$1"

# create array from wttr.in output
readarray -t weather_vars < <( curl -s -N wttr.in/"$location"?0?Q?T | cut -c 16- | sed 's/ *$//')

# print it out
 printf "\\x02Conditions:\\x0f ${weather_vars[0]} \\x02• Temp:\\x0f ${weather_vars[1]} \\x02• Wind:\\x0f ${weather_vars[2]} \\x02• Visibility:\\x0f ${weather_vars[3]} \\x02• Rainfall:\\x0f ${weather_vars[4]}"
