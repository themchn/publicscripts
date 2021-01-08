#!/bin/bash

#TODO use getopts to add flags
# Options to add: send email report to specified address
# Call getopt to validate the provided input. 
options=$(getopt -o ht:d:p --longoptions force-test,force-dd,no-test,no-dd,help -- "$@")
[ $? -eq 0 ] || { 
    echo "Incorrect options provided. Use -h to view help."
    exit 1
}
eval set -- "$options"
while true; do
    case "$1" in
    -h|--help)
		help="1"
        ;;
    -p)
        no_test="1"
        no_dd="1"
        ;;
    -t)
        shift;
		test_length="$@"
        if [ "$test_length" != "short" ] || [ "$test_length" != "long" ] ; then
            echo "Incorrect option provided for -t."
            exit 1
        fi
        ;;
    -d)
        shift;
        drive_list="${1}"
        ;;
    --force-test)
        force_test="1"
        ;;
    --force-dd)
        force_dd="1"
        ;;
    --no-test)
        no_test="1"
        ;;
    --no-dd)
        no_dd="1"
        ;;
    --)
        shift
        break
        ;;
    esac
    shift
done

if [ "$help" = "1" ] ; then
	echo "Usage: drive_test [OPTION]
Automated testing and wiping of drives for reuse.

Options are:

 -h		display this help and exit
 -d		is to define specific disks in a comma separated list. Accepts both diskN and sdX format.
 -t		specify SMART test length with [short|long] (default is long)
 --force-dd	force a disk wipe regardless of previous test status
 --force-test	force SMART test for drives regardless of previous test status
 --no-dd	do not zero any disks
 --no-test	do not perform any SMART tests. All other options will use previous SMART data for actions."
	exit 0
fi

# declaring later to be used arrays
declare -A phy_to_scsi=()
declare -A scsi_to_phy=()
declare -a phy_disk_unsorted=()
declare -a phy_disk_ordered=()
declare -a missing_disks=()
declare -A smartctl_output=()
declare -A smart_test_status=()
declare -A smart_health_status=()
declare -A smart_test_passed=()
declare -A smart_test_results=()
declare -A smart_report=()
declare -a smart_test_pids=()
declare -a dd_pids=()
declare -A dd_results=()

#TODO add configurable default email address
# defaults
if [ -z "$test_length" ] ; then
    test_length="long"    
fi

normal_disk_test() {
phy_disk="$1"
if [ "$force_test" = "1" ]; then
    smartctl -t "$test_length" /dev/"${phy_to_scsi["$phy_disk"]}" > /dev/null
else
    # if the last test completed successfully compare power on hours to test hours and run test if not recent enough
    if  echo "${smartctl_output["$phy_disk"]}" |  grep -q -E '# 1.*Extended offline.*Completed without error' ; then
        power_on_hours=$(echo "${smartctl_output["$phy_disk"]}" | awk '/Power_On_Hours/{print $NF}')
        last_test_hours=$(echo "${smartctl_output["$phy_disk"]}" | grep -E '# 1.*Extended offline' | grep -o -E '[0-9]{2,6} ')
        if (( "$power_on_hours" - "$last_test_hours" > 24 )); then 
            smartctl -t "$test_length" /dev/"${phy_to_scsi["$phy_disk"]}" > /dev/null
        fi
    else
        smartctl -t "$test_length" /dev/"${phy_to_scsi["$phy_disk"]}" > /dev/null
    fi
fi
}

special_disk_test() {
phy_disk="$1"
if [ "$force_test" = "1" ]; then
    smartctl -t "$test_length" /dev/"${phy_to_scsi["$phy_disk"]}" > /dev/null
else
    # if the last test completed successfully compare power on hours to test hours and run test if not recent enough
    if echo "${smartctl_output["$phy_disk"]}" | grep -q -E '# 1.*Background long.*Completed ' ; then
        # if the last test completed successfully compare power on hours to test hours
        power_on_hours=$(echo "${smartctl_output["$phy_disk"]}" | awk '/number of hours powered up/{print $7}' | cut -d"." -f1)
        last_test_hours=$(echo "${smartctl_output["$phy_disk"]}" |  grep -E '# 1 *Background long' | grep -o -E '[0-9]{2,6} ' )
        if (( "$power_on_hours" - "$last_test_hours" > 24 )); then 
            smartctl -t "$test_length" /dev/"${phy_to_scsi["$phy_disk"]}" > /dev/null
        fi
    else
        smartctl -t "$test_length" /dev/"${phy_to_scsi["$phy_disk"]}" > /dev/null
    fi
fi
}

