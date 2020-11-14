Usman Amin and Ahmed Boutar
CSC254
November 6, 2020
NETID: uamin2 NETID: abiurar
----- CONTENT -----
xref - Main program to execute. Outputs html to a file called out.html in subdirectory XREF. Written in Ruby.
XREF - subdirectory that contains:
    home.html - Launch this to get homepage containing link to cross-referenced code
    [out.html]
test.rs - example file for testing. Combination of both main.rs and fib.rs that was given by the TA Daniel Busaba.


----- FEATURES -----
Program xref uses the output of llvm-dwarfdump and objdump -d (also found in usr/bin/) to construct a web page 
that contains side-by-side assembly language and corresponding source code for a given program.  The assembly 
and source is lined up as follows: the first instruction in each contiguous block of instructions 
that come from the same line of source is horizontally aligned with a copy of that source line.  Source lines without 
corresponding assembly instructions is presented immediately above the first occurrence 
of the following source line.  Assembly code for which there is no corresponding source is omitted.  
Source for in-lined functions is displayed in-line. For the sake of clarity, the second and subsequent 
occurrences are “grayed-out".  

Only works for one Rust file, not cargos

In order to run the program again, you must delete out.html so a new, blank one can be created. Running the program again 
without deleting out.html will concatenate the latest version of out.html to the previous content, which is not desired.

Styled with Bootstrap!

----- HOW TO RUN -----
1. Be in directory with xref (file), XREF (folder), and Rust file.
2. Compile Rust file with 
        rustc -g -o r myprogram.rs
3. Run main program with
        ruby xref myprogram
4. Open home.html and follow link to code.  