#include "led.h"





void led_init() {
	GPIO_SetMode(GPIOC,
			LED_PIN_0 | LED_PIN_1 | LED_PIN_2 | LED_PIN_3 | LED_PIN_4
					| LED_PIN_5 | LED_PIN_6 | LED_PIN_7, OUTPUT);
}

void led_run() {

}


void led_upcounter() {
	//GPIO_WritePort(GPIO_LED_PIN, 0x80);
	GPIO_WritePin(GPIO_LED_PIN,GPIO_PIN_7,SET);
	GPIO_WritePin(GPIO_LED_PIN, GPIO_PIN_4 | GPIO_PIN_5 | GPIO_PIN_6 , RESET);

}

void led_clock(){
	//GPIO_WritePort(GPIO_LED_PIN, 0x40);
	GPIO_WritePin(GPIO_LED_PIN,GPIO_PIN_6,SET);
	GPIO_WritePin(GPIO_LED_PIN, GPIO_PIN_4 | GPIO_PIN_5 | GPIO_PIN_7, RESET);

}


void led_hh(){
	//GPIO_WritePort(GPIO_LED_PIN, 0x20);
	GPIO_WritePin(GPIO_LED_PIN,GPIO_PIN_5,SET);
	GPIO_WritePin(GPIO_LED_PIN, GPIO_PIN_4 | GPIO_PIN_6 | GPIO_PIN_7, RESET);

}

void led_ss(){
	//GPIO_WritePort(GPIO_LED_PIN, 0x10);
	GPIO_WritePin(GPIO_LED_PIN,GPIO_PIN_4,SET);
	GPIO_WritePin(GPIO_LED_PIN, GPIO_PIN_5 | GPIO_PIN_6 | GPIO_PIN_7, RESET);

}



void led_Upcount_Shift() {
	static uint8_t usdata = 0x01;
	static uint32_t prevtime = 0;

	if (millis() - prevtime < 100)
	{
	prevtime = millis();
	GPIO_WritePort(GPIO_LED_PIN, usdata);
	usdata = usdata << 1;
	if (usdata == 0x10) {
		usdata = 0x01;
	}
	}
}

void led_Clock_Shift() {
	static uint8_t csdata = 0x01;
	static uint32_t cprevtime = 0;

	if (millis() - cprevtime < 500)
	{
	cprevtime = millis();
	GPIO_WritePort(GPIO_LED_PIN, csdata);
	csdata = csdata << 1;

	if (csdata == 0x10) {
		csdata = 0x01;
	}
}
}
void led_drive() {

}
