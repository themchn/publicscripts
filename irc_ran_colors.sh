#!/bin/bash

# accept input to colorize
input="$1"

# create an array of color ids
readarray -t colors < <( seq -w 02 13 )
# count the number of entires in array
num_colors=${#colors[@]}
# Iterate over every character and assign bold format and random color if it isn't a space
# Because of how the input is read, each character is followed by a newline including spaces
# If statement checks if it is a blank line and converts it from a newline to a space.
char_count=0
printf "\\x02"
while read -n1 i; do
    if echo $i | grep -q '^$'
    then
        echo -n " "
    else
        echo -n "$i" | sed "s/./\\x03${colors[$((RANDOM%num_colors))]}&/"
    fi
	# Because irc has a 512byte message limit and each "letter" is multiple bytes due to formatting
	# every ~100 lines needs to be broken by a newline. If additional formatting is added to this script
	# it is likely you'll have to increase the number of line breaks. Use wc -c for byte count.
        # TODO: actually count and add the bytes to get accurate line breaks
	char_count=$(( $char_count + 1 ))
    if [ $char_count -gt 98 ]
    then
        printf "\n"
        printf "\\x02"
        char_count=1
    fi
done < <(echo -n "$input")
printf '\n'
