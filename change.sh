#!/bin/sh

# Use %U:%G:%A:%Y if ctime is not supported
: "${CHANGE_METADATA:="%Z"}"

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
