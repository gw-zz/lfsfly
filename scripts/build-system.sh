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

#   mkdir -p /mnt/lfs/lfs-commands
#   cp scripts /mnt/lfs/lfs-commands/
#   cp -R  scripts /mnt/lfs/lfs-commands/
#   cp  wget-list /mnt/lfs/lfs-commands/
#   cp -R lfs-patches /mnt/lfs/lfs-commands/
#   cp build-system.sh /mnt/lfs/lfs-commands/

echo "===Starting building Lfs 7.6 dev  $(date)" 

# linux-headers 
build_package linux-headers && cd $BUILD/$IMAGENAME/libarchive


echo "===Building system finiched $(date)"

