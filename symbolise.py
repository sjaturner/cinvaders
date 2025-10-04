import sys
import re

symbols = [line.split() for line in open('symbols')]
code = dict(((addr, symbol) for addr, sort, camel, symbol in symbols if sort == 'code'))
data = dict(((addr, symbol) for addr, sort, camel, symbol in symbols if sort == 'data'))
for line in sys.stdin:
    line = line.rstrip()
    
    m = re.match(r'.*;([0-9a-f]{4}).*', line)
    if m and m.group(1) in code:
        print('%s:'%code[m.group(1)])

    if re.match(r'^\s', line):
        for addr in code:
            subroutine = '\\bsub_%sh\\b'%addr
            line = re.sub(subroutine, code[addr], line)
            label = '\\bl%sh\\b'%addr
            line = re.sub(label, code[addr], line)
        for addr in data:
            subroutine = '\\b0%sh\\b'%addr
            line = re.sub(subroutine, data[addr], line)
    print(line)

print()

for addr in sorted(data):
    print('%-30s equ 0%sh'%(data[addr] + ':', addr))

