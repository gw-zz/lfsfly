# Directories for downloaded source tarballs and patches.
#!/bin/echo "This file is sourced, not run"


# Get the tarball for this package
find_package_tarball()
{
  # If there are multiple similar files we want the newest timestamp, in case
  # the URL just got upgraded but cleanup_oldfiles hasn't run yet.  Be able to
  # distinguish "package-123.tar.bz2" from "package-tests-123.tar.bz2" and
  # return the shorter one reliably.
  ls -tc "$SRCDIR/$1-"*.tar* 2>/dev/null | while read i
  do
    if [ "$(noversion "${i/*\//}")" == "$1" ]
    then
      echo "$i"
      break
    fi
  done
}

# Given a filename.tar.ext, return the version number.

getversion()
{
  echo "$1" | sed -e 's/.*-\(\([0-9\.]\)*\([_-]rc\)*\(-pre\)*\([0-9][a-zA-Z]\)*\)*\(\.tar\..z2*\)$/'"$2"'\1/'
}


# Remove version information and extension tarball name "$1".
# If "$2", add that version number back, keeping original extension.

noversion()
{
  LOGRUS='s/-*\(\([0-9\.]\)*\([_-]rc\)*\(-pre\)*\([0-9][a-zA-Z]\)*\)*\(\.tar\(\..z2*\)*\)$'
  #[ -z "$2" ] && LOGRUS="$LOGRUS//" || LOGRUS="$LOGRUS/$2\\6/"
  LOGRUS="$LOGRUS//" 
  echo "$1" | sed -e "$LOGRUS"
}


# Extract tarball named in $1 and apply all relevant patches into
# "$BUILD/packages/$1".  Record sha1sum of tarball and patch files in
# sha1-for-source.txt.  Re-extract if tarball or patches change.

extract_package()
{
  echo "extract_package() :$SRCTREE"
  mkdir -p "$SRCTREE" || dienow
  PACKAGE="$1"

  # Announce to the world that we're cracking open a new package
  announce "$PACKAGE"

  # Find tarball, and determine type

  FILENAME="$(find_package_tarball "$PACKAGE")"
  DECOMPRESS=""
  [ "$FILENAME" != "${FILENAME/%\.tar\.bz2/}" ] && DECOMPRESS="j"
  [ "$FILENAME" != "${FILENAME/%\.tar\.gz/}" ] && DECOMPRESS="z"

    echo -n "Extracting '$PACKAGE'"
  (
    UNIQUE=$(readlink /proc/self)
    trap 'rm -rf "$BUILD/temp-'$UNIQUE'"' EXIT
    rm -rf "$SRCTREE/$PACKAGE" 2>/dev/null
    mkdir -p "$BUILD/temp-$UNIQUE" "$SRCTREE" || dienow

    { tar -xv${DECOMPRESS} -f "$FILENAME" -C "$BUILD/temp-$UNIQUE" || dienow
    } | dotprogress

    mv "$BUILD/temp-$UNIQUE/"* "$SRCTREE/$PACKAGE" 
    #&&
    #echo "$SHA1TAR" > "$SHA1FILE"
  )

  [ $? -ne 0 ] && dienow
  
  echo "[ok]"
  #patch_package
  #cd $BUILD/$PACKAGE* || dienow
}

# Create a blank directory at first argument, deleting existing contents if any
blank_tempdir()
{
  # sanity test: never rm -rf something we don't own.
  [ -z "$1" ] && dienow
  touch -c "$1" || dienow

  # Delete old directory, create new one.
  [ -z "$NO_CLEANUP" ] && rm -rf "$1"
  mkdir -p "$1" || dienow
}

# dienow() is an exit function that works properly even from a subshell.
# (actually_dienow is run in the parent shell via signal handler.)

actually_dienow()
{
  echo -e "\n\e[31mExiting due to errors ($PACKAGE)\e[0m" >&2
  exit 1
}


trap actually_dienow SIGUSR1
TOPSHELL=$$

dienow()
{
  kill -USR1 $TOPSHELL
  exit 3
}

# Turn a bunch of output lines into a much quieter series of periods,
# roughly one per screenfull

dotprogress()
{
  x=0
  while read i
  do
    x=$[$x + 1]
    if [[ "$x" -eq 25 ]]
    then
      x=0
      echo -n .
    fi
  done
  echo
}

# Announce an action to the world

announce()
{
  # Write a line to the log file with easily greppable header
  echo "=== $1 ()"

  # Set the title bar of the current xterm
  #[ -z "$NO_TITLE_BAR" ] && echo -en "\033]2;$ARCH_NAME $STAGE_NAME $1\007"
}

# Filter out unnecessary noise, keeping just lines starting with "==="

maybe_quiet()
{
  [ -z "$FORK" ] && cat || grep "^==="
}


