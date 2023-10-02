.data
argument: .word   0x12345678
str1:     .string "Expect: "
str2:     .string "\nOutput: "
rads:     .word 0x3f490fdb # (float) 0.785398185
          .word 0xc36a0000
          .word 0x3
sine:    .word 0x3f3504f4 # (float) 4.5
.text

_start:
    j main

getbit:
    # prologue
    srl a0, a0, a1
    andi a0, a0, 0x1
    ret


count_leading_zeros:
    # prologue
    addi sp, sp, -12
    sw s0, 0(sp)
    sw s1, 4(sp)
    sw s2, 8(sp)

    # a0 = x
    srli s0, a0, 1
    or a0, a0, s0
    srli s0, a0, 2
    or a0, a0, s0
    srli s0, a0, 4
    or a0, a0, s0
    srli s0, a0, 8
    or a0, a0, s0
    srli s0, a0, 16
    or a0, a0, s0

    srli s0, a0, 1
    li s2, 0x55555555
    and s0, s0, s2
    sub a0, a0, s0
    srli s0, a0, 2
    li s2, 0x33333333
    and s0, s2, s0
    and s1, a0, s2
    add a0, s0, s1
    srli s0, a0, 4
    add s0, s0, a0
    li s2, 0x0f0f0f0f
    and a0, s0, s2
    srli s0, a0, 8
    add a0, a0, s0
    srli s0, a0, 16
    add a0, a0, s0

    li s2, 32
    andi a0, a0, 0x7f
    sub a0, s2, a0

    # epilogue
    lw s0, 0(sp)
    lw s1, 4(sp)
    lw s2, 8(sp)
    addi sp, sp, 12
    ret


fadd32:
    # prologue
    addi sp, sp, -4
    sw ra, 0(sp)
    
    li t2, 0x7fffffff
    and t0, a0, t2 # t0 = cmp_a
    and t1, a1, t2 # t1 = cmp_b
    bge t0, t1, 1f
    mv t2, a0 # swap a0 = ia, a1 = ib
    mv a0, a1
    mv a1, t2
1:  
    srli t0, a0, 23
    srli t1, a1, 23
    andi t0, t0, 0xff # t0 = ea
    andi t1, t1, 0xff # t1 = eb

    li t2, 0x7fffff
    and t3, a0, t2
    and t4, a1, t2
    addi t2, t2, 1
    or t3, t3, t2 # t3 = ma
    or t4, t4, t2 # t4 = mb
    
    sub t2, t0, t1 # t2 = align
    li t5, 24
    bge t5, t2, 2f
    li t2, 24
2:
    srl t4, t4, t2 # mb >>= align
    xor t2, a0, a1
    srli t2, t2, 31
    beqz t2, 3f
    neg t4, t4
3:
    add t3, t3, t4 # t3 = result of ma
    # t1(eb) and t4(mb) are free to use
    mv t4, a0 # t4 = ia
    mv a0, t3
    jal count_leading_zeros # a0 = clz
    li t2, 8
    blt t2, a0, 4f
    sub t5, t2, a0
    srl t3, t3, t5
    add t0, t0, t5
    j 5f
4: 
    sub t5, a0, t2 # t5 = shift
    sll t3, t3, t5
    sub t0, t0, t5
5:
    li t2, 0x80000000
    and a0, t2, t4
    slli t0, t0, 23
    or a0, a0, t0
    li t2, 0x7fffff
    and t3, t3, t2
    or a0, a0, t3
    
    # epilogue
    lw ra, 0(sp)
    addi sp, sp, 4
    ret


fmul32:
    # prologue
    addi sp, sp, -4
    sw ra, 0(sp)
    
    seqz t0, a0
    seqz t1, a0
    or t0, t0, t1
    beqz t0, 2f
    li a0, 0
    j 3f

2:  li t2, 0x7FFFFF
    and t0, a0, t2
    and t1, a1, t2
    addi t2, t2, 1
    or t0, t0, t2 # t0 = ma
    or t1, t1, t2 # t1 = mb
imul24:
    li t3, 0 # t3 = m, r(in imul24)
1:  
    andi t4, t1, 0x1
    neg t4, t4
    and t4, t0, t4
    srli t3, t3, 1
    add t3, t3, t4
    srli t1, t1, 1
    
    andi t4, t1, 0x1 # unroll 2
    neg t4, t4
    and t4, t0, t4
    srli t3, t3, 1
    add t3, t3, t4
    srli t1, t1, 1
    andi t4, t1, 0x1 # unroll 3
    neg t4, t4
    and t4, t0, t4
    srli t3, t3, 1
    add t3, t3, t4
    srli t1, t1, 1
    andi t4, t1, 0x1 # unroll 4
    neg t4, t4
    and t4, t0, t4
    srli t3, t3, 1
    add t3, t3, t4
    srli t1, t1, 1
    bnez t1, 1b

    mv t0, a0 # t0 = a
    mv t1, a1 # t1 = b
    mv a0, t3
    li a1, 24
    jal getbit # a0 = mshift

