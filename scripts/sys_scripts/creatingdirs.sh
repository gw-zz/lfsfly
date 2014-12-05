mkdir -pv /bin /boot /etc/opt /etc/sysconfig /home /lib /mnt /opt
mkdir -pv /media/floppy /media/cdrom /sbin /srv /var
install -dv -m 0750 /root
install -dv -m 1777 /tmp /var/tmp
mkdir -pv /usr/bin /usr/include /usr/lib /usr/sbin /usr/src
mkdir -pv /usr/local/bin /usr/local/include /usr/local/lib /usr/local/sbin /usr/local/src
mkdir -pv /usr/share/color /usr/share/dict /usr/share/doc
mkdir -pv /usr/share/info /usr/share/locale /usr/share/man
mkdir -pv /usr/local/share/color /usr/local/share/dict /usr/local/share/doc
mkdir -pv /usr/local/share/info /usr/local/share/locale /usr/local/share/man
mkdir -v  /usr/share/misc /usr/share/terminfo /usr/share/zoneinfo
mkdir -v  /usr/local/share/misc /usr/local/share/terminfo /usr/local/share/zoneinfo
mkdir -v  /usr/libexec
mkdir -pv /usr/share/man/man1 /usr/share/man/man2 /usr/share/man/man3 /usr/share/man/man4
mkdir -pv /usr/share/man/man5 /usr/share/man/man6 /usr/share/man/man7 /usr/share/man/man8
mkdir -pv /usr/local/share/man/man1 /usr/local/share/man/man2 /usr/local/share/man/man3
mkdir -pv /usr/local/share/man/man4 /usr/local/share/man/man5 /usr/local/share/man/man6
mkdir -pv /usr/local/share/man/man7 /usr/local/share/man/man8

case $(uname -m) in
 x86_64) ln -sv lib /lib64
         ln -sv lib /usr/lib64
         ln -sv lib /usr/local/lib64 ;;
esac

mkdir -v /var/log /var/mail /var/spool
ln -sv /run /var/run
ln -sv /run/lock /var/lock
mkdir -pv /var/opt /var/cache /var/lib/color /var/lib/misc /var/lib/locate /var/local

