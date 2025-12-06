grep '^[A-Z][^ ]' $1 | sed '/IRET/s/intr:0/intr:1/' | grep intr:1 > fore
cat fore | grep ^CALL | tr -s ' '  | cut -d' ' -f7 | sort -u | cut -d ':' -f2 > fore_calls
cat fore_calls | while read addr ; do python3 calls_who.py $addr < fore ; done | awk '{print NF " " $0;}' | sort -n | cut -d' ' -f2-
grep '^[A-Z][^ ]' $1 | sed '/IRET/s/intr:0/intr:1/' | grep intr:0 > back
cat back | grep ^CALL | tr -s ' '  | cut -d' ' -f7 | sort -u | cut -d ':' -f2 > back_calls
cat back_calls | while read addr ; do python3 calls_who.py $addr < back ; done | awk '{print NF " " $0;}' | sort -n | cut -d' ' -f2-
