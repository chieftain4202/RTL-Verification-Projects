#include "SPIMaster.h"

#include "xil_io.h"

void SPIMaster_Init(SPIMaster_t *hspi, u32 baseAddress) {
	hspi->baseAddress = baseAddress;
}

void SPIMaster_WriteTxData(SPIMaster_t *hspi, u8 txData) {
	Xil_Out32(hspi->baseAddress + SPI_MASTER_REG0_OFFSET, (u32) txData);
}

void SPIMaster_Start(SPIMaster_t *hspi) {
	Xil_Out32(hspi->baseAddress + SPI_MASTER_REG1_OFFSET, 1U);
}

void SPIMaster_SendByte(SPIMaster_t *hspi, u8 txData) {
	SPIMaster_WriteTxData(hspi, txData);
	SPIMaster_Start(hspi);
}

u32 SPIMaster_ReadReg(const SPIMaster_t *hspi, u32 regOffset) {
	return Xil_In32(hspi->baseAddress + regOffset);
}
