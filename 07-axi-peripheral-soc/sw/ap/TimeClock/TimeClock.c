#include "TimeClock.h"

timeClock_t timeClock;
hBtn_t hBtnHourSec;
int hhssled = 1;

void TimeClock_Init() {
	TimeClock_SetTime(12, 00, 00, 00);
	FND_Init();
	Button_Init(&hBtnHourSec, GPIOA, GPIO_PIN_6);
}

void TimeClock_SetTime(uint8_t hh, uint8_t mm, uint8_t ss, uint8_t ms) {
	timeClock.hour = hh;
	timeClock.min = mm;
	timeClock.sec = ss;
	timeClock.msec = ms;
}

void TimeClock_Excute() {

	TimeClock_DispTime();
	//Clock_UartPrint();
}

void TimeClock_Run() {
	static uint32_t prevTimeClock = 0;
	hhss_led();
	if (millis() - prevTimeClock >= 10) {
		prevTimeClock = millis();
		TimeClock_IncTime();
	}
}

void TimeClock_IncTime() {

	if (timeClock.msec < 100 - 1) {
		timeClock.msec++;
		return;
	}
	timeClock.msec = 0;

	if (timeClock.sec < 60 - 1) {
		timeClock.sec++;
		return;
	}
	timeClock.sec = 0;

	if (timeClock.min < 60 - 1) {
		timeClock.min++;
		return;
	}
	timeClock.min = 0;

	if (timeClock.hour < 24 - 1) {
		timeClock.hour++;
		return;
	}
	timeClock.hour = 0;

}

void hhss_led() {
	if (hhssled) {
		led_hh();
	} else {
		led_ss();
}
}
void TimeClock_DispTime() {
	static modedisp_state_t dismodstate = mod_sec;
	if (Button_GetState(&hBtnHourSec) == ACT_PUSHED) {
		if (dismodstate == mod_hour) {
			dismodstate = mod_sec;
		} else {
			dismodstate = mod_hour;
		}
	}
	switch (dismodstate) {
	case mod_hour:
		TimeClock_DispHourMin();
		hhssled = 1;
		break;
	case mod_sec:
		TimeClock_DispSecMsec();
		hhssled = 0;
		break;
	}

	if (timeClock.msec < 50) {
		FND_SetDp(FND_DIGIT_100, ON);
	} else {
		FND_SetDp(FND_DIGIT_100, OFF);
	}
}

void TimeClock_DispHourMin() {

	uint16_t timeNumH;

	timeNumH = timeClock.hour * 100 + timeClock.min;

	FND_SetNum(timeNumH);
}

void TimeClock_DispSecMsec() {

	uint16_t timeNumL;

	timeNumL = timeClock.sec * 100 + timeClock.msec;

	FND_SetNum(timeNumL);

}

void Clock_UartPrint() {
	if (timeClock.msec == 50) {
		printf("%02d : %02d : %02d : %02d\n", timeClock.hour, timeClock.min,
				timeClock.sec, timeClock.msec);
	}
}

