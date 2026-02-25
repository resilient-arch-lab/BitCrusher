#include "arming.h"
#include <stdint.h>

// Validate voltage value. Returns 0 if valid or 1 if invalid
int is_valid_voltage(uint16_t voltage){
    if (voltage < 150 || voltage > 500) {
        return 1;
    }
    return 0;
}

// Validate trigger polarity value. Returns 0 if valid or 1 if invalid
int is_valid_trigger_polarity(uint8_t trigger_polarity){
    if (trigger_polarity != 0 && trigger_polarity != 1) {
        return 1;
    }
    return 0;
}

// Validate trigger mode value. Returns 0 if valid or 1 if invalid
int is_valid_trigger_mode(uint8_t trigger_mode){
    if (trigger_mode != 0 && trigger_mode != 1) {
        return 1;
    }
    return 0;
}

// Validate trigger src value. Returns 0 if valid or 1 if invalid
int is_valid_trigger_src(uint8_t trigger_src){
    if (trigger_src != 0 && trigger_src != 1) {
        return 1;
    }
    return 0;
}

// Validate all values in arming config. Returns 0 if valid or 1 if invalid
int is_valid_arming_config(arming_config_t *config) {
    int valid = 1;
    valid &= !is_valid_voltage(config->voltage);
    valid &= !is_valid_trigger_polarity(config->trigger_polarity);
    valid &= !is_valid_trigger_mode(config->trigger_mode);
    valid &= !is_valid_trigger_src(config->trigger_src);
    return valid;
}