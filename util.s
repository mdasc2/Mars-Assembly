#
# This file contains a function used to implement syscalls from 
# MARS - This version simply call the appropriate syscalls with some
# massaging of the results. 
#
#  int InputDialogString (char *message, char * buf, int max) 
#     message is a message to be displayed
#     buf is a pointer to a character buffer at least of length max. 
#
#   The return value is the number of characters stored in buf, 
#   not counting the null byte (thus equivalent to strlen(buf)). 
#   If the user chose cancel in the dialog box, or types the 
#   single character q followed by a newline, the return value will be negative.
#
#   buf is always null-terminated and the newline does not appear in buf.  
#   If the user entered too much data, the extra data is lost.
#
	.text
    .globl  InputDialogString
InputDialogString:
    # int InputDialogString (char *message, char * buf, int max), 
    # leaf function
    # home arguments
    sw  $a0,0($sp)
    sw  $a1,4($sp)
    sw  $a2,8($sp)
    li  $t0,0
    sb  $t0,0($a1)
    li  $v0,54
    syscall
    li  $v0,-1
    beq $a1,-2,.IDSRet
    li  $v0,0
    beq $a1,-3,.IDSRet
    beq $a1,-4,.IDSstrlen
# 
#   check for q\n
#
    lw  $a1,4($sp)
    lb  $t0,0($a1)
    bne $t0,'q',.IDScont
    lb  $t0,1($a1)
    bne $t0,'\n',.IDScont
    li  $v0,-1
    b   .IDSRet
#
.IDScont:
    #
    # look for newline in buffer and store a nul byte on it
    #
    lw  $t0,4($sp)
.IDSck4null:
    lb  $t1,0($t0)
    beq $t1,$zero,.IDSstrlen
    bne $t1,'\n',.IDSnextbyte
    li  $t1,0
    sb  $t1,0($t0)
    b   .IDSstrlen
.IDSnextbyte:
    addi $t0,$t0,1
    b   .IDSck4null
.IDSstrlen:
    lw  $t0,4($sp)
    li $v0,0
.IDSstrlennext: 
    lb  $t1,0($t0)
    beq $t1,$zero,.IDSRet
    addi $t0,$t0,1
    addi $v0,$v0,1
    b   .IDSstrlennext
.IDSRet:
    jr  $ra
#
# void MessageDialog(char *message, int type).
#   the string message is output.
#   type is the same as that of syscall 55.
#
    .text
    .globl  MessageDialog
MessageDialog:
    # leaf. just do the syscall
    # arguments should be set correctly.
    li  $v0,55
    syscall
    jr  $ra
#
# void MessageDialogInt(char *message, int value)
#   the string message is output followed by the
#   integer value (translated to characters).
#
    .globl  MessageDialogInt
    # leaf. just a syscall
    # arguments are set correctly
MessageDialogInt:
    li  $v0,56
    syscall
    jr  $ra
#
# void PrintString(char *message)
#   prints the message using the old-fashioned SPIM syscalls
#
    .globl  PrintString
PrintString:
    li  $v0,4
    syscall
    jr  $ra
#
# void PrintInteger(int num)
#   prints the integer num using the old-fashioned SPIM syscalls
#
    .globl  PrintInteger
PrintInteger:
    li  $v0,1
    syscall
    jr  $ra
#
# void *sbrk(unsigned int nbytes)
#   returns a pointer to nbytes bytes of new memory
#   uses syscall 9
#
    .globl  sbrk
sbrk:
    li  $v0,9
    syscall
    # amazingly returns the pointer in $v0!
    jr  $ra
#
# void MessageDialogString(char *message, char *str)
#    uses syscall 59 to output a message followed by a string
#
    .globl  MessageDialogString
MessageDialogString:
    li  $v0,59
    syscall
    jr  $ra
#
# int InputDialogInt(char *message, int *num);
#   simple wrapper for syscall 51
#   any error from the syscall (negative status) is an error for IDI
#   errors are reported as a zero return value. 
#   A return value of 1 indicates success.
    .globl InputDialogInt
InputDialogInt:
    li  $v0,51
    # syscalls do not alter $v1, so use it to save num
    move    $v1,$a1
    syscall
    # this syscall has result in $a0, status in $a1
    # if error, just return
    move $v0,$zero
    bne $a1,$zero,.LIDIret
    li  $v0,1
    # store syscall return value into num
    sw  $a0,0($v1)
