#ifndef SRC_AP_UPCOUNTER_UPCOUNTER_H_
#define SRC_AP_UPCOUNTER_UPCOUNTER_H_
#include "../../Driver/FND/fnd.h"
#include "../../Driver/Button/button.h"
#include "../../common/common.h"
#include "../../Driver/LED/led.h"

typedef enum {
	STOP, RUN, CLEAR
} upcounter_state_t;

void UpCounter_Init();
void UpCounter_Excute();
void UpCounter_DispLoop();
void UpCounter_Run();
void UpCounter_Clear();
void UpCounter_Stop();


#endif /* SRC_AP_UPCOUNTER_UPCOUNTER_H_ */
