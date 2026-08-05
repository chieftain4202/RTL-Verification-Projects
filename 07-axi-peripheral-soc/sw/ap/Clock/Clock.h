
#ifndef SRC_AP_CLOCK_CLOCK_H_
#define SRC_AP_CLOCK_CLOCK_H_

#include "../../Driver/FND/fnd.h"
#include "../../Driver/Button/button.h"
#include "../../common/common.h"

typedef struct {
	uint8_t hour;
	uint8_t min;
	uint8_t sec;
	uint32_t msec;
} clock_t;

void Clock_Init();
void Clock_Run();
void Clock_Excute();

#endif /* SRC_AP_CLOCK_CLOCK_H_ */
