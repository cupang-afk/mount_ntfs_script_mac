A simple script to mount or remount all ntfs on mac as read/write using ntfs-3g

### NOTE
please install `ntfs-3g` first using [homebrew](https://brew.sh) `brew install ntfs-3g`

if you can't install `ntfs-3g`, try using gromgit tap [gromgit/homebrew-fuse](https://github.com/gromgit/homebrew-fuse) 

`brew install gromgit/fuse/ntfs-3g-mac`

or `brew tap gromgit/fuse` then `brew install ntfs-3g-mac`

---
```
curl -OL https://raw.githubusercontent.com/cupang-afk/mount_ntfs_script_mac/main/mount_ntfs-3g.sh
chmod a+x mount_ntfs-3g.sh
sudo ./mount_ntfs-3g.sh
```
usage
```
sudo mount_ntfs-3g.sh 
sudo mount_ntfs-3g.sh remount
```
example output
```
================
Device Node: /dev/disk0s2
Volume Name: Untitled-disk0s2 a.k.a (null)
File System Personality: NTFS
Mounted: Yes
Mount Point: /Volumes/Untitled-disk0s2

  Skip /Volumes/Untitled-disk0s2, no remount args set

================
Device Node: /dev/disk2s2
Volume Name: DATA
File System Personality: NTFS
Mounted: No

  Mounting /dev/disk2s2
  Creating /Volumes/DATA
  Mounted /dev/disk2s2 on /Volumes/DATA
```
error log is saved in `/var/log/mount-ntfs-3g.log` by default
