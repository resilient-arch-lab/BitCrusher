#ifndef __FLYBACK_CONTROL_H__
#define __FLYBACK_CONTROL_H__

#ifdef __cplusplus
extern "C" {
#endif

#include "main.h"

// voltage feedback conversion macros
#define HVVS_MAX 3
#define HVVS_MIN 0
#define VDDA (float )3.3
#define HV_MIN 150
#define HV_MAX 500

// PWM duty cycle macros
#define D_MIN 0.1
#define D_MAX 0.49
#define PWM_P 720

#define ADC_TO_V(x) (VDDA/(0x0fff))*x
#define V_TO_VHV(x) ((float )HV_MAX/(float )(HVVS_MAX - HVVS_MIN))*x

typedef struct {
    float Kp;   // proportional gain
    float Ki;   // integral gain
    float Kd;   // derivative gain
    float norm_max;  // output max
    float norm_min;  // output min
    float T;    // timestep for integral / derivative calculation
} PI_config_t;

// persistent state / cache of the PID controller instance
typedef struct {
    float it;           // integral result
    float dv;           // derivative result
    float err;          // error value
    float out;          // output value
    // float out_norm;     // normalized output
} PI_handle_t;

void PI_step(PI_config_t *cfg, PI_handle_t *pi, float fb, float set);

#ifdef __cplusplus
}
#endif
#endif /*__ FLYBACK_CONTROL_H__ */