chroot "$LFS" /tools/usr/bin/env -i \
    HOME=/root \
    TERM="$TERM" \
    PS1='|LFS] \u:\w\$ ' \
    PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin:/tools/usr/bin:/tools/sbin:/tools/usr/sbin \
    MAKEFLAGS=-j1 /tools/bin/sh -l

