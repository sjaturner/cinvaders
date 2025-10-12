import sys
import re

lines = [line.strip().split() for line in sys.stdin]

func = dict()
for line in lines:
    if 'CALL' in line[0]:
        func[re.split(r':', line[-1])[1]] = None    

for index in range(len(lines)):
    if re.split(r':', lines[index][1])[1] in func:
        lines[index].insert(0, 'FUNC')
    else:
        lines[index].insert(0, '____')

for line in lines:
    print(' '.join(line))

