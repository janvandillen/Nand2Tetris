# notes

- [notes](#notes)
  - [hack](#hack)
    - [A-operation](#a-operation)
    - [C-operation](#c-operation)
      - [comp Table](#comp-table)
      - [Dest and jump table](#dest-and-jump-table)
  - [Assembly](#assembly)
    - [a-operation](#a-operation-1)
    - [c-operation](#c-operation-1)
    - [Symbols](#symbols)
  - [VM](#vm)
    - [Arithmetic](#arithmetic)
      - [add/sub/and/or](#addsubandor)
      - [neg/not](#negnot)
      - [eq/lt/gt](#eqltgt)
    - [Memory access](#memory-access)
      - [Push](#push)
      - [POP](#pop)
      - [local/argument/this/that](#localargumentthisthat)
        - [Push Local i](#push-local-i)
        - [Pop Local i](#pop-local-i)
      - [Constant](#constant)
        - [Push constant i](#push-constant-i)
      - [Static](#static)
        - [Push static i](#push-static-i)
        - [Pop static i](#pop-static-i)
      - [Temp](#temp)
        - [Push temp i](#push-temp-i)
        - [Pop temp i](#pop-temp-i)
      - [Pointer](#pointer)
        - [Push pointer 0/1](#push-pointer-01)
        - [Pop pointer 0/1](#pop-pointer-01)

## hack

the first bit (`w[0]`) decides if it is an A operation or a C one.

### A-operation

a value is set in the A-register

| word      | value               | example           | example translation |
| --------- | ------------------- | ----------------- | ------------------- |
| `w[0]`    | `0`                 | `0`               | fixed               |
| `w[1-15]` | the value in binary | `000000000110010` | `50`                |

### C-operation

| word       | value                                     | example   | example translation    |
| ---------- | ----------------------------------------- | --------- | ---------------------- |
| `w[0-2]`   | `111`                                     | `111`     | fixed                  |
| `w[3]`     | set A-register as pointer or value        | `0`       | uses A-register as is  |
| `w[4-9]`   | the computation. See comp table           | `0011100` | `D-1`                  |
| `w[10-12]` | destination of the answer. see dest table | `100`     | A-register             |
| `w[13-15]` | jump condition. see jump table            | `110`     | jump if lower or equal |

#### comp Table

| `a=0` | `w[4-9]` | `a=1` |
| ----- | -------- | ----- |
| `0`   | `101010` |
| `1`   | `111111` |
| `-1`  | `111010` |
| `D`   | `001100` |
| `A`   | `110000` | `M`   |
| `!D`  | `001101` |
| `!A`  | `110001` | `!M`  |
| `-D`  | `001111` |
| `-A`  | `110011` | `-M`  |
| `D+1` | `011111` |
| `A+1` | `110111` | `M+1` |
| `D-1` | `001110` |
| `A-1` | `110010` | `M-1` |
| `D+A` | `000010` | `D+M` |
| `D-A` | `010011` | `D-M` |
| `A-D` | `000111` | `M-D` |
| `D&A` | `000000` | `D&M` |
| `D|A` | `010101` | `D|M` |

#### Dest and jump table

| dest   | value | jump   |
| ------ | ----- | ------ |
| `null` | `000` | `null` |
| `M`    | `001` | `JGT`  |
| `D`    | `010` | `JEQ`  |
| `MD`   | `011` | `JGE`  |
| `A`    | `100` | `JLT`  |
| `AM`   | `101` | `JNE`  |
| `AD`   | `110` | `JLE`  |
| `AMD`  | `111` | `JMP`  |

## Assembly

`//` is used for comments

`@` is used to specify that it is an A-operation

### a-operation

it should start by `@` followed by a value between -16384 and 16383 or a variable. E.g.:

* `@35`: set the A-register to 35
* `@value`: set the A-register to the value of the variable
* `@newvalue`: if the variable does not exist give it is given a new value between 16 and 255
* `@LABEL`: if it is a label instead it wil use the number of the next command of the label

### c-operation

the format goes as follow `[dest]=[comp];[jump]` both dest and jump can be omitted. in that case they are considered as `null`. E.g.:

* `D=D+A`: increment D register with A
* `D;JGT`: Jump if D-register is greater then 0;
* `AD=D-1;JMP`: after setting the D and A register to `D-1` Jump

### Symbols

there are three types symbols

* Labels: they link to a location in the code they are marked with parenthesis. `(LABEL)`
* constants: they are fixed values specific to the cpu see table.
* variable: those are the adresses for memory location 16 to 255

| Label    | RAM     |
| -------- | ------- |
| `SP`     | `0`     |
| `LCL`    | `1`     |
| `ARG`    | `2`     |
| `THIS`   | `3`     |
| `THAT`   | `4`     |
| `R0-R15` | `0-15`  |
| `SCREEN` | `16384` |
| `KBD`    | `24576` |

## VM

### Arithmetic

* y is at the top of stack
* x is second from the top

| Command | Return value | Return type |
| ------- | ------------ | ----------- |
| `add`   | x + y        | integer     |
| `sub`   | x - y        | integer     |
| `neg`   | -y           | integer     |
| `eq`    | x==y         | boolean     |
| `gt`    | x > y        | boolean     |
| `lt`    | x < y        | boolean     |
| `and`   | x and y      | boolean     |
| `or`    | x or y       | boolean     |
| `not`   | not y        | boolean     |

#### add/sub/and/or

* decrease pointer (`P`)
* get value
* get value from `P-1`
* add both value and set it to `p-1`

```assembly
@SP
AM=M-1
D=M
A=A-1
M=D+M//M=M-D//M=M&D//M=M|D
```

#### neg/not

```assembly
@SP
A=M-1
M=-M/m=!M
```

#### eq/lt/gt

* decrease pointer (`P`)
* get value
* get value from `P-1`
* substract both value and jump if eq
* if not equal set `P-1` to `0` and jump to end
* if equal set `P-1` to `-1`

V1: eq=10;neq=12

```assembly
@SP
AM=M-1
D=M
A=A-1
D=M-D
@EQ
D;JEQ//D;JLT//D;JGT
@SP
A=M-1
M=0
@END
0;JMP
(EQ)
@SP
A=M-1
M=-1
(END)
```

V2: eq=8;neq=11

```assembly
@SP
AM=M-1
D=M
A=A-1
D=M-D
M=-1
@END
D;JEQ//D;JLT//D;JGT
@SP
A=M-1
M=0
(END)
```

### Memory access

#### Push

* get value from memory
* set value in stack
* increment pointer

```assembly
[get value]
@SP
M=M+1
A=M-1
M=D
```

#### POP

* decrement pointer
* get value from stack
* set value in memory

```assembly
@SP
AM=M-1
D=M
[set value]
```

#### local/argument/this/that

memory location `LCL` is a pointer to the base of the `Local` memory space

the same code can be applied to argument/this/that using `ARG`/`THIS`/`THAT` as pointers

##### Push Local i

```assembly
@LCL
D=M
@[i]
A=D+A
D=M
[Push]
```

| code    | D    | A      | M    | SP  | LCL  |
| ------- | ---- | ------ | ---- | --- | ---- |
| `@LCL`  | ?    | 1      | 1024 | 257 | 1024 |
| `D=M`   | 1024 | 1      | 1024 | 257 | 1024 |
| `@[i]`  | 1024 | i      | ?    | 257 | 1024 |
| `A=D+A` | 1024 | 1024+i | X    | 257 | 1024 |
| `D=M`   | X    | 1024+i | X    | 257 | 1024 |
| `@SP`   | X    | 0      | 257  | 257 | 1024 |
| `M=M+1` | X    | 0      | 258  | 258 | 1024 |
| `A=M-1` | X    | 257    | ?    | 258 | 1024 |
| `M=D`   | X    | 257    | X    | 258 | 1024 |

##### Pop Local i

| code     | D      | A      | M      | SP  | LCL    |
| -------- | ------ | ------ | ------ | --- | ------ |
| `@LCL`   | ?      | 1      | 1024   | 257 | 1024   |
| `D=M`    | 1024   | 1      | 1024   | 257 | 1024   |
| `@[i]`   | 1024   | i      | ?      | 257 | 1024   |
| `D=D+A`  | 1024+i | i      | ?      | 257 | 1024   |
| `@LCL`   | 1024+i | 1      | 1024   | 257 | 1024   |
| `M=D`    | 1024+i | 1      | 1024+i | 257 | 1024+i |
| `@SP`    | 1024+i | 0      | 257    | 257 | 1024+i |
| `AM=M-1` | 1024+i | 256    | X      | 256 | 1024+i |
| `D=M`    | X      | 256    | X      | 256 | 1024+i |
| `@LCL`   | X      | 1      | 1024+i | 256 | 1024+i |
| `A=M`    | X      | 1024+i | ?      | 256 | 1024+i |
| `M=D`    | X      | 1024+i | X      | 256 | 1024+i |
| `D=A`    | 1024+i | 1024+i | X      | 256 | 1024+i |
| `@[i]`   | 1024+i | i      | ?      | 256 | 1024+i |
| `D=D-A`  | 1024   | i      | ?      | 256 | 1024+i |
| `@LCL`   | 1024   | 1      | 1024+i | 256 | 1024+i |
| `M=D`    | 1024   | 1      | 1024   | 256 | 1024   |

| code     | D      | A      | M      | SP  | LCL  | TEMP   |
| -------- | ------ | ------ | ------ | --- | ---- | ------ |
| `@LCL`   | ?      | 1      | 1024   | 257 | 1024 | ?      |
| `D=M`    | 1024   | 1      | 1024   | 257 | 1024 | ?      |
| `@[i]`   | 1024   | i      | ?      | 257 | 1024 | ?      |
| `D=D+A`  | 1024+i | i      | ?      | 257 | 1024 | ?      |
| `@TEMP`  | 1024+i | T      | ?      | 257 | 1024 | ?      |
| `M=D`    | 1024+i | T      | 1024+i | 257 | 1024 | 1024+i |
| `@SP`    | 1024+i | 0      | 257    | 257 | 1024 | 1024+i |
| `AM=M-1` | 1024+i | 256    | X      | 256 | 1024 | 1024+i |
| `D=M`    | X      | 256    | X      | 256 | 1024 | 1024+i |
| `@TEMP`  | X      | T      | 1024+i | 256 | 1024 | 1024+i |
| `A=M`    | X      | 1024+i | ?      | 256 | 1024 | 1024+i |
| `M=D`    | X      | 1024+i | X      | 256 | 1024 | 1024+i |

#### Constant

##### Push constant i

```assembly
@[i]
D=A
[Push]
```

#### Static

##### Push static i

```assembly
@Foo.i
D=M
[Push]
```

##### Pop static i

```assembly
[Pop]
@Foo.i
M=D
```

#### Temp

##### Push temp i

```assembly
@[5+i]
D=M
[Push]
```

##### Pop temp i

```assembly
[Pop]
@[5+i]
M=D
```

#### Pointer

##### Push pointer 0/1

```assembly
@[3/4]
D=M
[Push]
```

##### Pop pointer 0/1

```assembly
[Pop]
@[3/4]
M=D
```
