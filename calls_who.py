#!/usr/bin/python3
# grep '^[A-Z][^ ]' /tmp/big | sed '/IRET/s/intr:0/intr:1/' | grep intr:0 > out
import sys
import re

in_call = False
back = '0000'
calls = []
for line in sys.stdin:
    line = line.strip()

    if not in_call:
        if line.startswith('CALL') and 'jump:'+sys.argv[1] in line:
            in_call = True
            back = [elem for elem in line.split() if elem.startswith('next:')][0].split(':')[1]
            sub_depth = int([elem for elem in line.split() if elem.startswith('sub_depth:')][0].split(':')[1])

    if in_call:
        # print(line)
        if line.startswith('CALL'):
            new_depth = int([elem for elem in line.split() if elem.startswith('sub_depth:')][0].split(':')[1])
            if new_depth == sub_depth + 1:
                jump = [elem for elem in line.split() if elem.startswith('jump:')][0].split(':')[1]
                if not jump in calls:
                    calls.append(jump)

    if in_call:
        if [elem for elem in line.split() if elem.startswith('jump:')][0].split(':')[1] == back:
            # print('---')
            in_call = False
        
print(sys.argv[1], ' '.join(calls))