# polling disks to check for test completion
smart_test_polling () {
phy_disk="$1"
smart_test_status["$phy_disk"]=0
until [ "${smart_test_status["$phy_disk"]}" -eq "1" ] ; do
    smartctl_output["$phy_disk"]=$(smartctl -a /dev/"${phy_to_scsi["$phy_disk"]}")
    if ! echo "${smartctl_output["$phy_disk"]}" | grep -e "Self-test routine in progress" -e "Self test in progress" ; then
        sleep 900
    else
        smart_test_status["$phy_disk"]=1
    fi
done
}

# TODO see about making this more portable
# would need to ignore in use disks
# Get list of attached disks by physical port and associated sdX
readarray -t raw_disk_list < <(ls -la /dev/disk/by-path/ | grep -v "part" | grep -E "sas-phy." | grep -E -o -e "phy." -e "sd." | pr -2ats' ' | sed 's/phy/disk/g')

# create arrays of physical disks to sdX
for i in "${raw_disk_list[@]}"; do
    phy_disk=$(echo $i | cut -d" " -f1)
    scsi_disk=$(echo -n $i | cut -d" " -f2)
    phy_to_scsi["$phy_disk"]="$scsi_disk"
    scsi_to_phy["$scsi_disk"]="$phy_disk"
done

# check if supplied drives with -d actually exist and translate sdX to diskN format
if [ -n "$drive_list" ] ; then
    readarray -td',' custom_drive_list < <(echo -n "$drive_list")
    for disk in "${custom_drive_list[@]}" ; do
        case "$disk" in
            sd[a-z])
                if [[ -v "scsi_to_phy["$disk"]" ]] ; then
                    readarray -O "${#phy_disk_unsorted[@]}" phy_disk_unsorted <<< "${scsi_to_phy["$disk"]}"
                else
                    readarray -O "${#missing_disks[@]}" missing_disks <<< "$disk"
                fi
                ;;
            disk[0-9+])
                if [[ -v "phy_to_scsi["$disk"]" ]] ; then
                    readarray -O "${#phy_disk_unsorted[@]}" phy_disk_unsorted <<< "$disk"
                else
                    readarray -O "${#missing_disks[@]}" missing_disks <<< "$disk"
                fi
                ;;
            *)
                echo "Error: Invalid disk identifier"
                exit 1
                ;;
        esac
    done
    # if -d is supplied with disks not detected in system
    if [ -n "${missing_disks[*]}" ] ; then
        echo "Error: Missing disks: "${missing_disks[*]}""
        exit 3
    fi
fi

# created sorted array of disks to be tested
#TODO $drive_list could really be named better
if [ -n "$drive_list" ] ; then
    readarray -O "${#phy_disk_ordered[@]}" phy_disk_ordered < <(printf '%s\n' "${phy_disk_unsorted[@]}" | sort -u)
else
    for i in "${raw_disk_list[@]}"; do
        phy_disk=$(echo $i | cut -d" " -f1)
        readarray -O "${#phy_disk_ordered[@]}" phy_disk_ordered < <(echo -n "$phy_disk")
    done
fi

# enable smart and test logging if not already and get SMART info for fast parsing and minimize running of smartctl
for phy_disk in "${phy_disk_ordered[@]}" ; do
    smartctl -s on -S on /dev/"${phy_to_scsi["$phy_disk"]}" > /dev/null
    smartctl_output["$phy_disk"]=$(smartctl -a /dev/"${phy_to_scsi["$phy_disk"]}")
done

# check self-assessment health status
for phy_disk in "${phy_disk_ordered[@]}" ; do
    if echo "${smartctl_output["$phy_disk"]}" | grep -q -e "SMART overall-health self-assessment test result: PASSED" -e "SMART Health Status: OK" ; then
        smart_health_status["$phy_disk"]=1
    else
        smart_health_status["$phy_disk"]=0
    fi
done

# case statement to differentiate between special case drives
# did this for flexibility as my sample size of drives is still small
if [ "$no_test" = "1" ]; then
    :
