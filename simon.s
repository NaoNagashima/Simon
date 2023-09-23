.data
sequence:  .byte 0,0,0,0
count:     .word 1
promptStart: .string "press any key on the D Pad to start the game\n"
promptReplay: .string "press top button to continue playing for next round or bottom button to exit\n"
promptEnter: .string "please enter the same pattern on the D Pad"
newline: .string "\n"
promptRound: .string "Round: "
.globl main
.text

main:
    # TODO: Before we deal with the LEDs, we need to generate a random
    # sequence of numbers that we will use to indicate the button/LED
    # to light up. For example, we can have 0 for UP, 1 for DOWN, 2 for
    # LEFT, and 3 for RIGHT. Store the sequence in memory. We provided 
    # a declaration above that you can use if you want.
    # HINT: Use the rand function provided to generate each number
    
    
    li a7, 4
    la a0, promptStart
    ecall
    
    call pollDpad
    
    
    # initialize the random seed in x20
    li a7, 30
    ecall
    mv x20, a0
    slli x20, x20, 28
    srli x20, x20, 28
    
    # initialize the starting count and round
    lw x21, count
    li x22, 1

start:
    
    li a7, 4
    la a0, promptRound
    ecall
    
    li a7, 1
    mv a0, x22
    ecall
    
    li a7, 4
    la a0, newline
    ecall
    
    call resetBoard
    # register sequence into s0
    la s0, sequence
    # s1 is the accumulator of the loop
    li s1, 0
    
LOOPSEQ:
    beq s1, x21, ENDSEQ
    
    call lsfr
    
    mv a0, x20
    
    slli a0, a0, 30
    srli a0, a0, 30

    sw a0, 0(s0)
    addi s0, s0, -4
    addi s1, s1, 1
 
    j LOOPSEQ
ENDSEQ:
    
    li t0, 4
    mul t0, t0, x21
    
    add s0, s0, t0
    
    # TODO: Now read the sequence and replay it on the LEDs. You will
    # need to use the delay function to ensure that the LEDs light up 
    # slowly. In general, for each number in the sequence you should:
    # 1. Figure out the corresponding LED location and colour
    # 2. Light up the appropriate LED (with the colour)
    # 2. Wait for a short delay (e.g. 500 ms)
    # 3. Turn off the LED (i.e. set it to black)
    # 4. Wait for a short delay (e.g. 1000 ms) before repeating
    
    # s1 is the accumulator of the loop
    li s1, 0
    # s2 is the loop condition
    
LOOPCOLOR:
    beq s1, x21, ENDCOLOR
    
    # s3 is the value in sequence
    lw s3, 0(s0)
    
    li a4, 0
    beq s3, a4, TOP 
    li a4, 1
    beq s3, a4 DOWN
    li a4, 2
    beq s3, a4, LEFT
    li a4, 3
    beq s3, a4, RIGHT

RETURN:
    
    mv t4, a1
    li a0, 500
    call delay
    
    call resetBoard
    
    addi s0, s0, -4
    addi s1, s1, 1
    
    li a0, 1000
    call delay
    
    j LOOPCOLOR

TOP:
    li a0, 0xFFFF00
    li a1, 1
    li a2, 0
    call setLED
    
    j RETURN
LEFT:
    li a0, 0x00FF00
    li a1, 0
    li a2, 1
    call setLED
    
    j RETURN
RIGHT:
    li a0, 0x0000FF
    li a1, 2
    li a2, 1
    call setLED
    
    j RETURN
DOWN:
    li a0, 0xFF0000
    li a1, 1
    li a2, 2
    call setLED
    
    j RETURN
    
ENDCOLOR:

    li t0, 4
    mul t0, t0, x21
    
    add s0, s0, t0
    # TODO: Read through the sequence again and check for user input
    # using pollDpad. For each number in the sequence, check the d-pad
    # input and compare it against the sequence. If the input does not
    # match, display some indication of error on the LEDs and exit. 
    # Otherwise, keep checking the rest of the sequence and display 
    # some indication of success once you reach the end.
    
    # s1 is the accumulator of the loop
    li s1, 0
    
    # s2 is used to check if zero state exists
    li s2, 0
    
    li a7, 4
    la a0, promptEnter
    ecall
    
