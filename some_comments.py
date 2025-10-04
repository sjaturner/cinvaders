import sys
import re

comments = dict()
for line in open('code.asm'):
    line = line.rstrip()
    m = re.match(r'\s+([0-9A-F]{4}):.*;([^;]*)', line)
    if m:
        addr = int(m.group(1), 16);
        if addr >= 0x1a93:
            continue
#       print(line, m.group(1), m.group(2))
        comment = m.group(2).strip()
        if comment:
            comments[addr] = m.group(2)

for line in sys.stdin:
    line = line.rstrip()
    while len(line) < 64:
        line += ' '
     
    m = re.match(r'.*; ([0-9a-f]{4}).*', line)
    if m:
        addr = int(m.group(1), 16)
        if addr in comments:
            print('%s ; %s'%(line, comments[addr]))
            continue

    print(line)


