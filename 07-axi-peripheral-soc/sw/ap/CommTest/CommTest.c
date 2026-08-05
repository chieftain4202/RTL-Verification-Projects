#include "CommTest.h"

#include "sleep.h"
#include "xil_io.h"
#include "xil_printf.h"
#include "../../Driver/I2CMaster/I2CMaster.h"

#define COMMTEST_POLL_DELAY_US 100000U
#define GPIO8_REG_CR_OFFSET 0U
#define GPIO8_REG_IDR_OFFSET 4U
#define I2C_MASTER_BASEADDR 0x44A00000U
#define GPIO8_0_BASEADDR 0x44A10000U
#define GPIO8_1_BASEADDR 0x44A20000U

typedef struct {
	u8 initialized;
	u8 firstSample;
	u8 prevSw;
	u8 prevSw1;
	u16 prevWord;
	u32 prevStatus;
} commTestCtx_t;

static I2CMaster_t hI2c;
static commTestCtx_t commTestCtx;

static u8 CommTest_ReadGpioInput(u32 baseAddress) {
	return (u8) Xil_In32(baseAddress + GPIO8_REG_IDR_OFFSET);
}

static void CommTest_ConfigureGpioAsInput(u32 baseAddress) {
	Xil_Out32(baseAddress + GPIO8_REG_CR_OFFSET, 0x00U);
}

static void CommTest_PrintI2cStatus(const char *tag, u32 status) {
	u32 state = status & I2C_MASTER_STATUS_STATE_MASK;
	u32 busy = (status & I2C_MASTER_STATUS_BUSY_MASK) ? 1U : 0U;
	u32 done = (status & I2C_MASTER_STATUS_DONE_MASK) ? 1U : 0U;
	u32 ack = (status & I2C_MASTER_STATUS_ACK_MASK) ? 1U : 0U;
	u32 startLevel = (status & I2C_MASTER_STATUS_START_DB_MASK) ? 1U : 0U;
	u32 startSeen = (status & I2C_MASTER_STATUS_START_SEEN_MASK) ? 1U : 0U;
	u32 swTx = (status >> I2C_MASTER_STATUS_SW_TX_SHIFT) & I2C_MASTER_STATUS_TX_MASK;
	u32 mTx = (status >> I2C_MASTER_STATUS_M_TX_SHIFT) & I2C_MASTER_STATUS_TX_MASK;

	xil_printf(
			"[CommTest] I2C %s status=0x%x state=%u busy=%u done=%u ack=%u start=%u start_seen=%u sw_tx=0x%x m_tx=0x%x\r\n",
			tag, (unsigned) status, (unsigned) state, (unsigned) busy,
			(unsigned) done, (unsigned) ack, (unsigned) startLevel,
			(unsigned) startSeen, (unsigned) swTx, (unsigned) mTx);
}

static void CommTest_PrintSample(u8 swValue, u8 sw1Value, u16 swWord, u32 status) {
	xil_printf("[CommTest] sw=0x%x sw_1=0x%x sw_word=0x%x\r\n",
			(unsigned) swValue, (unsigned) sw1Value, (unsigned) swWord);
	CommTest_PrintI2cStatus("sample", status);
}

void CommTest_Init() {
	I2CMaster_Init(&hI2c, I2C_MASTER_BASEADDR);

	CommTest_ConfigureGpioAsInput(GPIO8_0_BASEADDR);
	CommTest_ConfigureGpioAsInput(GPIO8_1_BASEADDR);

	commTestCtx.initialized = 1U;
	commTestCtx.firstSample = 1U;
	commTestCtx.prevSw = 0U;
	commTestCtx.prevSw1 = 0U;
	commTestCtx.prevWord = 0U;
	commTestCtx.prevStatus = 0U;

	xil_printf("\r\n[CommTest] init\r\n");
	xil_printf("[CommTest] I2C base    : 0x%x\r\n", (unsigned) hI2c.baseAddress);
	xil_printf("[CommTest] GPIO8_0 base: 0x%x\r\n",
			(unsigned) GPIO8_0_BASEADDR);
	xil_printf("[CommTest] GPIO8_1 base: 0x%x\r\n",
			(unsigned) GPIO8_1_BASEADDR);
	xil_printf("[CommTest] sw[7:0]  -> I2C tx data\r\n");
	xil_printf("[CommTest] sw_1[7]  -> I2C start level\r\n");
}

void CommTest_Execute() {
	u8 swValue;
	u8 sw1Value;
	u16 swWord;
	u32 status;

	if (!commTestCtx.initialized) {
		return;
	}

	usleep(COMMTEST_POLL_DELAY_US);

	swValue = CommTest_ReadGpioInput(GPIO8_0_BASEADDR);
	sw1Value = CommTest_ReadGpioInput(GPIO8_1_BASEADDR);
	swWord = ((u16) sw1Value << 8) | (u16) swValue;

	I2CMaster_WriteSwWord(&hI2c, swWord);
	status = I2CMaster_ReadStatus(&hI2c);

	if (commTestCtx.firstSample || swValue != commTestCtx.prevSw
			|| sw1Value != commTestCtx.prevSw1 || swWord != commTestCtx.prevWord
			|| status != commTestCtx.prevStatus) {
		CommTest_PrintSample(swValue, sw1Value, swWord, status);
		commTestCtx.prevSw = swValue;
		commTestCtx.prevSw1 = sw1Value;
		commTestCtx.prevWord = swWord;
		commTestCtx.prevStatus = status;
		commTestCtx.firstSample = 0U;
	}
}
