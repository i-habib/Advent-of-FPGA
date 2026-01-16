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

# Harcaml experience
This was my first time using an FPGA lagnauge. It is definetely more frusturating to type, but that is a given, and I definetely see the merit in so much customizability.



***

### Project Structure & Execution

**Directory Layout**
```text
.
├── input01.txt       # Puzzle input data
├── src/
│   ├── day01.ml      # Hardcaml circuit logic (RTL generation)
│   └── day01.mli     # Interface definition
└── test/
    ├── test01.ml     # OCaml testbench (Input parsing & Simulation drive)
    └── test01.mli    # Empty interface (Standard practice)
```

**Execution Instructions**

1.  **Input Configuration:**
    Ensure `input01.txt` is located in the project root.


2.  **Compilation:**
    To compile the circuit and the test harness, run:
    ```bash
    dune build
    ```

3.  **Simulation & Testing:**
    This project uses inline expectation tests. To run the simulation:
    ```bash
    dune runtest
    ```

 To accept the new output (i.e., to save the calculated answer into the test file), run:
    ```bash
    dune promote
    ```
    Subsequent runs of `dune runtest` will pass if unchanged.
