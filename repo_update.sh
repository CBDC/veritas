#!/bin/bash
set -e

source env.sh

# We'll need the VERITAS' public data directory declared..
: ${REPO_VERITAS?'VERITAS repo not defined'}
[ -z "$REPO_VERITAS_DATA_PUB" ] && { 1>&2 echo "Environment not loaded"; exit 1 }

TMPDIR=$(mktemp -d)

clean_exit() {
  rm -rf $TMPDIR
}
trap clean_exit EXIT ERR


csv2fits() {
  # Arguments:
  FILEIN="$1"
  FILEOUT="$2"
  FILELOG="$3"
  FLOGERR="$4"

  # Run the script to convert csv (veritas format) to fits
  source activate veritas
  script="${REPO_VERITAS}/proc/csv2fits.py"
  python script $FILEIN $FILEOUT > $FILELOG 2> $FLOGERR)
  return $?
}

is_file_ok () {
  FILE="$1"
  [ -f "$FILE" ]        || return 1
  [ "$FILE" != ".?*" ]  || return 1
  return 0
}

modify() {
  # Arguments:
  FILENAME="$1"
  DIR_IN="$2"
  EVENT="$3"

  DIR_LOG="${DIR_IN}/log"

  # Run veritas' csv2fits python script
  # If csv2fits succeeds, copy result to $REPO_VERITAS_DATA_PUB
  # and commit the change

  FILEIN="${DIR_IN}/${FILENAME}"
  is_file_ok $FILEIN || return 1

  _FROOT="${FILEIN%.*}"
  FILEOUT="${TMPDIR}/${_FROOT}.fits"
  FILELOG="${TMPDIR}/${_FROOT}_${EVENT#*_}.log"
  FLOGERR="${FILELOG}.error"
  unset _FROOT

  csv2fits $FILEIN $FILEOUT $FILELOG $FLOGERR

  if [ "$?" == "0" ]; then
    cp $FILEOUT   $REPO_VERITAS_DATA_PUB
    commit $EVENT
  else
    1>&2 echo "CSV2FITS failed. Output at '$DIR_LOG'"
  fi
  # Always copy the log/err output to archive's feedback
  mv $FILELOG $FLOGERR   $DIR_LOG
}

delete() {
  # Arguments:
  FILENAME="$1"
  EVENT="$2"
  # Remove filename from $REPO_VERITAS_DATA_PUB
  # and commit the change
  rm "${REPO_VERITAS_DATA_PUB}/$FILENAME"
  commit $EVENT
}

commit() {
  # Arguments:
  EVENT="$1"
  # Commit changes of $REPO_VERITAS_DATA_PUB
  (
    echo cd $REPO_VERITAS                        && \
    echo git commit -am "inotify change $EVENT"  &&\
    echo git push
  )
}