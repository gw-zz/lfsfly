#!/bin/sh

#set -x
set -o nounset
set -o errexit
set +h 

TOP=$(pwd)
SRCDIR=$TOP/sources
IMAGENAME=lfs-7.6
NO_CLEANUP=""
BUILD=

# move this vars
LFS=/mnt/lfs
LFS_TGT=$(uname -m)-lfs-linux-gnu

# XXX copy all needed patch in builddir 
# XXX make a link for example gcc-4.9.2 -> gcc

source scripts/include.sh


## 
#if [ -e /build/tools.stp ]; then 

echo "===Starting building at $(date)" 

# ./032-binutils-pass1

extract_package binutils && cd $BUILD/$IMAGENAME/binutils
patch -p1 -i ../binutils-2.24-configure_ash-1.patch
mkdir -vp ../binutils-build
cd ../binutils-build

../binutils-2.24/configure     \
    --prefix=/tmp/tools        \
    --with-sysroot=$LFS        \
    --with-lib-path=/tools/lib \
    --target=$LFS_TGT          \
    --disable-nls              \
    --disable-werror

make

case $(uname -m) in
  x86_64) mkdir -v /tmp/tools/lib && ln -sv lib /tmp/tools/lib64 ;;
esac

make install
#===
rm -vfR $BUILD/$IMAGENAME/{binutils,binutils-build}
#===

# ./033-gcc-pass1
extract_package gcc && cd $BUILD/$IMAGENAME/gcc
ln -s $SRCDIR/{mpfr-3.1.2.tar.xz,gmp-6.0.0a.tar.xz,mpc-1.0.2.tar.gz} $BUILD/$IMAGENAME
# ===
tar -xf ../mpfr-3.1.2.tar.xz
mv -v mpfr-3.1.2 mpfr
tar -xf ../gmp-6.0.0a.tar.xz
mv -v gmp-6.0.0 gmp
tar -xf ../mpc-1.0.2.tar.gz
mv -v mpc-1.0.2 mpc

for file in \
 $(find gcc/config -name linux64.h -o -name linux.h -o -name sysv4.h)
do
  cp -v $file $file.orig
  sed -e 's@/lib\(64\)\?\(32\)\?/ld@//tmp/tools&@g' \
      -e 's@/usr@/tmp/tools@g' $file.orig > $file
  echo '
#undef STANDARD_STARTFILE_PREFIX_1
#undef STANDARD_STARTFILE_PREFIX_2
#define STANDARD_STARTFILE_PREFIX_1 "/tmp/tools/lib/"
#define STANDARD_STARTFILE_PREFIX_2 ""' >> $file
  touch $file.orig
done

sed -i '/k prot/agcc_cv_libc_provides_ssp=yes' gcc/configure

mkdir -v ../gcc-build
cd ../gcc-build

../gcc-4.9.2/configure                               \
    --target=$LFS_TGT                                \
    --prefix=/tmp/tools                                  \
    --with-sysroot=$LFS                              \
    --with-newlib                                    \
    --without-headers                                \
    --with-local-prefix=/tmp/tools                       \
    --with-native-system-header-dir=/tmp/tools/include   \
    --disable-nls                                    \
    --disable-shared                                 \
    --disable-multilib                               \
    --disable-decimal-float                          \
    --disable-threads                                \
    --disable-libatomic                              \
    --disable-libgomp                                \
    --disable-libitm                                 \
    --disable-libquadmath                            \
    --disable-libsanitizer                           \
    --disable-libssp                                 \
    --disable-libvtv                                 \
    --disable-libcilkrts                             \
    --disable-libstdc++-v3                           \
    --enable-languages=c,c++

make

make install

#==
rm -vfR $BUILD/$IMAGENAME/{gcc,gcc-build}
rm -vf $BUILD/$IMAGENAME/{mpfr-3.1.2.tar.xz,gmp-6.0.0a.tar.xz,mpc-1.0.2.tar.gz} 
#==
# ./034-linux-headers
extract_package linux &&  cd $BUILD/$IMAGENAME/linux

sed -i 's/SIGTERM ERR/SIGTERM/' scripts/link-vmlinux.sh
make mrproper

make INSTALL_HDR_PATH=dest headers_install

