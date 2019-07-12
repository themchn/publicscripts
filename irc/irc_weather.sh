#!/bin/bash

# define location with zip or major city
location="$1"

# create array from wttr.in output
readarray -t weather_vars < <( curl -s -N curl -s -N wttr.in/"$location"?format=%c+%C%7C%t%7C%h%7C%p%7C%w%7C%m | sed -e 's/|/\n/g' -e 's/%/\%\%/g'

# print it out
printf "\\x02Conditions:\\x0f ${weather_vars[0]} \\x02• Temp:\\x0f ${weather_vars[1]} \\x02• Humidity:\\x0f ${weather_vars[2]} \\x02• Rainfall:\\x0f ${weather_vars[3]} \\x02• Wind:\\x0f ${weather_vars[4]} \\x02• Moon phase:\\x0f ${weather_vars[5]}\n"