LOOPPOLL:
    beq s1, x21, SUCCESS
    lw a5, 0(s0)
    li t0, 0
    bne a5, t0, IFNOTZERO
checked:
    call pollDpad
    bne a0, a5, ERROR
    addi s0, s0, -4
    addi s1, s1, 1
    
    j LOOPPOLL
IFNOTZERO:
    addi s2, s2, 1
    j checked

ERROR:
    
    li a0, 0xFF0000
    li a1, 1
    li a2, 1
    call setLED
    
    li a0, 500
    call delay
    
    call resetBoard
    
    j exit

SUCCESS:
    li a0, 0x00FF6E
    li a1, 1
    li a2, 1
    call setLED
    
    li a0, 500
    call delay
    
    j ENDPOLL
ENDPOLL:
    li t0, 4
    mul t0, t0, x21
    
    add s0, s0, t0
    li t0, 0
    beq s2, t0, zerostate
    call resetBoard
    
    # TODO: Ask if the user wishes to play again and either loop back to
    # start a new round or terminate, based on their input.
prompt:
     li a7, 4
     la a0, newline
     ecall
     li a7, 4
     la a0, promptReplay
     ecall
     call pollDpad
     li t0, 0
     li t1, 1
     beq a0, t0, replay
     beq a0, t1, exit
     j prompt

replay:
    addi x22, x22, 1
    addi x21, x21, 1
    
    j start

     
exit:
    li a7, 10
    ecall

# --- OWN FUNCTIONS ----------------------------

resetBoard:
    mv t2, ra

    li a0, 0
    li a1, 0
    li a2, 0
    call setLED
    li a1, 0
    li a2, 2
    call setLED
    li a1, 1
    li a2, 1
    call setLED
    li a1, 2
    li a2, 0
    call setLED
    li a1, 2
    li a2, 2
    call setLED
    
    li a0, 0x006400
    li a1, 0
    li a2, 1
    call setLED
    li a0, 0x646400
    li a1, 1
    li a2, 0
    call setLED
    li a0, 0x640000
    li a1, 1
    li a2, 2
    call setLED
    li a0, 0x000064
    li a1, 2
    li a2, 1
    call setLED
    
    mv ra, t2
    
    jr ra

lsfr:
    mv x29, x20
    
    slli x29, x29, 28
    srli x29, x29, 28
 
    slli x28, x29, 30
    srli x28, x28, 31

    xor x27, x29, x28
    
    srli x29, x29, 1
    
    slli x27, x27, 31
    srli x27, x27, 28
    
    add x30, x27, x29
    
    mv x20, x30
    
    jr ra   

zerostate:
    
    addi s0, s0, 16
    
    li a0, 1 
    sw a0, 0(s0)
    
    j prompt

# --- HELPER FUNCTIONS ---
# Feel free to use (or modify) them however you see fit
     
# Takes in the number of milliseconds to wait (in a0) before returning
delay:
    mv t0, a0
    li a7, 30
    ecall
    mv t1, a0
delayLoop:
    ecall
    sub t2, a0, t1
    bgez t2, delayIfEnd
    addi t2, t2, -1
delayIfEnd:
    bltu t2, t0, delayLoop
    jr ra

# Takes in an RGB color in a0, an x-coordinate in a1, and a y-coordinate
# in a2. Then it sets the led at (x, y) to the given color.
setLED:
    li t1, LED_MATRIX_0_WIDTH
    mul t0, a2, t1
    add t0, t0, a1
    li t1, 4
    mul t0, t0, t1
    li t1, LED_MATRIX_0_BASE
    add t0, t1, t0
    sw a0, (0)t0
    jr ra
    
# Polls the d-pad input until a button is pressed, then returns a number
# representing the button that was pressed in a0.
# The possible return values are:
# 0: UP
# 1: DOWN
# 2: LEFT
# 3: RIGHT
pollDpad:
    mv a0, zero
    li t1, 4
pollLoop:
    bge a0, t1, pollLoopEnd
    li t2, D_PAD_0_BASE
    slli t3, a0, 2
    add t2, t2, t3
    lw t3, (0)t2
    bnez t3, pollRelease
    addi a0, a0, 1
    j pollLoop
pollLoopEnd:
    j pollDpad
pollRelease:
    lw t3, (0)t2
    bnez t3, pollRelease
pollExit:
    jr ra