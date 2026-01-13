# Advent of FPGA
# AOC Challenge: Day 1, P1
<br>

# Generalic Logic
### Relatively straightforward (see) python.py
 Basically just bruteforce raw points assuming "stacking" across the numberline
 Then take it mod 100 to restore to range [0, 99]
 Keep a rolling track of number of times it crosses 0

# Modulus optimization
### I was unable to find a native hardcaml modulus operator. I used two methods to copy the logic
### Method 1 (naive): 
brute force repeated addition and subtraction (# times determined by quick script run beforehand to count range)
### Method 2 (fast):
 basically x % 100 can be rewritten like this:
$$x \pmod{100} = x - 100 \cdot \left\lfloor \frac{x}{100} \right\rfloor$$
<br>
 We can approximate 1/100 by 20972 >> 21 (logic for this in code comments), and from there implementation is easy.

<br>
