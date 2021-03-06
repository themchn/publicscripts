#!/bin/bash

# define output styling
formatting=$1

# basic help message
if [ "$formatting" == "--help" ];
    then
        echo "Usage specs.sh [FORMAT]
Output basic system specs for sharing.

Formats available:

    plaintext       outputs plaintext
    weechat-direct  meant for use if running script from weechat with /exec
    weechat-paste   outputs /exec command meant to be pasted into weechat"
        exit 0
fi

# define system spec vars for formatted output
os=$(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)
cpu=$(grep "model name" /proc/cpuinfo | uniq | cut -d":" -f2 | sed -e 's/^ //' -e 's/ \+/ /g')
sockets=$(grep "physical id" /proc/cpuinfo | sort | uniq | wc -l)
cores=$(grep cores /proc/cpuinfo | uniq | grep -Eo '[0-9]+')
threads=$(expr "$(grep processor /proc/cpuinfo | wc -l)" / "$sockets")
memory=$(free -h | awk '/Mem/{print ""$2" Total ("$4" Free)"}')
# add together bytes of all attached disks
storage=$(sum=0; while read bytes ; do sum=$(expr $bytes + $sum) ; done <<< $(lsblk -b | grep disk | awk '{print $4}') ; echo $sum)
# determine division based on integer length
# as this is ingeter only division it is inaccurate but good enough for this
case $(echo -n $storage | wc -m) in
[4-6])
    storage=$(expr $storage / 1024)K
    ;;
[7-9])
    storage=$(expr $storage / 1024 / 1024)M
    ;;
1[0-2])
    storage=$(expr $storage / 1024 / 1024 / 1024)G
    ;;
1[3-9])
    storage=$(expr $storage / 1024 / 1024 / 1024 / 1024)T
    ;;
esac 
uptime=$(uptime | awk '{print $3" "$4}' | sed 's/,//')

case "$formatting" in
plaintext|"")
    bold=$(tput bold)
    normal=$(tput sgr0)
    echo "${bold}OS:${normal} $os ${bold}• CPU:${normal} $cpu ${bold}• Cores:${normal} $cores ${bold}• Threads:${normal} $threads ${bold}• Sockets:${normal} $sockets ${bold}• Memory:${normal} $memory ${bold}• Storage:${normal} $storage •${bold} Uptime:${normal} $uptime"
    ;;
weechat-direct)
    printf "\\x02OS:\\x0f ""$os"" \\x02• CPU:\\x0f ""$cpu"" \\x02• Cores:\\x0f ""$cores"" \\x02• Threads:\\x0f ""$threads"" \\x02• Sockets:\\x0f ""$sockets"" \\x02• Memory:\\x0f ""$memory"" \\x02• Storage:\\x0f ""$storage"" \\x02• Uptime:\\x0f ""$uptime""\n"
    ;;
weechat-paste)
    echo "/exec -o printf \"\\x02OS:\\x0f ""$os"" \\x02• CPU:\\x0f ""$cpu"" \\x02• Cores:\\x0f ""$cores"" \\x02• Threads:\\x0f ""$threads"" \\x02• Sockets:\\x0f ""$sockets"" \\x02• Memory:\\x0f ""$memory"" \\x02• Storage:\\x0f ""$storage"" \\x02• Uptime:\\x0f ""$uptime""\n"\"
    ;;
*)
    echo "Unrecognized format"
    ;;
esac
