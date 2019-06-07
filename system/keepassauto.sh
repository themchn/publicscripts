#!/bin/bash
# mount webdav keepass folder and start keepassxc
# requires dav2fs and the davfs mount set up for your user in /etc/fstab
mount $HOME/.keepass/
mountcode="$?"
if [ "$mountcode" -ne "0" ]
    then
        # keepass icon in base64
        echo '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
dX1ZRr0IX//Z' | base64 -d > /tmp/keepass_logo_small.jpg

        # display notification with icon
        dbus-send --type=method_call --dest='org.freedesktop.Notifications' \
        /org/freedesktop/Notifications org.freedesktop.Notifications.Notify \
        string:'[APPLICATION]' \
        uint32:1 string:'/tmp/keepass_logo_small.jpg' \
        string:'' \
        string:"Error mounting davfs" \
        array:string:'' \
        dict:string:string:'','' \
        int32:3000
        
        # cleanup
        sleep 1s
        rm /tmp/keepass_logo_small.jpg
    else
        keepassxc
        wait $!
        fusermount -u $HOME/.keepass/
fi