.LIDIret:
    jr  $ra
#
# int time(void)
#   uses syscall 30 to retrieve the time, discarding the high-order bits.
#   the low-order bits are converted to seconds and returned
#   NOTE: uses a divide instruction, so HI and LO are destroyed.
#
    .globl time
time:
    li      $v0,30
    syscall
    li      $v0,1000
    divu    $a0,$v0
    mflo    $v0
    jr      $ra
#
# void sleep(int nsecs)
#   uses syscall 32 to implement a sleep delay of nsecs seconds
#   NOTE: uses mult instruction, so LO and HI are destroyed.
#
    .globl sleep
sleep:
    # nsecs is in secs, syscall 32 wants milliseconds
    li      $v0,1000
    mult    $a0,$v0
    mflo    $a0
    li      $v0,32
    syscall
    jr      $ra
#
# void srandom(int seed)
#   sets the seed of random number generator #1
#   
    .globl srandom
srandom:
    move    $a1,$a0
    li      $a0,1
    li      $v0,40
    syscall
    jr      $ra
#
# unsigned int random(void)
#   using syscall 41, returns a pseudo-random integer in the range
#   [ 0, MAX ] using random number generator #1
#   MAX is implementation-defined.
#
    .globl  random
random:
    li      $a0,1
    li      $v0,41
    syscall
    move    $v0,$a0
    jr      $ra
#  
#
# axtoi.s - convert a string that 'looks like' a hex number
#       into the correponding integer.
#
#   int axtoi(int *num, char *string)
#
    .text
    .globl  axtoi
axtoi:
    # leaf procedure. no stack frame needed
    # $t0 is ch; $t1 is thisnum; $a0 is &num; $a1 is &string
    beq     $a1,$zero,.Laxtoifail
    beq     $a0,$zero,.Laxtoifail    # fail if either pointer arg is NULL
    sw      $zero,0($a0)        # initialize num to zero
.Laxtoiskip:
    lb      $t0,0($a1)          # ch = *string
    bne     $t0,$zero,.Laxtoiskipend # if (ch != 0) goto Laxtoiskipend
    add     $a1,$a1,1           # string++
    b       .Laxtoiskip
.Laxtoiskipend:
    beq     $t0,$zero,.Laxtoisucceed    # if (ch == 0) goto Laxtoisucceed
.Laxtoiloop:
    blt     $t0,'0',.Laxtoitrylower  # if ch is in ['0','9'], process it
    bgt     $t0,'9',.Laxtoitrylower
    sub     $t1,$t0,'0'
    b       .Laxtoiadd
.Laxtoitrylower:
    blt     $t0,'a',.Laxtoitryupper  # if ch is in ['a','f'], process it
    bgt     $t0,'f',.Laxtoitrynl
    sub     $t1,$t0,'a'
    add     $t1,$t1,10
    b       .Laxtoiadd
.Laxtoitryupper:
    blt     $t0,'A',.Laxtoitrynl      # if ch is in ['A','F'], process it
    bgt     $t0,'F',.Laxtoitrynl
    sub     $t1,$t0,'A'
    add     $t1,$t1,10
    b       .Laxtoiadd
.Laxtoitrynl:   
    bne     $t0,'\n',.Laxtoifail
    b       .Laxtoisucceed
.Laxtoiadd:  
    lw      $t2,0($a0)
    sll     $t2,$t2,4
    add     $t2,$t2,$t1
    sw      $t2,0($a0)
    add     $a1,$a1,1
    lb      $t0,0($a1)
    bne     $t0,$zero,.Laxtoiloop
.Laxtoisucceed:
    li      $v0,1
    jr      $ra
.Laxtoifail:
    li      $v0,0
    jr      $ra
# 
# unsigned strlen(const char *s) 
#  returns the length of s, not including the null byte
#  s is assumed to NOT be NULL
#
    .globl  strlen
strlen:
    # a0 has address of string
    li  $v0,-1
.Lstrlennext:
    lb  $t0,0($a0)
    addi $v0,$v0,1
    beq $t0,$zero,.Lstrlendone
    addi $a0,$a0,1
    b   .Lstrlennext
.Lstrlendone:
    jr  $ra
    .globl strcpy
strcpy:
# implements
#  char *strcpy(char *dest, char *src)
#  returning a pointer to dest.
#  dest is assumed to have room to store a copy of src.
#
    move    $v0,$a0