# m(t3) value computed
    srl t3, t3, a0

    li t2, 0xFF800000
    and t0, t0, t2 # t0 = sea
    and t1, t1, t2 # t1 = seb

    li t2, 0x3f800000
    sub t4, t0, t2
    add t4, t4, t1
    li t2, 0xFF800000
    and t4, t4, t2 # t4 = ((sea - 0x3f800000 + seb) & 0xFF800000)
    
    li t2, 0x7fffff
    slli a0, a0, 23
    or a0, a0, t2
    and a0, a0, t3
    add a0, a0, t4 # a0 = r(in fmul32)

    # check overflow
    xor t3, t0, t1
    xor t3, t3, a0
    srli t3, t3, 31 # t3 = ovfl

    li t2, 0x7f800000
    xor t4, t2, a0
    and t4, t4, t3
    xor a0, a0, t4

3:  # epilogue
    lw ra, 0(sp)
    addi sp, sp, 4
    ret


fdiv32:
    # prologue
    addi sp, sp, -4
    sw ra, 0(sp)

    beqz a0, 3f
    bnez a1, 1f
    li a0, 0x7f800000
    j 3f
1:
    li t2, 0x7FFFFF
    and t0, t2, a0
    and t1, t2, a1
    addi t2, t2, 1
    or t0, t0, t2 # t0 = ma
    or t1, t1, t2 # t1 = mb
idiv24:
    li t3, 0 # t3 = m, r(in idiv24)
    li t4, 32 # t4 = end condition
2:
    sub t0, t0, t1
    sltz t2, t0
    seqz t2, t2
    slli t3, t3, 1
    or t3, t3, t2
    seqz t2, t2
    neg t2, t2
    and t5, t2, t1 # t5 = b & -(a < 0)
    add t0, t0, t5
    slli t0, t0, 1

    sub t0, t0, t1
    sltz t2, t0
    seqz t2, t2
    slli t3, t3, 1
    or t3, t3, t2
    seqz t2, t2
    neg t2, t2
    and t5, t2, t1 # t5 = b & -(a < 0)
    add t0, t0, t5
    slli t0, t0, 1
    sub t0, t0, t1
    sltz t2, t0
    seqz t2, t2
    slli t3, t3, 1
    or t3, t3, t2
    seqz t2, t2
    neg t2, t2
    and t5, t2, t1 # t5 = b & -(a < 0)
    add t0, t0, t5
    slli t0, t0, 1
    sub t0, t0, t1
    sltz t2, t0
    seqz t2, t2
    slli t3, t3, 1
    or t3, t3, t2
    seqz t2, t2
    neg t2, t2
    and t5, t2, t1 # t5 = b & -(a < 0)
    add t0, t0, t5
    slli t0, t0, 1
    
    addi t4, t4, -4
    bnez t4, 2b 

    li t2, 0xFF800000
    and t0, a0, t2 # t0 = sea
    and t1, a1, t2 # t1 = seb
    mv a0, t3
    li a1, 31
    jal getbit
    seqz a0, a0 # a0 = mshift
    sll t3, t3, a0 # t3 = m

    li t2, 0x3f800000
    sub t4, t0, t1
    add t4, t4, t2 # t4 = sea - seb + 0x3f800000
    neg a0, a0
    li t2, 0x800000
    and a0, a0, t2 # a0 = 0x800000 & -mshift
    srli t3, t3, 8
    addi t2, t2, -1
    and t3, t3, t2 # t3 = m
    sub a0, t4, a0
    or a0, a0, t3

    # check overflow
    xor t3, t1, t0
    xor t3, t3, a0
    srli t3, t3, 31

    li t2, 0x7f800000
    xor t4, t2, a0
    and t4, t4, t3
    xor a0, a0, t4
3:
    # epilogue
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

f2i32:
    li t2, 0x7FFFFF
    and t0, t2, a0
    addi t2, t2, 1
    or t0, t0, t2 # t0 = ma
    srli t1, a0, 23
    andi t1, t1, 0xff
    addi t1, t1, -127 # t1 = ea
    li t2, 23
    bge t2, t1, 1f # if t2 >= t1 then 1f
    bgez t1 2f
    li a0, 0
    ret
    
1: # ea <= 23
    neg t1, t1
    addi t1, t1, 23
    srl a0, t0, t1
    ret

