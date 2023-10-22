.data
Tag:
    .word 0x7f7f7f7f
    .word 0x55555555
    .word 0x33333333
    .word 0x0f0f0f0f
    .word 0xffff


.text
.globl mzbyte
mzbyte:
    # Prologue a0=Lower part, a1=Higher part           
zbytel:
    #y = (x & 0x7F7F7F7F7F7F7F7F)+ 0x7F7F7F7F7F7F7F7F
    # li    t0,0x7f7f7f7f
    la a7, Tag
    lw t0, 0(a7)
    # lw t0, 0(s0)
    and   a0,a0,t0          
    add   a0,a0,t0
    
    #y = ~(y | x |0x7F7F7F7F7F7F7F7F)
    or    a0,a0,t0
    xori  a0,a0,-1          #a0:Lower part -> prev: s2
    
    and  a1,a1,t0
    add  a1,a1,t0
    or    a1,a1,t0
    xori  a1,a1,-1          #a1:Higher part -> prev: s3

    # mv s2, a0
    # mv s3, a1
    # li s0, 0
clz:
    #x |= (x >> 1)
    andi  t1,a1,0x1
    srli  a4,a1,1
    srli  a5,a0,1
    slli  t1,t1,31
    or    a5,a5,t1
    or    a1,a4,a1
    or    a0,a5,a0
    
    #x |= (x >> 2)
    andi  t1,a1,0x3
    srli  a4,a1,2
    srli  a5,a0,2
    slli  t1,t1,30
    or    a5,a5,t1
    or    a1,a4,a1
    or    a0,a5,a0
    
    #x |= (x >> 4)
    andi  t1,a1,0xf
    srli  a4,a1,4
    srli  a5,a0,4
    slli  t1,t1,28
    or    a5,a5,t1
    or    a1,a4,a1
    or    a0,a5,a0
    
    #x |= (x >> 8)
    andi  t1,a1,0xff
    srli  a4,a1,8
    srli  a5,a0,8
    slli  t1,t1,24
    or    a5,a5,t1
    or    a1,a4,a1
    or    a0,a5,a0
   
    #x |= (x >> 16)
    lw t1, 16(a7)
    # li    t1,0xffff
    and   t1,a1,t1
    srli  a4,a1,16
    srli  a5,a0,16
    slli  t1,t1,16
    or    a5,a5,t1
    or    a1,a4,a1
    or    a0,a5,a0
    
    #x |= (x >> 32)
    mv    a5,a1
    and   a4,a1,x0
    or    a1,a4,a1
    or    a0,a5,a0
    
    # x -= ((x >> 1) & 0x5555555555555555)
    andi  t1,a1,0x1
    srli  a4,a1,1
    srli  a5,a0,1
    slli  t1,t1,31
    or    a5,a5,t1
    lw t1, 4(a7)
    # li    t1,0x55555555
    and   a4,a4,t1
    and   a5,a5,t1
    sub   a1,a1,a4
    sub   a0,a0,a5
    
    #x = ((x >> 2) & 0x3333333333333333) + (x & 0x3333333333333333)
    andi  t1,a1,0x3
    srli  a4,a1,2
    srli  a5,a0,2
    slli  t1,t1,30
    or    a5,a5,t1
    lw t1, 8(a7)
    # li    t1,0x33333333
    and   a4,a4,t1        
    and   a5,a5,t1        
    and   a1,a1,t1
    and   a0,a0,t1
    add   a1,a1,a4
    add   a0,a0,a5
    
    #x = ((x >> 4) + x) & 0x0f0f0f0f0f0f0f0f;
    andi  t1,a1,0xf
    srli  a4,a1,4
    srli  a5,a0,4
    slli  t1,t1,28
    or    a5,a5,t1
    add   a4,a4,a1
    add   a5,a5,a0
    lw t1, 12(a7)
    # li    t1,0x0f0f0f0f
    and   a1,a4,t1
    and   a0,a5,t1
    
    #x += (x >> 8)
    andi  t1,a1,0xff
    srli  a4,a1,8
    srli  a5,a0,8
    slli  t1,t1,24
    or    a5,a5,t1
    add   a1,a1,a4
    add   a0,a0,a5
    
    #x += (x >> 16)
    lw t1, 16(a7)
    # li    t1,0xffff
    and   t1,t1,a1
    srli  a4,a1,16
    srli  a5,a0,16
    slli  t1,t1,16
    or    a5,a5,t1
    add   a1,a1,a4
    add   a0,a0,a5
    
    #x += (x >> 32)
    mv    a5,a1
    and   a4,a1,x0
    add   a1,a1,a4
    add   a0,a0,a5
    
    #64 - (x & 0x7f)
    andi  a0,a0,0x7f
    li    t1,64
    sub   a0,t1,a0
# end of clz
    srli  a0,a0,3           #clz(y)>>3
    
    ret