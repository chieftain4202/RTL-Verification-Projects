
#include "TMR.h"

uint32_t TMR_GetCNT(TMR_Typedef_t *TMRx){
	if (TMRx == 0) {
		return 0U;
	}
	return TMRx->CNT;
}

void TMR_SetPSC(TMR_Typedef_t *TMRx, uint32_t psc) {
	if (TMRx == 0) {
		return;
	}
	TMRx->PSC = psc;
}

void TMR_SetARR(TMR_Typedef_t *TMRx, uint32_t arr) {
	if (TMRx == 0) {
		return;
	}
	TMRx->ARR = arr;
}

void TMR_StartIntr(TMR_Typedef_t *TMRx) {
	if (TMRx == 0) {
		return;
	}
	TMRx->CR |= 1 << TMR_INTR_BIT;
}

void TMR_StopIntr(TMR_Typedef_t *TMRx) {
	if (TMRx == 0) {
		return;
	}
	TMRx->CR &= ~(1 << TMR_INTR_BIT);
}

void TMR_StartTimer(TMR_Typedef_t *TMRx) {
	if (TMRx == 0) {
		return;
	}
	TMRx->CR |= 1 << TMR_ENABLE_BIT;
}

void TMR_StopTimer(TMR_Typedef_t *TMRx) {
	if (TMRx == 0) {
		return;
	}
	TMRx->CR &= ~(1 << TMR_ENABLE_BIT);
}

void TMR_ClearTimer(TMR_Typedef_t *TMRx) {
	if (TMRx == 0) {
		return;
	}
	TMRx->CR |= 1 << TMR_CLEAR_BIT;
	TMRx->CR &= ~(1 << TMR_CLEAR_BIT);
}