2: # ea >= 0
    addi t1, t1, -23
    sll a0, t0, t1
    ret


i2f32:
    # prologue
    addi sp, sp, -4
    sw ra, 0(sp)

    beqz a0, 4f

    li t0, 0x80000000
    and t0, t0, a0 # t0 = s
    beqz t0, 1f
    neg a0, a0
1: 
    mv t1, a0 # t1 = x
    jal count_leading_zeros
    mv t2, a0 # t2 = clz
    li t3, 31
    sub t3, t3, t2
    addi t3, t3, 127 # t3 = e
    slli t3, t3, 23 # e << 23
    or a0, t0, t3 # s | e << 23

    li t4, 8
    blt t2, t4, 2f # if clz < 8, then 2f
    sub t4, t2, t4
    sll t1, t1, t4
    li t4, 0x7fffff
    and t1, t1, t4 # x & 0x7fffff
    or a0, a0, t1
    j 4f
2: 
    sub t4, t4, t2
    srl t1, t1, t4
    li t4, 0x7fffff
    and t1, t1, t4
    or a0, a0, t1
    j 4f

4:
    # epilogue
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

myPow:
    # prologue
    addi sp, sp, -20
    sw ra, 0(sp)
    sw s0, 4(sp)
    sw s1, 8(sp)
    sw s2, 12(sp)
    sw s3, 16(sp)

    mv s0, a1 # s0 = n
    mv s3, a0 # s3 = x
    #mv a1, a0 # a1 = x
    li s1, 0x3f800000 # s1 = float r = 1

1: # while loop
    beqz s0, 4f
2:
    andi s2, s0, 0x1
    beqz s2, 3f
    mv a0, s1
    mv a1, s3
    jal fmul32
    mv s1, a0
    addi s0, s0, -1
    j 1b
3:
    mv a0, s3
    mv a1, s3
    jal fmul32
    mv s3, a0
    srli s0, s0, 1
    j 1b

4:
    # epilogue
    lw ra, 0(sp)
    lw s0, 4(sp)
    lw s1, 8(sp)
    lw s2, 12(sp)
    lw s3, 16(sp)
    addi sp, sp, 20
    ret


factorial:
    # prologue
    addi sp, sp, -16
    sw ra, 0(sp)
    sw s0, 4(sp)
    sw s1, 8(sp)
    sw s2, 12(sp)

    li s0, 1 # s0 = i
    mv s1, a0 # s1 = n
    li s2, 0x3f800000 # s2 = float r = 1

1: # for loop
    mv a0, s0
    jal i2f32
    mv a1, s2
    jal fmul32
    mv s2, a0
    addi s0, s0, 1
    bge s1, s0, 1b # if s1 >= s0 then target

    mv a0, s2

    # epilogue
    lw ra, 0(sp)
    lw s0, 4(sp)
    lw s1, 8(sp)
    lw s2, 12(sp)
    addi sp, sp, 16
    ret


mySin:
    # prologue 
    addi sp, sp, -4
    sw ra, 0(sp)
    
    mv s11, a0 # s11 = x (input radius (float))
    li s0, 0 # s0 = float r = 1
    li s1, 0 # int n
    li s2, 5 # for loop break condition
1: # for loop
    mv a0, s1 # counting k
    jal i2f32
    li a1 0x40000000 # i2f32(2)
    jal fmul32
    li a1, 0x3f800000 # i2f32(1)
    jal fadd32
    jal f2i32
    mv s3, a0 # s3 = int k
    andi a0, s1, 1 # counting s
    neg a0, a0 # t0 2's complement
    andi a0, a0, -2
    xori a0, a0, 1 # int s
    jal i2f32
    mv s4, a0 # s4 = float s
    mv a0, s11 # counting r
    mv a1, s3
    jal myPow
    mv a1, s4
    jal fmul32
    mv s5, a0 # s5 = temp value of fmul32(myPow())
    mv a0, s3
    jal factorial
    mv a1, a0
    mv a0, s5
    jal fdiv32
    mv a1, s0
    jal fadd32
    mv s0, a0 # r 

    addi s1, s1, 1
    bne s1, s2, 1b

    mv a0, s0
    # epilogue
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

main:
    la t0, rads
    lw a0, 0(t0)
    #lw a1, 8(t0)
    #jal myPow
    jal mySin
    j printAns


printAns:
    mv t0, a0
    la a0, str1
    li a7, 4
    ecall
    la a0 sine
    lw a0 0(a0)
    li a7 2
    ecall
    la a0, str2
    li a7, 4
    ecall
    mv a0, t0
    li a7, 2
    ecall
    
end:
    nop