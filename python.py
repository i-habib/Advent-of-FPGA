import sys
val = 50
cnt = 0
def norm(n):
    n = n%100
    if (n < 0):
        print('ehheashjdas')
    return n
for line in sys.stdin:
    dir = line[0]
    value = int(line[1:])
    sign = 0
    sign = -1 if dir == "L" else 1
    val += sign * value
    val = norm(val)
    if(val == 0):
        cnt+=1
print(cnt)

