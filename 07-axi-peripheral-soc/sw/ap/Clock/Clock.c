/*
 * Clock.c
 *
 *  Created on: 2026. 4. 28.
 *      Author: kccistc
 */
#include "Clock.h"

int clockdoton;
hBtn_t hBtnHour, hBtnSec;

static clock_t clockData;

void Clock_Init() {
	FND_Init();
}

void Clock_Run() {

	if (clockData.hour == 23) {
		clockData.hour = 0;
	} else if (clockData.min == 60) {
		clockData.min = 0;
		clockData.hour = clockData.hour + 1;
	} else if (clockData.sec == 60) {
		clockData.sec = 0;
		clockData.min = clockData.min + 1;
	}

	if (millis() - clockData.msec < 1001 - 1) {

		return;

	}

	clockData.msec = millis();
	clockData.sec = clockData.sec + 1;
	Watch_UartPrint();
}

void Clock_Excute() {
	if ((millis() / 500) % 2 == 0) {
		FND_DotPoint(1);
	} else {
		FND_DotPoint(0);
	}
	FND_DispDigit();
	FND_SetNum(clockData.min * 100 + clockData.sec);

}

void Watch_UartPrint() {
	printf("%02d : %02d : %02d : %02d\n", clockData.hour, clockData.min,
			clockData. sec,clockData.msec);
}
