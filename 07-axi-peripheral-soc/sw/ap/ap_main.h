/*
 * ap_main.h
 *
 *  Created on: 2026. 4. 28.
 *      Author: kccistc
 */

#ifndef SRC_AP_AP_MAIN_H_
#define SRC_AP_AP_MAIN_H_

typedef enum {
	counter, clock,
} mode_state_t;


void ap_init();
void ap_excute();

#endif /* SRC_AP_AP_MAIN_H_ */
