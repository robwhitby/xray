#!/bin/bash
START=$(date +%s)
URL=http://localhost:8889/src/test-runner.xqy
MODULES=
TESTS=
CGREEN="\e[0;32m"
CRED="\e[0;31m"
CDEFAULT="\e[0m"
STATUS=0

while getopts 'u:m:t:h' OPTION
do
    case $OPTION in
        u) URL="$OPTARG";;
        m) MODULES="$OPTARG";;
        t) TESTS="$OPTARG";;
        *)
            echo "usage: [-u test runner url] [-m module name pattern] [-t test name pattern]"
            exit 1;;
    esac
done

RESPONSE=$(curl --silent "$URL?format=text&modules=$MODULES&tests=$TESTS")

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
echo -e "Time: $DIFF seconds"

exit $STATUS
