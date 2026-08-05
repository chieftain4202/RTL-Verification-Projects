/*
 * ap_main.c
 *
 *  Created on: 2026. 4. 28.
 *      Author: kccistc
 */
#include "xparameters.h"
#include "xintc.h"
#include "xil_exception.h"
#include "xil_printf.h"

#include "ap_main.h"
#include "interrupt.h"
#include "../Driver/FND/fnd.h"
#include "../common/common.h"
#include "UpCounter/UpCounter.h"
#include "Clock/Clock.h"
#include "TimeClock/TimeClock.h"
#include "../HAL/TMR/TMR.h"
#include "../Driver/LED/led.h"

hBtn_t hBtnMode;

void ap_init() {
	UpCounter_Init();
	SetupInterruptSystem();

	TMR_SetPSC(TMR0, 100 - 1);
	TMR_SetARR(TMR0, 0xffffffff);
	TMR_StopIntr(TMR0);
	TMR_StartTimer(TMR0);

	// 1khz -> 1ms
	TMR_SetPSC(TMR1, 100 - 1);
	TMR_SetARR(TMR1, 1000 - 1);
	TMR_StartIntr(TMR1);
	TMR_StartTimer(TMR1);

	// 100khz -> 10ms
	TMR_SetPSC(TMR2, 100 - 1);
	TMR_SetARR(TMR2, 10000 - 1);
	TMR_StartIntr(TMR2);
	TMR_StartTimer(TMR2);

	Clock_Init();
	TimeClock_Init();
	led_init();
	Button_Init(&hBtnMode, GPIOA, GPIO_PIN_5);
}

void ap_excute() {
	static mode_state_t ModeState = counter;

	while (1) {
		//Clock_Run();      // �빆�긽 �떎�뻾
		// �빆�긽 �떎�뻾
		//delay_ms(1);      // �빆�긽 �떎�뻾
		TimeClock_Run();

		if (Button_GetState(&hBtnMode) == ACT_PUSHED) {
			if (ModeState == counter) {
				ModeState = clock;
			} else {
				ModeState = counter;
			}
		}

		switch (ModeState) {
		case counter:
			FND_SetDp(FND_DIGIT_100, OFF);
			UpCounter_Excute();
			led_upcounter();

			break;

		case clock:
			TimeClock_Excute();
			led_clock();
			led_Clock_Shift();
			break;
		}

	}
}

