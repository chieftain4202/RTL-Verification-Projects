/*
 * TimeClock.h
 *
 *  Created on: 2026. 4. 30.
 *      Author: kccistc
 */

#ifndef SRC_AP_TIMECLOCK_TIMECLOCK_H_
#define SRC_AP_TIMECLOCK_TIMECLOCK_H_

#include "../../HAL/GPIO/GPIO.h"
#include <stdint.h>
#include "../../Driver/FND/fnd.h"
#include "../../common/common.h"
#include "../../Driver/Button/button.h"
#include "../../Driver/LED/led.h"

typedef struct {
	uint8_t hour;
	uint8_t min;
	uint8_t sec;
	uint8_t msec;

} timeClock_t;

typedef enum {
	mod_hour, mod_sec,
} modedisp_state_t;

void TimeClock_Init();
void TimeClock_SetTime(uint8_t hh, uint8_t mm, uint8_t ss, uint8_t ms);
void TimeClock_Excute();
void TimeClock_IncTime();
void TimeClock_DispTime();
void TimeClock_DispHourMin();
void TimeClock_DispSecMsec();
void TimeClock_Run();
void Clock_UartPrint();
void hhss_led();





#endif /* SRC_AP_TIMECLOCK_TIMECLOCK_H_ */
