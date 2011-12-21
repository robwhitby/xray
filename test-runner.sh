#!/bin/bash

#Sample test runner script, only tested on OSX

#Edit these default values
#####################################################################
BASEURL=http://localhost:8889/xray/index.xqy
DIR=test
MODULES=
TESTS=
#####################################################################


START=$(date +%s)
CRED=$(tput setaf 1)
CGREEN=$(tput setaf 2) 
CDEFAULT=$(tput sgr0)       
STATUS=0

while getopts 'u:m:t:d:h' OPTION
do
  case $OPTION in
    u) BASEURL="$OPTARG";;
    m) MODULES="$OPTARG";;
    t) TESTS="$OPTARG";;
    d) DIR="$OPTARG";;
    *)
      echo "usage: test-runner.sh [-u URL of index.xqy] [-m module name regex] [-t test name regex] [-d test directory]"
      exit 1;;
  esac
done

URL="$BASEURL?format=text&modules=$MODULES&tests=$TESTS&dir=$DIR"
RESPONSE=$(curl --silent "$URL")

if [ "$RESPONSE" = "" ]; then
  echo "Error: No response from $URL"
  STATUS=1
fi

while read -r LINE; do
  case $LINE in
    Module*) echo -ne $CDEFAULT;;
    *PASSED) echo -ne $CGREEN;;
    *FAILED) STATUS=1; echo -ne $CRED;;
    Finished*) echo -ne $CDEFAULT;;
  esac
  echo $LINE
done <<< "$RESPONSE"

DIFF=$(( $(date +%s) - $START ))
echo -ne $CDEFAULT
#echo -e "Time: $DIFF seconds"

exit $STATUS
