#!/bin/bash
# mount webdav keepass folder and start keepassxc
# requires dav2fs and the davfs mount set up for your user in /etc/fstab
mount $HOME/.keepass/
keepassxc
wait $!
fusermount -u $HOME/.keepass/
