#!/usr/bin/env bash

# Extract args
emulator=$1;
testdir=$2;
logdir=$3;

# Print info
printf "[INFO] Emulator: ${emulator}\n"

# Run tests
failed=0;
i=-3;
for test in "$@"
do
    i=$((i + 1));
    if  [ $i -gt 0 ]
    then
        printf "[TEST] ${test}";
        if timeout --foreground 5 ${emulator} -l --log-commits --isa=RV64gh ${testdir}/${test}.elf 2> ${logdir}/${test}.verif.log
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