cp -rv dest/include/* /tmp/tools/include

#===
rm -vfR $BUILD/$IMAGENAME/linux
#===

# ./035-glibc
extract_package glibc &&  cd $BUILD/$IMAGENAME/glibc

if [ ! -r /usr/include/rpc/types.h ]; then
  su -c 'mkdir -pv /usr/include/rpc'
  su -c 'cp -v sunrpc/rpc/*.h /usr/include/rpc'
fi

mkdir -v ../glibc-build
cd ../glibc-build

../glibc-2.20/configure                             \
      --prefix=/tmp/tools                           \
      --host=$LFS_TGT                               \
      --build=$(../glibc-2.20/scripts/config.guess) \
      --disable-profile                             \
      --enable-kernel=2.6.32                        \
      --with-headers=/tmp/tools/include             \
      libc_cv_forced_unwind=yes                     \
      libc_cv_ctors_header=yes                      \
      libc_cv_c_cleanup=yes

make

make install

echo 'main(){}' > dummy.c
$LFS_TGT-gcc dummy.c
#readelf -l a.out | grep ': /tools'
readelf -l a.out

#rm -v dummy.c a.out
#cp a.out dummy.c ..

rm -vfR $BUILD/$IMAGENAME/{glibc,glibc-build}

# ./036-gcc-libstdc++
extract_package gcc && cd $BUILD/$IMAGENAME/gcc
mkdir -pv ../gcc-build
cd ../gcc-build

../gcc-4.9.2/libstdc++-v3/configure \
    --host=$LFS_TGT                 \
    --prefix=/tmp/tools                 \
    --disable-multilib              \
    --disable-shared                \
    --disable-nls                   \
    --disable-libstdcxx-threads     \
    --disable-libstdcxx-pch         \
    --with-gxx-include-dir=/tmp/tools/$LFS_TGT/include/c++/4.9.2

make

make install

rm -vfR $BUILD/$IMAGENAME/{gcc,gcc-build}

# ./037-binutils-pass2
extract_package binutils && cd $BUILD/$IMAGENAME/binutils

patch -p1 -i ../binutils-2.24-configure_ash-1.patch

mkdir -v ../binutils-build
cd ../binutils-build

CC=$LFS_TGT-gcc                \
AR=$LFS_TGT-ar                 \
RANLIB=$LFS_TGT-ranlib         \
../binutils-2.24/configure     \
    --prefix=/tmp/tools            \
    --disable-nls              \
    --disable-werror           \
    --with-lib-path=/tmp/tools/lib \
    --with-sysroot

make

make install

make -C ld clean
make -C ld LIB_PATH=/usr/lib:/lib
cp -v ld/ld-new /tmp/tools/bin

rm -vfR $BUILD/$IMAGENAME/{binutils,binutils-build}

# ./038-gcc-pass2
extract_package gcc && cd $BUILD/$IMAGENAME/gcc
ln -s $SRCDIR/{mpfr-3.1.2.tar.xz,gmp-6.0.0a.tar.xz,mpc-1.0.2.tar.gz} $BUILD/$IMAGENAME
echo "# ./038-gcc-pass2"
cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
  `dirname $($LFS_TGT-gcc -print-libgcc-file-name)`/include-fixed/limits.h

for file in \
 $(find gcc/config -name linux64.h -o -name linux.h -o -name sysv4.h)
do
  cp -v $file $file.orig
  sed -e 's@/lib\(64\)\?\(32\)\?/ld@/tmp/tools&@g' \
      -e 's@/usr@/tmp/tools@g' $file.orig > $file
  echo '
#undef STANDARD_STARTFILE_PREFIX_1
#undef STANDARD_STARTFILE_PREFIX_2
#define STANDARD_STARTFILE_PREFIX_1 "/tmp/tools/lib/"
#define STANDARD_STARTFILE_PREFIX_2 ""' >> $file
  touch $file.orig
done

tar -xf ../mpfr-3.1.2.tar.xz
mv -v mpfr-3.1.2 mpfr
tar -xf ../gmp-6.0.0a.tar.xz
mv -v gmp-6.0.0 gmp
tar -xf ../mpc-1.0.2.tar.gz
mv -v mpc-1.0.2 mpc

mkdir -v ../gcc-build
cd ../gcc-build

CC=$LFS_TGT-gcc                                      \
CXX=$LFS_TGT-g++                                     \
AR=$LFS_TGT-ar                                       \
RANLIB=$LFS_TGT-ranlib                               \
../gcc-4.9.2/configure                               \
    --prefix=/tmp/tools                                  \
    --with-local-prefix=/tmp/tools                       \
    --with-native-system-header-dir=/tmp/tools/include   \
    --enable-languages=c,c++                         \
    --disable-libstdcxx-pch                          \
    --disable-multilib                               \
    --disable-bootstrap                              \
    --disable-libgomp

make

make install

ln -sv gcc /tmp/tools/bin/cc

echo 'main(){}' > dummy.c
cc dummy.c
readelf -l a.out | grep 'tools'

rm -v dummy.c a.out

rm -vfR $BUILD/$IMAGENAME/{gcc,gcc-build}
rm -vf $BUILD/$IMAGENAME/{mpfr-3.1.2.tar.xz,gmp-6.0.0a.tar.xz,mpc-1.0.2.tar.gz} 

# 
#else 
# echo "continuning building" 
# ./039-busybox
extract_package busybox  && cd $BUILD/$IMAGENAME/busybox

patch -p1 -i ../busybox-1.22.1-verbose-3.patch

make distclean

make defconfig

sed -e 's/\(CONFIG_FEATURE_HAVE_RPC\)=y/# \1 is not set/' \
    -e 's/\(CONFIG_FEATURE_INETD_RPC\)=y/# \1 is not set/' -i .config

make

make CONFIG_PREFIX=/tmp/tools install

rm -vfR $BUILD/$IMAGENAME/busybox
echo "busybox installed !" 


# ./040-gawk
extract_package gawk  && cd $BUILD/$IMAGENAME/gawk

./configure --prefix=/tmp/tools 

make

make install

rm -vfR $BUILD/$IMAGENAME/gawk

# ./041-m4
extract_package m4 && cd $BUILD/$IMAGENAME/m4
./configure --prefix=/tmp/tools

make

make install

rm -vfR $BUILD/$IMAGENAME/m4

# ./042-make
extract_package make && cd $BUILD/$IMAGENAME/make 

./configure --prefix=/tmp/tools --without-guile

make

make install

rm -vfR $BUILD/$IMAGENAME/make

# ./043-perl
extract_package perl && cd $BUILD/$IMAGENAME/perl

sh Configure -des -Dprefix=/tmp/tools -Dlibs=-lm

make

cp -v perl cpan/podlators/pod2man /tmp/tools/bin
mkdir -pv /tmp/tools/lib/perl5/5.20.1
cp -Rv lib/* /tmp/tools/lib/perl5/5.20.1

rm -vfR $BUILD/$IMAGENAME/perl
#
# fi 
echo "=== Toolchain finiched $(date)"
