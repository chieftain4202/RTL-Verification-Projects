#ifndef SRC_DRIVER_SPIMASTER_SPIMASTER_H_
#define SRC_DRIVER_SPIMASTER_SPIMASTER_H_

#include "xil_types.h"

#define SPI_MASTER_REG0_OFFSET 0U
#define SPI_MASTER_REG1_OFFSET 4U
#define SPI_MASTER_REG2_OFFSET 8U
#define SPI_MASTER_REG3_OFFSET 12U

typedef struct {
	u32 baseAddress;
} SPIMaster_t;

void SPIMaster_Init(SPIMaster_t *hspi, u32 baseAddress);
void SPIMaster_WriteTxData(SPIMaster_t *hspi, u8 txData);
void SPIMaster_Start(SPIMaster_t *hspi);
void SPIMaster_SendByte(SPIMaster_t *hspi, u8 txData);
u32 SPIMaster_ReadReg(const SPIMaster_t *hspi, u32 regOffset);

#endif /* SRC_DRIVER_SPIMASTER_SPIMASTER_H_ */
