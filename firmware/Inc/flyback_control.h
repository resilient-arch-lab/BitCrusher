#ifndef __FLYBACK_CONTROL_H__
#define __FLYBACK_CONTROL_H__

#ifdef __cplusplus
extern "C" {
#endif

#include "main.h"

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
    float out_norm;     // normalized output
} PI_handle_t;

void PI_step(PI_config_t *cfg, PI_handle_t *pi, float fb, float set);




#ifdef __cplusplus
}
#endif
#endif /*__ FLYBACK_CONTROL_H__ */