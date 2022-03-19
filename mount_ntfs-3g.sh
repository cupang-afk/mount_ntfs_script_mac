#!/bin/bash
#check mount_ntfs script
if [ ! -f "/usr/local/sbin/mount_ntfs" ]; then 
    if [ ! -f $(which ntfs-3g) ]; then
        echo "Install ntfs-3g first" 
        exit 1
    else
        #create self mount_ntfs function
        echo "ntfs-3g is found, but mount_ntfs script was not"
        echo "using self mount_ntfs"
        ntfs3g_wrapper="false"
        function mount_ntfs {
            VOLUME_NAME="${@:$#}"
            VOLUME_NAME=${VOLUME_NAME#/Volumes/}
            USER_ID=501
            GROUP_ID=20

            if [ "$(/usr/bin/stat -f %u /dev/console)" -ne 0 ]; then
            USER_ID=$(/usr/bin/stat -f %u /dev/console)
            GROUP_ID=$(/usr/bin/stat -f %g /dev/console)
            fi
            
            $($(which ntfs-3g) \
            -o volname="${VOLUME_NAME}" \
            -o local \
            -o negative_vncache \
            -o auto_xattr \
            -o auto_cache \
            -o noatime \
            -o windows_names \
            -o streams_interface=openxattr \
            -o inherit \
            -o uid="$USER_ID" \
            -o gid="$GROUP_ID" \
            -o allow_other \
            -o big_writes \
            "$@" >> /var/log/mount-ntfs-3g.log 2>&1)
            return $?
        }
    fi
else
    ntfs3g_wrapper="true"
fi

#check remount args
if [ ! -z "$1" ] && [ ! "$1" == "remount" ]; then
    echo "Error, no option for $1"
    echo "Only accept 'remount'"
    exit 1
elif [ "$1" == "remount" ]; then
    do_remount="true"
else
    do_remount="false"
fi
#loop every $(ls /dev/disk[number]s[partition number]) and do $(diskutil info)
while read disk; do
    diskutil_result=$(diskutil info $disk)
    #only get disk that has NTFS attribute
    if echo "$diskutil_result" | grep -iq '.*File System Personality.*NTFS'; then
        #setup common variable
        device_identifier=""
        device_node=""
        vol_name=""
        is_vol_name_null=""
        fs=""
        is_mounted=""
        mount_point=""
        #check every line and add to common variable if found
        while read diskutil_result_line; do
            device_identifier+=$(echo $diskutil_result_line | awk '/(Device Identifier)/ {print $3}')
            device_node+=$(echo $diskutil_result_line | awk '/(Device Node)/ {print $3}')
            vol_name+=$(echo $diskutil_result_line | awk '/(Volume Name)/ {print $3}')
            fs+=$(echo $diskutil_result_line | awk '/(File System Personality)/ {print $4}')
            is_mounted+=$(echo $diskutil_result_line | awk '/(Mounted)/ {print $2}')
            if [ "$is_mounted" == "Yes" ];then 
                mount_point+=$(echo $diskutil_result_line | awk '/(Mount Point)/ {print $3}')
            fi
        done <<< "$diskutil_result"
        #if /dev/disk has (null) vol_name, change vol_name to Untitled-$device_identifier e.g Untitled-disk2s2
        if [ -z "$vol_name" ]; then is_vol_name_null="(null)"; vol_name="Untitled-$device_identifier"; fi
        #print info
        printf "\n================\n"
        echo "Device Node:" $device_node
        if [ ! -z "$is_vol_name_null" ];then
            echo "Volume Name:" $vol_name "a.k.a" $is_vol_name_null
        else
            echo "Volume Name:" $vol_name
        fi
        echo "File System Personality:" $fs
        echo "Mounted:" $is_mounted
        if [ "$is_mounted" == "Yes" ];then echo "Mount Point:" $mount_point; fi
        echo 
        #mount start
        if [ "$is_mounted" == "Yes" ];then
            #do remount if true, and skip mounting process if not
            if $do_remount; then
                echo "  Remounting $mount_point"
                echo "  $(diskutil unmount $mount_point)"
            else
                echo "  Skip $mount_point, no remount args set"
                continue
            fi
        else
            mount_point="/Volumes/$vol_name"
            echo "  Mounting $device_node"
        fi
        #this part will get skipped if remount is not set and /dev/disk already mounted
        if [ ! -d "$mount_point" ]; then 
            echo "  Creating $mount_point"
            sudo mkdir $mount_point
        fi
        #use mount_ntfs script if available, else use self mount_ntfs
        if $ntfs3g_wrapper; then
            if $(sudo /usr/local/sbin/mount_ntfs -o rw $device_node $mount_point);then
                echo "  Mounted $device_node on $mount_point"
            else
                echo "  Something error, please check /var/log/mount-ntfs-3g.log"
            fi
        else
            if mount_ntfs -o rw $device_node $mount_point;then
                echo "  Mounted $device_node on $mount_point"
            else
                echo "  Something error, please check /var/log/mount-ntfs-3g.log"
            fi
        fi
    fi
done < <(ls /dev/disk*s*)
echo 