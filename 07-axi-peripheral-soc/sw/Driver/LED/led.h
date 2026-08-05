/*
 * led.h
 *
 *  Created on: 2026. 4. 30.
 *      Author: kccistc
 */

#ifndef SRC_DRIVER_LED_LED_H_
#define SRC_DRIVER_LED_LED_H_

#include "../../common/common.h"
#include "../../HAL/GPIO/GPIO.h"

#define GPIO_LED_PIN GPIOC

#define LED_PIN_0 GPIO_PIN_0
#define LED_PIN_1 GPIO_PIN_1
#define LED_PIN_2 GPIO_PIN_2
#define LED_PIN_3 GPIO_PIN_3
#define LED_PIN_4 GPIO_PIN_4
#define LED_PIN_5 GPIO_PIN_5
#define LED_PIN_6 GPIO_PIN_6
#define LED_PIN_7 GPIO_PIN_7

void led_init();
void led_run();
void led_upcounter();
void led_clock();
void led_hh();
void led_ss();
void led_Upcount_Shift();
void led_Clock_Shift();

#endif /* SRC_DRIVER_LED_LED_H_ */
