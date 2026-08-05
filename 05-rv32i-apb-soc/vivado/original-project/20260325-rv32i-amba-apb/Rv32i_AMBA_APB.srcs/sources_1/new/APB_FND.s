// FND ROM program
// Display 0 -> 1 -> 1234 repeatedly on APB FND peripheral.
// FND base address: 0x2000_3000
// FND_ODATA offset: 0x000

        lui   x5, 0x20003        // x5 = 0x2000_3000

loop:
        sw    x0, 0(x5)          // FND_ODATA = 0
        jal   x1, delay

        addi  x6, x0, 1
        sw    x6, 0(x5)          // FND_ODATA = 1
        jal   x1, delay

        addi  x6, x0, 1234
        sw    x6, 0(x5)          // FND_ODATA = 1234
        jal   x1, delay

        jal   x0, loop

delay:
        addi  x7, x0, 32
dly1:
        addi  x7, x7, -1
        bne   x7, x0, dly1
        jalr  x0, 0(x1)
