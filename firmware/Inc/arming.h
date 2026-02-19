#ifndef __ARMING_H__
#define __ARMING_H__

#include <stdint.h>
#ifdef __cplusplus
extern "C" {
#endif

#define ARM_HANDSHAKE_TIMEOUT = 1000  // timeout duration in ms

typedef struct {
    uint16_t voltage;  // in [150V, 500V]
    uint8_t trigger_polarity;  // 0: low, 1: high
    uint8_t trigger_mode;  // 0: continuous, 1: single
    uint8_t trigger_src;  // 0: HW, 1: FW
} arming_config_t;

int is_valid_voltage(uint16_t voltage);
int is_valid_trigger_polarity(uint8_t trigger_polarity);
int is_valid_trigger_mode(uint8_t trigger_mode);
int is_valid_trigger_src(uint8_t trigger_src);

int is_valid_arming_config(arming_config_t *config);


#ifdef __cplusplus
}
#endif

#endif  // #define __ARMING_H__