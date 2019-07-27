#!/bin/bash

# this is ugly and far from done but here it is
# monitor ALL weechat logs, tail every single one with a separate process, and reply with a specified phrase when a match is found
# Must be using weechat with fifo enabled

for i in $HOME/.weechat/logs/* ; do 
    (tail -F -n0 $i | grep --line-buffered grabbedme | while read ; do echo "$(echo $i | cut -d'/' -f6 | sed 's/.weechatlog//') *Ok" >~/.weechat/weechat_fifo ; done) &
done

sleep 60
