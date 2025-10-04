import sys
import re

covered = dict()
for line in open('accesses'):
    addr = int(line.strip(),16)
    covered[addr] = None

print(covered)

for line in sys.stdin:
    line = line.rstrip()
     
    m = re.match(r'.*; ([0-9a-f]{4}).*', line)
    if m:
        addr = int(m.group(1), 16)
        if addr in covered:
            print('@ %s'%line)
            continue

    print('  %s'%line)


