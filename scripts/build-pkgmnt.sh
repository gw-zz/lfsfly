#!/bin/sh

#set -x
set -o nounset
set -o errexit
set +h 

TOP=$(pwd)
SRCDIR=$TOP/pkg_sources
IMAGENAME=pkg-7.6
NO_CLEANUP=""
BUILD=

# move this vars
LFS=/mnt/lfs
LFS_TGT=$(uname -m)-lfs-linux-gnu

# XXX copy all needed patch in builddir 
# XXX make a link for example gcc-4.9.2 -> gcc

source scripts/include.sh


echo "===Starting building extra tools pkg management at  $(date)" 

# libarchive
extract_package libarchive && cd $BUILD/$IMAGENAME/libarchive

./configure --prefix=/tmp/tools --mandir=/tmp/tools/man \
     --without-lzmadec \
     --without-xml2 \
     --without-expat \
     --without-nettle \
     --without-openssl

make

make install

# pkgconf
extract_package pkgconf && cd $BUILD/$IMAGENAME/pkgconf

./configure \
  --prefix=/tmp/tools --with-system-libdir=/tmp/tools/lib --with-system-includedir=/tmp/tools/include
make
make install

ln -sf /tmp/tools/bin/pkgconf /tmp/tools/bin/pkg-config

# pkgutils

extract_package pkgutils && cd $BUILD/$IMAGENAME/pkgutils

make 

make DESTDIR=/tmp/tools install


echo "===Pkg tools finiched $(date)"

