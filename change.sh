#!/bin/sh

# Use %U:%G:%A:%Y if ctime is not supported
: "${CHANGE_METADATA:="%Z"}"

: "${CHANGE_FIND_NAME:=""}"
: "${CHANGE_FIND_INAME:=""}"
: "${CHANGE_FIND_PATH:=""}"
: "${CHANGE_FIND_IPATH:=""}"
: "${CHANGE_FIND_REGEX:=""}"
: "${CHANGE_FIND_TYPE:=""}"
: "${CHANGE_FIND_EXECUTABLE:="0"}"
: "${CHANGE_FIND_PERM:=""}"
: "${CHANGE_FIND_MTIME:=""}"
: "${CHANGE_FIND_ATIME:=""}"
: "${CHANGE_FIND_CTIME:=""}"
: "${CHANGE_FIND_MMIN:=""}"
: "${CHANGE_FIND_NEWER:=""}"
: "${CHANGE_FIND_USER:=""}"
: "${CHANGE_FIND_GROUP:=""}"
: "${CHANGE_FIND_SIZE:=""}"
: "${CHANGE_FIND_LINKS:=""}"
: "${CHANGE_FIND_EMPTY:="0"}"
: "${CHANGE_FIND_PRUNE:="0"}"

while :; do
  case "$1" in
    -name) CHANGE_FIND_NAME=$2; shift 2 ;;
    -name=*) CHANGE_FIND_NAME=${1#*=} ; shift ;;
    -iname) CHANGE_FIND_INAME=$2; shift 2 ;;
    -iname=*) CHANGE_FIND_INAME=${1#*=} ; shift ;;
    -path) CHANGE_FIND_PATH=$2; shift 2 ;;
    -path=*) CHANGE_FIND_PATH=${1#*=}; shift ;;
    -ipath) CHANGE_FIND_IPATH=$2; shift 2 ;;
    -ipath=*) CHANGE_FIND_IPATH=${1#*=} ; shift ;;
    -regex) CHANGE_FIND_REGEX=$2; shift 2 ;;
    -regex=*) CHANGE_FIND_REGEX=${1#*=} ; shift ;;
    -type) CHANGE_FIND_TYPE=$2; shift 2 ;;
    -type=*) CHANGE_FIND_TYPE=${1#*=} ; shift ;;
    -executable) CHANGE_FIND_EXECUTABLE=1; shift ;;
    -perm) CHANGE_FIND_PERM=$2; shift 2 ;;
    -perm=*) CHANGE_FIND_PERM=${1#*=} ; shift ;;
    -mtime) CHANGE_FIND_MTIME=$2; shift 2 ;;
    -mtime=*) CHANGE_FIND_MTIME=${1#*=} ; shift ;;
    -atime) CHANGE_FIND_ATIME=$2; shift 2 ;;
    -atime=*) CHANGE_FIND_ATIME=${1#*=} ; shift ;;
    -ctime) CHANGE_FIND_CTIME=$2; shift 2 ;;
    -ctime=*) CHANGE_FIND_CTIME=${1#*=} ; shift ;;
    -mmin) CHANGE_FIND_MMIN=$2; shift 2 ;;
    -mmin=*) CHANGE_FIND_MMIN=${1#*=} ; shift ;;
    -newer) CHANGE_FIND_NEWER=$2; shift 2 ;;
    -newer=*) CHANGE_FIND_NEWER=${1#*=} ; shift ;;
    -user) CHANGE_FIND_USER=$2; shift 2 ;;
    -user=*) CHANGE_FIND_USER=${1#*=} ; shift ;;
    -group) CHANGE_FIND_GROUP=$2; shift 2 ;;
    -group=*) CHANGE_FIND_GROUP=${1#*=} ; shift ;;
    -size) CHANGE_FIND_SIZE=$2; shift 2 ;;
    -size=*) CHANGE_FIND_SIZE=${1#*=} ; shift ;;
    -links) CHANGE_FIND_LINKS=$2; shift 2 ;;
    -links=*) CHANGE_FIND_LINKS=${1#*=} ; shift ;;
    -empty) CHANGE_FIND_EMPTY=1; shift ;;
    -prune) CHANGE_FIND_PRUNE=1; shift ;;
    *) break ;;
  esac
done

ctime_support() {
  if [ -f "$1" ]; then
    _tgt=$(dirname "$1")
  else
    _tgt=$1
  fi

  _test=$(mktemp -p "$_tgt" .ctime-XXXXXX)
  _before=$(stat -c %Z "$_test")
  sleep 1
  chmod a+x "$_test"
  _after=$(stat -c %Z "$_test")
  rm -f "$_test"
  [ "$_before" != "$_after" ]
}

summary() {
  find -L "$1" -exec stat -L -c "%n:%s:%F:${CHANGE_METADATA}" {} \;
}

for dir; do
  if [ ! -d "$dir" ]; then
    echo "Not a directory: $dir" >&2
    exit 1
  fi
  summary "$dir" | sha256sum | awk '{print $1}'
done