.Lstrcpynext:
    lb  $t0,0($a1)
    sb  $t0,0($a0)
    beq $t0,$zero,.Lstrcpydone
    addi    $a0,$a0,1
    addi    $a1,$a1,1
    b   .Lstrcpynext
.Lstrcpydone:
    jr  $ra
    .globl exit
exit:
# implements void exit(void)
# and exits the program with syscall 10
#
    li  $v0,10
    syscall
    # should never return
    jr  $ra
    
#int itoax(unsigned int num, char * string) {
#    
#    // returns 1 (true) unless string is NULL. If string is not NULL,
#    // assumes string has room for the max of 9 characters needed
#    // to convert num to its ASCII hexadecimal counterpart
#    // ALGORITHM: shifts num 8 times to reveal each hex digit.
#    //   skips leading 0 digits
#    int shiftamt=28;  // first shift is 28 bits
#    int thisdig;
#    if (string == NULL) return (0);
#
#    // skip leading zeroes
#    while (((num >> shiftamt) & 0xf)==0) {
#        if (shiftamt == 0) break;
#        shiftamt-=4;
#    }
#    while (shiftamt >= 0) {
#        thisdig=(num >> shiftamt)&0xf;
#        *string++ = itoxc(thisdig);
#        shiftamt -= 4;
#    }
#    *string=0;
#    return(1);
#}
#int itoax(unsigned int num, char * string) {
    .text
    .globl itoax
itoax:
    # this is not a leaf. We need room for our arguments (16)
    # and to save an s-register for the variable shiftamt, as well as $ra (8)
    addiu   $sp,$sp,-24
    sw      $ra,20($sp)
    sw      $s0,16($sp)
#    int shiftamt=28;  // first shift is 28 bits
#    int thisdig;
    addiu   $s0,$zero,28
#    if (string == NULL) return (0);
    bne     $a1,0,.Litoaxdoit
    li      $v0,0
    b       .Litoaxret
#    // skip leading zeroes
#    while (((num >> shiftamt) & 0xf)==0) {
.Litoaxdoit:
#    if (((num >> shiftamt) & 0xf) != 0) goto .Litoaxdigs;
    srlv    $t0,$a0,$s0
    andi    $t0,$t0,0xf
    bne     $t0,$zero,.Litoaxdigs
#        if (shiftamt == 0) break;
    beq     $s0,$zero,.Litoaxdigs
#        shiftamt-=4;
    addiu   $s0,$s0,-4
#    goto .Litaxdoit;
    b       .Litoaxdoit
#    }
.Litoaxdigs:
#    while (shiftamt >= 0) {
#   if (shiftamt < 0) goto .Litoax0
    blt     $s0,$zero,.Litoax0
#        thisdig=(num >> shiftamt)&0xf;
    srlv    $t0,$a0,$s0
    andi    $t0,$t0,0xf
#        *string++ = itoxc(thisdig);
    sw      $a0,24($sp)
    sw      $a1,28($sp)
    move    $a0,$t0
    jal     itoxc
    lw      $a0,24($sp)
    lw      $a1,28($sp)
    sb      $v0,0($a1)
    addi    $a1,$a1,1
#        shiftamt -= 4;
    addiu   $s0,$s0,-4
#   goto .Litoaxdigs
    b       .Litoaxdigs
#    }
.Litoax0:
#    *string=0;
    sb      $zero,0($a1)
#    return(1);
    li      $v0,1
.Litoaxret:
    # unwind stack and return
    lw      $s0,16($sp)
    lw      $ra,20($sp)
    addiu   $sp,$sp,24
    jr      $ra

#char itoxc(int i) {
#    char ch;
#    i &= 0xf;
#    ch = (i + '0');
#    if (i <= 9) goto Ldone
#    ch = 'a' + i - 10;
#Ldone:
#    return (ch);
#}
    .text
    .globl  itoxc
itoxc:
    # leaf procedure - needs no stack frame. Only uses t regs
    # $t0 will be ch
    andi    $a0,$a0,0xf
    addi    $t0,$a0,'0'
    ble     $a0,9,.Litoxcdone
    addi    $t0,$a0,'a'
    addi    $t0,$t0,-10
.Litoxcdone:
    move    $v0,$t0     # should have used $v0 in the beginning.
    jr      $ra

