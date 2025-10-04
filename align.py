import sys
import re

for line in sys.stdin:
    line = line.rstrip()
    m = re.search(r'^\t+([^\t]+)\t+;([^\t]+)\t+([^\t]+)',line)
    if m:
        print('    %-32s ; %-8s %-32s'%(m.group(1),m.group(2), m.group(3)))
    else:
        print(line);
