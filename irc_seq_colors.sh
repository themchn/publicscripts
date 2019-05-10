#!/bin/bash

# accept input to colorize
input="$1"

# create an array of color ids
colors="02
03
04
05
06
07
08
09
10
11
12
13"
colors_array=($colors)

# count the number of entires in array
num_colors=${#colors_array[@]}

color_choice=0
char_count=1

# Iterate over every character and assign bold format and color in sequence if it isn't a space
# Because of how the input is read, each character is followed by a newline including spaces
# If statement checks if it is a blank line and converts it from a newline to a space.
printf "\\x02"
while read -n1 i; do
	if echo $i | grep -q '^$'
    then
		echo -n " "
    else
        echo -n "$i" | sed "s/./\\x03${colors_array[$color_choice]}&/"
        color_choice=$(( $color_choice + 1 ))
        char_count=$(( $char_count + 1 ))
        if [ $color_choice -gt $num_colors ]
        then
			color_choice=0
        fi
		# Because irc has a 512byte message limit and each "letter" is multiple bytes due to formatting
		# every ~100 needs to be broken by a newline. If additional formatting is added to this script
		# it is likely you'll have to increase the number of line breaks. Use wc -c for byte count.
        if [ $char_count -gt 99 ]
        then
            printf "\n"
            printf "\\x02"
            char_count=1
        fi
	fi
done < <(echo -n "$input")

printf '\n'
