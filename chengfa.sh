#!/bin/bash

for j in `seq 9`;do
    for i in `seq $j`;do
        let res=$j*$i
        echo -e -n "$j*$i=$res "
    done
    echo ""
done
