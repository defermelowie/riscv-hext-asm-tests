#!/usr/bin/env bash

# Print used emulator
printf "[INFO] Emulator: $1\n"

# Extract args
emulator=$1;
testdir=$2;
logdir=$3;

# Run tests
failed=0;
i=-3;
for test in "$@"
do
    i=$((i + 1));
    if  [ $i -gt 0 ]
    then
        printf "[TEST] ${test}";
        if timeout 5 $emulator $testdir/$test.elf > $logdir/$test.test.log 2>&1 && grep -q SUCCESS $logdir/$test.test.log
        then
        printf " - \x1b[32mok\x1b[0m"
        else
        printf " - \x1b[31mfail\x1b[0m"
        failed=$((failed + 1));
        fi
        printf "\n"
    fi
done

if [ $failed -eq 0 ]
then
    printf "[RESULT] All $i tests succeeded\n"
    exit 0
else
    printf "[RESULT] $failed/$i tests failed\n"
    exit -1
fi
