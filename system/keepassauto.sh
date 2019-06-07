#!/bin/bash
# mount webdav keepass folder and start keepassxc
# requires dav2fs and the davfs mount set up for your user in /etc/fstab
mount $HOME/.keepass/
mountcode="$?"
if [ "$mountcode" -ne "0" ]
	then
		dbus-send --type=method_call --dest='org.freedesktop.Notifications' \
        /org/freedesktop/Notifications org.freedesktop.Notifications.Notify \
        string:'[APPLICATION]' \
        uint32:1 string:'[ICON]' \
        string:'' \
        string:"Error mounting davfs" \
        array:string:'' \
        dict:string:string:'','' \
        int32:3000
	else
		keepassxc
		wait $!
		fusermount -u $HOME/.keepass/
fi
