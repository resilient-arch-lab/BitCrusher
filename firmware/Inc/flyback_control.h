#ifndef __FLYBACK_CONTROL_H__
#define __FLYBACK_CONTROL_H__

#include <stdint.h>
#ifdef __cplusplus
extern "C" {
#endif

#include "main.h"

// voltage feedback conversion macros
// #define HVVS_MAX 3
#define HVVS_MAX 1.5
#define HVVS_MIN 0
#define VDDA (float )3.3
#define HV_MIN 150
#define HV_MAX 500
#define HV_COMP_WINDOW 0.1
#define RAMP(setpoint) 0 * (setpoint / HV_MAX)

// PWM duty cycle macros
#define D_MIN 0.08
#define D_MAX 0.29
#define PWM_P 720

// current limit trip level
#define V_ILIM_MAX 0.5
#define V_ILIM_MIN 0.2
#define V_ILIM V_ILIM_MAX
#define D_TO_ILIM(D) ((V_ILIM_MIN - V_ILIM_MAX)*D) + V_ILIM_MIN

// DEBUGGING:
//  1. get live readings from cap bank and measurement port, and compare
//  to sensed ADC voltage to make sure it matches.
//  2. simulate some results here with the expected range and make sure
//  the scaling is right and nothing is getting truncated 
constexpr uint16_t adc_meas_min = 0;
constexpr uint16_t adc_meas_max = 0x0fff;
#define ADC_TO_V(x) ((x * 3.3f) / (float) adc_meas_max)
#define VHV_OFFSET 0.85
#define V_TO_VHV(x) ((float )HV_MAX/(float )(HVVS_MAX - HVVS_MIN))*(x - VHV_OFFSET)
constexpr uint16_t adc_meas_test = adc_meas_max-3000;
constexpr float adc_to_v_test = ADC_TO_V(adc_meas_test);
constexpr float v_to_vhv_test = V_TO_VHV(adc_meas_test);

typedef struct {
    float Kp;       // proportional gain
    float Ki;       // integral gain
    float T;        // timestep for integral / derivative calculation
} PI_config_t;

// persistent state / cache of the PID controller instance
typedef struct {
    float it;           // integral result
    float dv;           // derivative result
    float err;          // error value
    float out;          // output value
    // float out_norm;     // normalized output
} PI_handle_t;

constexpr PI_config_t flyback_PWM_PI_cfg = {
    1.0,
    0.0,
    1.0
};

void PI_step(const PI_config_t *cfg, PI_handle_t *pi, float fb, float set);

#ifdef __cplusplus
}
#endif
#endif /*__ FLYBACK_CONTROL_H__ */