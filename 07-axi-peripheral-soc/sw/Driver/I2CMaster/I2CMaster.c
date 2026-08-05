#include "I2CMaster.h"

#include "xil_io.h"

void I2CMaster_Init(I2CMaster_t *hi2c, u32 baseAddress) {
	hi2c->baseAddress = baseAddress;
}

void I2CMaster_WriteSwWord(I2CMaster_t *hi2c, u16 swWord) {
	Xil_Out32(hi2c->baseAddress + I2C_MASTER_REG0_OFFSET, (u32) swWord);
}

u32 I2CMaster_ReadStatus(const I2CMaster_t *hi2c) {
	return Xil_In32(hi2c->baseAddress + I2C_MASTER_STATUS_OFFSET);
}

u32 I2CMaster_ReadReg(const I2CMaster_t *hi2c, u32 regOffset) {
	return Xil_In32(hi2c->baseAddress + regOffset);
}
