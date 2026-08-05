#include "fnd.h"



uint8_t fndDpData = 0;
uint16_t fndNumData = 0;
int dotpoint;

void FND_SetComPort(GPIO_Typedef_t *FND_Port, uint32_t Seg_Pin, int OnOff) {

	GPIO_WritePin(FND_Port, Seg_Pin, OnOff);
}



void FND_SetDp(uint8_t digit, uint8_t on_off) {
	if (digit == FND_DIGIT_1) {
		if (!on_off) fndDpData |= 1 << 0;
		else fndDpData &= ~(1 << 0);
	} else if (digit == FND_DIGIT_10) {
		if (!on_off) fndDpData |= 1 << 1;
		else	fndDpData &= ~(1 << 1);
	} else if (digit == FND_DIGIT_100) {
		if (!on_off) fndDpData |= 1 << 2;
		else fndDpData &= ~(1 << 2);
	} else if (digit == FND_DIGIT_1000) {
		if (!on_off) fndDpData |= 1 << 3;
		else fndDpData &= ~(1 << 3);
	}
}


void FND_DispDP(uint8_t digit)
{
    if (fndDpData & digit) {
        GPIO_WritePin(FND_FONT_PORT, SEG_PIN_DP, RESET);
    }
    else {
        GPIO_WritePin(FND_FONT_PORT, SEG_PIN_DP, SET);
    }
}



void FND_DispDigit() {

	static uint8_t fndDigState = 0;
	fndDigState = (fndDigState + 1) % 4;

	switch (fndDigState) {
	case 0:
		FND_DispDigit_1();
		FND_DispDP(FND_DIGIT_1);
		break;
	case 1:
		FND_DispDigit_10();
		FND_DispDP(FND_DIGIT_10);
		break;
	case 2:
		FND_DispDigit_100();
		FND_DispDP(FND_DIGIT_100);
		break;
	case 3:
		FND_DispDigit_1000();
		FND_DispDP(FND_DIGIT_1000);
		break;
	default:
		FND_DispDigit_1();
		break;

	}
}


void FND_Init() {
	// GPIO 설정, GPIOA0,1,2,3 COM 연결
	GPIO_SetMode(GPIOA,
	FND_COM_DIG_1 | FND_COM_DIG_2 | FND_COM_DIG_3 | FND_COM_DIG_4,
	OUTPUT);
	// GPIO 설정, GPIOB seg
	GPIO_SetMode(GPIOB, SEG_PIN_A | SEG_PIN_B | SEG_PIN_C | SEG_PIN_D,
	OUTPUT);
	GPIO_SetMode(GPIOB, SEG_PIN_E | SEG_PIN_F | SEG_PIN_G | SEG_PIN_DP,
	OUTPUT);
}

void FND_DispDigit_1() {
	uint16_t fndFont[16] = { 0xc0, 0xf9, 0xa4, 0xb0, 0x99, 0x92, 0x82, 0xf8,
			0x80, 0x90, 0x88, 0x83, 0xc6, 0xa1, 0x86, 0x8e };
	//num 자리수 분리
	uint16_t digitData1 = fndNumData % 10;
	FND_DispAllOff();
	GPIO_WritePort(FND_FONT_PORT, fndFont[digitData1]);
	FND_SetComPort(FND_COM_PORT, FND_COM_DIG_1, ON);
}

void FND_DispDigit_10() {
	uint16_t fndFont[16] = { 0xc0, 0xf9, 0xa4, 0xb0, 0x99, 0x92, 0x82, 0xf8,
			0x80, 0x90, 0x88, 0x83, 0xc6, 0xa1, 0x86, 0x8e };
	//num 자리수 분리
	uint16_t digitData10 = fndNumData / 10 % 10;
	FND_DispAllOff();
	GPIO_WritePort(FND_FONT_PORT, fndFont[digitData10]);
	FND_SetComPort(FND_COM_PORT, FND_COM_DIG_2, ON);
}

void FND_DispDigit_100() {
	uint16_t fndFont[16] = { 0xc0, 0xf9, 0xa4, 0xb0, 0x99, 0x92, 0x82, 0xf8,
			0x80, 0x90, 0x88, 0x83, 0xc6, 0xa1, 0x86, 0x8e };
	uint16_t digitData100 = fndNumData / 100 % 10;
	FND_DispAllOff();
	GPIO_WritePort(FND_FONT_PORT, fndFont[digitData100]);
	GPIO_WritePin(FND_FONT_PORT, SEG_PIN_DP, dotpoint ? ON : OFF);
	FND_SetComPort(FND_COM_PORT, FND_COM_DIG_3, ON);
}

void FND_DispDigit_1000() {
	uint16_t fndFont[16] = { 0xc0, 0xf9, 0xa4, 0xb0, 0x99, 0x92, 0x82, 0xf8,
			0x80, 0x90, 0x88, 0x83, 0xc6, 0xa1, 0x86, 0x8e };
	uint16_t digitData1000 = fndNumData / 1000 % 10;
	FND_DispAllOff();
	GPIO_WritePort(FND_FONT_PORT, fndFont[digitData1000]);
	FND_SetComPort(FND_COM_PORT, FND_COM_DIG_4, ON);
}

void FND_SetNum(uint16_t num) {
	fndNumData = num;
}

void FND_DispAllOn()
{
    GPIO_WritePort(FND_FONT_PORT, 0x00);
    FND_SetComPort(FND_COM_PORT, FND_COM_DIG_1 | FND_COM_DIG_2 | FND_COM_DIG_3 | FND_COM_DIG_4, ON);
}

void FND_DispAllOff()
{
    FND_SetComPort(FND_COM_PORT, FND_COM_DIG_1 | FND_COM_DIG_2 | FND_COM_DIG_3 | FND_COM_DIG_4, OFF);
    GPIO_WritePort(FND_FONT_PORT, 0xff);
    //fndDpData = 0x00;
}

void FND_DotPoint(int on) {
	if (on == 1) {
		dotpoint = 1;
	} else if (on == 0) {
		dotpoint = 0;
	}
}









#define FND_DP_ON      1
#define FND_DP_OFF     0


void FND_DispDigit_DP(uint8_t digit, uint8_t on_off) {
	FND_DispAllOff();
	GPIO_WritePort(FND_FONT_PORT, on_off);
	FND_SetComPort(FND_COM_PORT, digit, ON);
}

void FND_DispDigit_1_DP(uint8_t on_off) {
	FND_DispDigit_DP(FND_DIGIT_1, on_off);
}
void FND_DispDigit_10_DP(uint8_t on_off) {
	FND_DispDigit_DP(FND_DIGIT_10, on_off);
}
void FND_DispDigit_100_DP(uint8_t on_off) {
	FND_DispDigit_DP(FND_DIGIT_100, on_off);
}
void FND_DispDigit_1000_DP(uint8_t on_off) {
	FND_DispDigit_DP(FND_DIGIT_1000, on_off);
}

