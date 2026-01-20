#ifndef __ARMING_H__
#define __ARMING_H__

#include <stdint.h>
#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
    uint16_t voltage;  // in [150V, 500V]
    uint8_t trigger_polarity;  // 0: low, 1: high
    uint8_t trigger_mode;  // 0: continuous, 1: single
    uint8_t trigger_src;  // 0: HW, 1: FW
} arming_config_t;


#ifdef __cplusplus
}
#endif

#endif  // #define __ARMING_H__