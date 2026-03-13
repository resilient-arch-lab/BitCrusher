#include "flyback_control.h"

void PI_step(const PI_config_t *cfg, PI_handle_t *pi, float fb, float set) {
    pi->err = set - fb;
    // pi->it += cfg->Ki*pi->err*cfg->T;
    pi->out = (cfg->Kp*pi->err) + pi->it;
}