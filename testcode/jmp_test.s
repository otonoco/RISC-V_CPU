jmp_test.s:
.align 4
.section .text
.globl _start
    # Refer to the RISC-V ISA Spec for the functionality of
    # the instructions in this test program.
_start:
    # Note that the comments in this file should not be taken as
    # an example of good commenting style!!  They are merely provided
    # in an effort to help you understand the assembly style.

    # Note that one/two/eight are data labels

  li a0, 9
  jal factorial
  mv x18, a0
  la x19, factorial
  li a0, 11
  jalr x19
  mv x20, a0
  j halt

factorial:	
  # lw a0, some_label

   mv t3, a0       #t3 is the input value
   mv t2, a0       #t2 is the factorial counter
   li t4, 1        # t4 <= 1
	
LOOP_START:	
   addi t2, t2, -1
   ble t2, t4, LOOP_END
   li t0, 0
   mv t1, t2            #t1 is the mul counter
	
MUL:	
   blt t1, t4, MUL_END   #t1 is the mul counter
   add t0, t0, t3        #t0 stores the mul value
   add t1, t1, -1
   j MUL

MUL_END:	
   mv t3, t0
   j  LOOP_START

LOOP_END:	
   mv a0, t3           #t3 stores the final value
	
ret:
   jr ra

.section .rodata

halt:                 # Infinite loop to keep the processor
    beq x0, x0, halt	
some_label: .word 0x9