else
    for phy_disk in "${phy_disk_ordered[@]}"; do
        if [ "${smart_health_status["$phy_disk"]}" -eq "1" ] ; then
            case $(echo "${smartctl_output["$phy_disk"]}" | grep -e "Model Family:" -e "Vendor:" | cut -d":" -f1) in
                "Model Family")
                normal_disk_test "$phy_disk"
                smart_test_polling "$phy_disk"
                ;; 
                "Vendor")
                special_disk_test "$phy_disk"
                smart_test_polling "$phy_disk"
                ;;
            esac &
            # create array of pids to wait on before doing anything else
            readarray -O "${#smart_test_pids[@]}" smart_test_pids < <(echo -n "$!")
        fi
    done
    # wait for case statement subshells to complete
    for pid in "${smart_test_pids[@]}" ; do
        wait "$pid"
    done
fi

# updated smartctl_output and check if test passed
#TODO add a check for if no test was run
for phy_disk in "${phy_disk_ordered[@]}"; do
    smartctl_output["$phy_disk"]=$(smartctl -a /dev/"${phy_to_scsi["$phy_disk"]}")
    if echo "${smartctl_output["$phy_disk"]}" | grep "# 1" | grep -q "Completed " ; then
        smart_test_passed["$phy_disk"]=1
    else
        smart_test_passed["$phy_disk"]=0
    fi
done

# wipe the drive if test was successful
if [ "$no_dd" = "1" ]; then
    :
else
    for phy_disk in "${phy_disk_ordered[@]}"; do
        if [ "$force_dd" = "1" ]; then
            :
            dd_results["$phy_disk"]=$(dd if=/dev/zero of=/dev/"${phy_to_scsi["$phy_disk"]}" bs=8M conv=fsync |& grep -e "copied" -e "error")
        else
            if [ "${smart_test_passed["$phy_disk"]}" -eq "1" ] ; then
                echo "This would wipe "$phy_disk""
                dd_results["$phy_disk"]=$(dd if=/dev/zero of=/dev/"${phy_to_scsi["$phy_disk"]}" bs=8M conv=fsync |& grep -e "copied" -e "error")
            fi
        fi &
        readarray -O "${#dd_pids[@]}" dd_pids < <(echo -n "$!")
    done
    # wait for dd subshells to complete so we can include details in report
    for pid in "${dd_pids[@]}" ; do
        wait "$pid"
    done
fi

# Put SMART test and drive details in array for later use in final report
for phy_disk in "${phy_disk_ordered[@]}" ; do
    case $(echo "${smartctl_output["$phy_disk"]}" | grep -e "Model Family:" -e "Vendor:" | cut -d":" -f1) in
        "Model Family")
        smart_report["$phy_disk"]=$(echo "${smartctl_output["$phy_disk"]}" | awk '/Model/ || /Serial/ || /SMART overall-health self-assessment test result/ || /SMART Self-test log/ || /Test_Description/ || /# 1/')
        ;; 
        "Vendor")
        smart_report["$phy_disk"]=$(echo "${smartctl_output["$phy_disk"]}" | awk '/Vendor:/ || /Product:/ || /Serial number:/ || /SMART Health Status:/ || /SMART Self-test log/ || /LBA_first_err/ || /# 1/' )
        ;;
    esac
done

# create summary report
for phy_disk in "${phy_disk_ordered[@]}" ; do
    readarray -O "${#summary_report[@]}" summary_report < <(
        if [ "${smart_test_passed["$phy_disk"]}" -eq "1" ] ; then
            echo "$phy_disk|"${phy_to_scsi["$phy_disk"]}" - PASSED"
            echo "dd status: "${dd_results["$phy_disk"]}""
        else
            echo "$phy_disk|"${phy_to_scsi["$phy_disk"]}" - FAILED"
        fi
        printf '\n')
done

# create final report and store in array
for phy_disk in "${phy_disk_ordered[@]}" ; do
    readarray -O "${#complete_report[@]}" complete_report < <(
        if [ "${smart_test_passed["$phy_disk"]}" -eq "1" ] ; then
            echo "$phy_disk|"${phy_to_scsi["$phy_disk"]}" - PASSED"
        else
            echo "$phy_disk|"${phy_to_scsi["$phy_disk"]}" - FAILED"
        fi
        echo "${smart_report["$phy_disk"]}"
        if [ "${smart_test_passed["$phy_disk"]}" -eq "1" ] ; then
            echo "dd status: "${dd_results["$phy_disk"]}""
        fi
        printf '\n')
done

# email complete report
for i in "${summary_report[@]}" ; do
    printf '%s' "$i"
done

for i in "${complete_report[@]}" ; do
    printf '%s' "$i"
done
