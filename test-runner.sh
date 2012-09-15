#!/bin/bash

# Rather than modify this script, consider creating a wrapper script with
# better defaults for your project. See run-xray-tests.sh

#Default parameter values
#####################################################################
BASEURL=http://localhost:8889/xray/
CREDENTIALS=
DIR=test
MODULES=
TESTS=
#####################################################################


START=$(date +%s)
CRED=$(tput setaf 1)
CGREEN=$(tput setaf 2) 
CYELLOW=$(tput setaf 3)
CDEFAULT=$(tput sgr0)       
STATUS=0

function usage() {
      echo '
usage: test-runner.sh [options...]
Options:
      -c <user:password>    Credential for HTTP authentication.
      -d <path>             Look for tests in this directory.
      -h                    This message.
      -m <regex>            Test modules that match this pattern.
      -t <regex>            Test functions that match this pattern.
      -u <URL>              HTTP server location where index.xqy can be found.
'
      exit 1
}

while getopts 'c:d:hm:t:u:' OPTION
do
  case $OPTION in
    c) CREDENTIAL="$OPTARG";;
    d) DIR="$OPTARG";;
    h) usage;;
    m) MODULES="$OPTARG";;
    t) TESTS="$OPTARG";;
    u) BASEURL="$OPTARG";;
    *) usage;;
  esac
done

URL="$BASEURL?format=text&modules=$MODULES&tests=$TESTS&dir=$DIR"
CURL="curl --silent"
if [ -n "$CREDENTIAL" ]; then
    CURL="$CURL --anyauth --user $CREDENTIAL"
fi
RESPONSE=$($CURL "$URL")

if [ "$RESPONSE" = "" ]; then
  echo "Error: No response from $URL"
  STATUS=1
fi

while read -r LINE; do
  case $LINE in
    Module*) echo -ne $CDEFAULT;;
    *PASSED) echo -ne $CGREEN;;
    *IGNORED) echo -ne $CYELLOW;;
    *FAILED) STATUS=1; echo -ne $CRED;;
    Finished*) echo -ne $CDEFAULT;;
  esac
  echo $LINE
done <<< "$RESPONSE"

DIFF=$(( $(date +%s) - $START ))
echo -ne $CDEFAULT
#echo -e "Time: $DIFF seconds"

exit $STATUS

# end
