#!/bin/bash
set -e

# This script is meant to be run by inotify to validate/process data files
# from veritas; when the content of $VERITAS_ARCHIVE changes.
#
# $VERITAS_ARCHIVE can change in three ways regarding its files:
# - file created
# - file modified
# - file deleted
# Regarding the fs/inotify signals, "created" and "modify" can be merged
# under the listening of one signal: "MODIFY", while "deleted" is signaled
# by "DELETE".
#
# The script expects three arguments:
# - the filename that was modified/deleted
# - the signal triggered
# - the directory where filename is/was

help() {
  echo ""
  echo "Usage: " `basename $0` "<arguments>"
  echo ""
  echo "Arguments are:"
  echo '  $1 : filename modified, created or deleted'
  echo '  $2 : incron event (IN_MODIFY,IN_DELETE,IN_MOVE)'
  echo '  $3 : source directory'
  echo ""
}

# Check number of arguments (3)
[ "$#" -ne 3 ] && { help; exit 0; }

FILENAME="$1"
EVENT="$2"
DIR="$3"

# Check whether (some) arguments are ok..
#
_F="${DIR}/${FILENAME}"
[ ! -d "$DIR" ] && { 1>&2 echo "Not a directory: '$DIR'"; exit 1; }
[ ! -f "$_F" ]  && { 1>&2 echo "File '$_F' not found";    exit 1; }

# Here is where things actually start
source repo_update.sh

[ "$EVENT" == "IN_MODIFY" ] && modify $FILENAME $DIR $EVENT
[ "$EVENT" == "IN_MOVED" ]  && modify $FILENAME $DIR $EVENT
[ "$EVENT" == "IN_DELETE" ] && delete $FILENAME $EVENT

exit 0
