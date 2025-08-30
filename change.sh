#!/bin/sh

set -eu

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

check_find_args() {
  if [ "$#" -eq 0 ]; then
    return
  fi

  # Verify first argument looks like a find option
  case "$1" in
    -*)
      ;;
    "(")
      ;;
    "!")
      ;;
    *)
      echo "Invalid find option: $1" >&2
      exit 1
      ;;
  esac

  # Verify find options
  for opt; do
    case "$opt" in
      -print*|-exec|-ok|-delete|-quit)
        echo "$opt is not allowed as a find action" >&2
        exit 1
        ;;
    esac
  done
}

idempotent_ls() {
  # Pickup path the directory, scream on error
  _dir=$1
  if ! [ -d "$_dir" ]; then
    echo "Not a directory: $_dir" >&2
    exit 1
  fi
  shift

  check_find_args "$@"

  # Generate a unique file list, recursively.
  find -L "$_dir" "$@" -exec stat -L -c "%n:%s:%F:${CHANGE_METADATA}" {} \; | sort
}

generate_dirsum() {
  sumbin=$1
  shift
  idempotent_ls "$@" | "$sumbin" | awk '{print $1}'
}

generate_sums() {
  sumbin=$1
  paths=$2
  shift 2
  if [ -z "$paths" ] || [ "$paths" = "-" ]; then
    while IFS= read -r path; do
      generate_dirsum "$sumbin" "$path" "$@"
    done
  elif [ -f "$paths" ]; then
    while IFS= read -r path; do
      generate_dirsum "$sumbin" "$path" "$@"
    done <"$paths"
  elif [ -d "$paths" ]; then
    generate_dirsum "$sumbin" "$paths" "$@"
  else
    echo "$2 is not a file, nor a dir!" >&2
    exit 1
  fi
}

main() {
  case "$1" in
    detect)
      shift
      for path; do
        if ctime_support "$path"; then
          CHANGE_METADATA="%Z"
        else
          CHANGE_METADATA="%U:%G:%A:%Y"
        fi
        printf "%s\n" "$CHANGE_METADATA"
      done
      ;;
    sha256)
      shift
      generate_sums sha256sum "$@"
      ;;
    sha512)
      shift
      generate_sums sha512sum "$@"
      ;;
    *)
      echo "Invalid command: $1" >&2
      exit 1
      ;;
  esac
}

if [ "$#" -eq 0 ]; then
  generate_dirsum sha256sum .
  exit
fi

if [ "$#" -gt 0 ]; then
  if [ -d "$1" ] || [ -f "$1" ] || [ "$1" = "-" ]; then
    generate_sums sha256sum "$@"
  else
    main "$@"
  fi
fi
