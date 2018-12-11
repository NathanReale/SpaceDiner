# Reale CPU Spec

RCPU uses 16 bit words. Each operation is 16 bits. The lowest 4 bits make up the op code, 
and then there are two groups of 6 bits that make up the arguments. bbbbbbaaaaaaoooo

## Registers

* PC - Program Counter
* A - General (often accumulator)
* B - General (often backup)
* C - General
* H - Hardware register. Results from hardware polls are stored here.

## Instructions

* SET b a - 0x01 - Store b in a.
* ADD b a - 0x02 - Add a to b and store in a.
* SUB b a - 0x03 - Subtract b from a and store in a.
* JZE b a - 0x08 - Jump to a if b is zero.
* JNZ b a - 0x09 - Jump to a if b is not zero.

### Values

* 0x00 - 0x07 - Registers (A, B, C, H, PC - in order)
* 0x08 - 0x0f - [register] indirect addressing
* 0x10 - next word (literal)
* 0x11 - [next word]
* 0x1f - 0x3f - Literal between -1 and 0x1f (value - 0x20)


### Labels

* Labels can appear as '[a-z]+:', and then referenced later in a jump operation.

## Hardware

Hardware maps to the upper 0x8000 locations in RAM. Each hardware maps to a specific region
of RAM and can be controlled by writing values to the associated memory locations. 

## Example Program

```
SET 5 A
SET 7 B
ADD B A
```
