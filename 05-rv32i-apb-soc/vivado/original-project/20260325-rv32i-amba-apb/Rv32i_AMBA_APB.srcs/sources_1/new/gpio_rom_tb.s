// GPIO ROM program for tb_rv32i
// Scenario:
// 1. Set GPIO_CTL = 0xFF00  (GPIO[15:8] output, GPIO[7:0] input)
// 2. Write 0x0100, 0x0200, 0x0400, 0x0800 to GPIO_ODATA
// 3. Repeat forever

        lui   x5,  0x20002        // x5 = 0x2000_2000 (GPIO base)
        lui   x6,  0x00010
        addi  x6,  x6, -256       // x6 = 0x0000_FF00
        sw    x6,  0(x5)          // GPIO_CTL   = 0xFF00
        sw    x0,  4(x5)          // GPIO_ODATA = 0x0000

loop:
        addi  x7,  x0, 1
        slli  x7,  x7, 8
        sw    x7,  4(x5)
        jal   x1,  delay

        addi  x7,  x0, 2
        slli  x7,  x7, 8
        sw    x7,  4(x5)
        jal   x1,  delay

        addi  x7,  x0, 4
        slli  x7,  x7, 8
        sw    x7,  4(x5)
        jal   x1,  delay

        addi  x7,  x0, 8
        slli  x7,  x7, 8
        sw    x7,  4(x5)
        jal   x1,  delay

        jal   x0,  loop

delay:
        addi  x8,  x0, 32
dly1:
        addi  x8,  x8, -1
        bne   x8,  x0, dly1
        jalr  x0,  0(x1)
