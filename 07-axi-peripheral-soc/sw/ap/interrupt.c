#include "interrupt.h"

#if defined(TMR1_DEV_ID) && defined(TMR2_DEV_ID)

XIntc IntrController;

void TMR1_ISR(void *CallbackRef) {
	(void) CallbackRef;
	millis_inc();
	UpCounter_DispLoop();
}

void TMR2_ISR(void *CallbackRef) {
	(void) CallbackRef;
}

int SetupInterruptSystem() {
	int status;

	status = XIntc_Initialize(&IntrController, INTC_DEV_ID);
	if (status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	status = XIntc_Connect(&IntrController, TMR1_DEV_ID,
			(XInterruptHandler) TMR1_ISR, (void *) 0);
	if (status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	status = XIntc_Connect(&IntrController, TMR2_DEV_ID,
			(XInterruptHandler) TMR2_ISR, (void *) 0);
	if (status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	status = XIntc_Start(&IntrController, XIN_REAL_MODE);
	if (status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	XIntc_Enable(&IntrController, TMR1_DEV_ID);
	XIntc_Enable(&IntrController, TMR2_DEV_ID);

	Xil_ExceptionInit();
	Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT,
			(Xil_ExceptionHandler) XIntc_InterruptHandler, &IntrController);
	Xil_ExceptionEnable();

	return XST_SUCCESS;
}

#else

void TMR1_ISR(void *CallbackRef) {
	(void) CallbackRef;
}

void TMR2_ISR(void *CallbackRef) {
	(void) CallbackRef;
}

int SetupInterruptSystem() {
	return XST_SUCCESS;
}

#endif