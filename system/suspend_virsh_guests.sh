#!/bin/bash
# suspend and resume vms when suspending host to memory

case "${1}" in
    pre)
        # Get list of running machines
        readarray -t active_vms < <(virsh list | grep running | awk '{print $2}')

        # if no vms were active then exit
        if [ "${#active_vms[@]}" -eq 0 ]; then
            exit 0
        fi
        
        # Create list for resuming later
        printf '%s\n' "${active_vms[@]}" > /tmp/running_vms
        
        # Perform the suspension
        for i in ${active_vms[@]}; do
            virsh -q suspend $i;
        done
        ;;
    post)
        # check if any vms were actually running and exit if not
        if [ -f /tmp/running_vms ]; then
            # resume all previously active vms
            while read vm; do
                virsh resume $vm;
            done < /tmp/running_vms
            # cleanup list
            rm /tmp/running_vms
        else
            exit 0
        fi
        ;;
esac
        
