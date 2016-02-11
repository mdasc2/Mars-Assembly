# void checkregs(void); // contained in mymul_main.s
#
# int mymul(int left, int right){
#    int retval;
#    // the function checkregs must be called here
#    // it ensures you are following the calling convention.
#    checkregs();
#    // here is the code for mymul that you must write
#    if (left == 1) retval=right;
#    else retval=(right+mymul(left-1,right));
#    return(retval);
#}

    .globl mymul
mymul:  
    # put your entry code here
	addiu $sp, $sp , -28
	sw $ra, 24($sp) 
	sw $a0, 28($sp)
	sw $a1, 32($sp) 
	
    # you must call the function checkregs 
	jal     checkregs
    # finish mymul here
	li $t1, 1	# 1
	
	lw $a0, 28($sp)
	lw $a1, 32($sp) 
		
	beq $a0, $t1, equalsone	#if left ==1 then retval is 1 times right side	
	sub $a0, $a0, $t1 # left - 1
	
	jal mymul
	
	add $v0, $v0, $a1
	
	b done
	
	equalsone:
	move $v0, $a1
	
	done:
	lw $ra, 24($sp)
	addiu $sp, $sp , 28
    # and eventually return
	jr      $ra



# mymul_main.s - a partial implementation of the mymul program
#  the user enters a multiplier and multiplicand the the
#  program computes multiplier * multiplicand using 
#  a recursive function mymul (see below)

# /* product = multiplier * multiplicand */
#
# the function int mymul(int left, int right); is supplied by the user
# the support functions and main program follow:
    .data
banner:  .asciiz "Welcome to multiply. Enter the integers to multiply together"
multiplier_prompt:  .asciiz "Enter the multiplier (first number):"
multiplicand_prompt:  .asciiz "Enter the multiplicand (second number):"
result_banner:  .asciiz "Result="

    .text
    .globl main
# main() {
main:
    # main needs standard argument stack space, to save $ra 
    # and it needs three words of stack space for 
    # multiplier, multiplicand and product
    addiu   $sp,$sp,-32
    sw      $ra,28($sp)
    # 24($sp) is product
    # 20($sp) is multiplicand
    # 16($sp) is multiplier
    #    puts("Welcome to multiply. Enter the integers to multiply together");
    li      $a1,1
    la      $a0,banner
    jal     MessageDialog
    #
    #    multiplier = get_int("Enter the multiplier (first number):");
    la      $a0,multiplier_prompt
    jal     get_int
    sw      $v0,16($sp)

    #    multiplicand = get_int("Enter the multiplicand (second number):");
    la      $a0,multiplicand_prompt
    jal     get_int
    sw      $v0,20($sp)

    #    product=mymul(multiplier,multiplicand);
    lw      $a0,16($sp)
    lw      $a1,20($sp)
    jal     mymul
    sw      $v0,24($sp)

    #    printf("Result=%d\n",product);
    la      $a0,result_banner
    lw      $a1,24($sp)
    jal     MessageDialogInt

    lw      $ra,28($sp)
    addiu   $sp,$sp,32
    jr      $ra
#}

    .data
notpositive:  .asciiz "you must enter a positive integer"
    .text
.globl get_int
get_int:
    # stack frame needed 
    addiu   $sp,$sp,-24
    # one temp space needed for integer result from InputDialogInt
    # at 16($sp)
    sw      $ra,20($sp)
    # $a0 must be homed!
    # home $a0
    sw      $a0,24($sp)
Lloop:
    # move original a0 (prompt) back from home location
    # (in case this isn't the first time around the loop)
    lw      $a0,24($sp)
    # create the address of the temporary integer
    add     $a1,$sp,16  
    jal     InputDialogInt
    # did InputDialogInt return an error?
    beq     $v0,$zero,Lbadint
    # get the number stored by InputDialogInt
    lw      $v0,16($sp)
    # if the number was interpreted as a positive integer, we're done
    bgt     $v0,$zero,Lret1

    # if not, complain about the integer and try again
Lbadint:

    # output a message that the integer must be positive
    la      $a0,notpositive
    li      $a1,2
    jal     MessageDialog

    # get another integer
    b       Lloop

Lret1:

    # result is in $v0 already.
    # just unwind the stack and return
    lw      $ra,20($sp)
    addiu   $sp,$sp,24
    jr      $ra


    .globl checkregs
checkregs:    
    # this function just destroys all volatile registers
    # and writes over its argument area
    li      $t0,-1
    move    $t1,$t0
    move    $t2,$t0
    move    $t3,$t0
    move    $t4,$t0
    move    $t5,$t0
    move    $t6,$t0
    move    $t7,$t0
    move    $t8,$t0
    move    $t9,$t0
    move    $a0,$t0
    move    $a1,$t0
    move    $a2,$t0
    move    $a3,$t0
    move    $v0,$t0
    move    $v1,$t0
    sw      $t0,0($sp)
    sw      $t0,4($sp)
    sw      $t0,8($sp)
    sw      $t0,12($sp)
    jr      $ra
.include "/pub/cs/gboyd/cs270/util.s"

