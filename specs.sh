#!/bin/bash

formatting=$1

os=$(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)
cpu=$(grep "model name" /proc/cpuinfo | uniq | cut -d":" -f2 | sed 's/^ //')
sockets=$(grep "physical id" /proc/cpuinfo | sort | uniq | wc -l)
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

if [ "$formatting" == "weechat" ];
	then
		echo "/exec -o printf \"\\x02OS:\\x0f $os \\x02• CPU:\\x0f $cpu \\x02• Sockets:\\x0f $sockets \\x02• Memory:\\x0f $memory \\x02• Storage:\\x0f $storage \\x02• Uptime:\\x0f $uptime\""
	else		
		echo "OS: $os • CPU: $cpu • Sockets: $sockets • Memory: $memory • Storage: $storage • Uptime: $uptime"
fi
