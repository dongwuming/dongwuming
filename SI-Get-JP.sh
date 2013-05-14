#!/bin/bash
while read line
do
./SI-Deplace_Log_For_Ncmc.sh $line
done < list-TS-log
