# Reale CPU Spec

RCPU uses 16 bit words. Each operation is 16 bits. The lowest 4 bits make up the op code, 
and then there are two groups of 6 bits that make up the arguments. bbbbbbaaaaaaoooo

## Registers

* PC - Program Counter
* SP - Stack Pointer
* A - General (often accumulator)
* B - General (often backup)
* C - General

### Stack
 
There is a reverse stack at the end of ram, starting at 0xFFFF. The stack pointer (SP)
points to the top of the stack. PUSH, POP, and PEAK operations are supported.

## Instructions

* SET b a - 0x01 - Store b in a.
* ADD b a - 0x02 - Add a to b and store in a.
* SUB b a - 0x03 - Subtract b from a and store in a.
* JZE b a - 0x08 - Jump to a if b is zero.
* JNZ b a - 0x09 - Jump to a if b is not zero.
* JSR b - 0x0F - Push PC onto the stack and jump to b.

### Values

* 0x00 - 0x07 - Registers (A, B, C, PC, SP - in order)
* 0x08 - 0x0f - [register] indirect addressing
* 0x10 - next word (literal)
* 0x11 - [next word]
* 0x12 - If a PUSH / [--SP], if b POP / [SP++]
* 0x13 - PEAK / [SP]
* 0x1f - 0x3f - Literal between -1 and 0x1f (value - 0x20)


### Labels

* Labels can appear as '[a-z]+:', and then referenced later in a jump operation.

## Hardware

Hardware maps to the upper 0x8000 locations in RAM. Each hardware maps to a specific region
of RAM and can be controlled by writing values to the associated memory locations. 

### Motor

Controlled by writing to 0x00 location. When in motion, new controls will be ignored,
and the status will be set to 0xFFFF in the 0x01 location.

Controls:

* 0x1 - Up
* 0x2 - Down
* 0x4 - Left
* 0x8 - Right
