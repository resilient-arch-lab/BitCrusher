#include "main.h"
#include <stdint.h>
#include "protocol.h"


int is_valid_header(uint8_t hdr) {
    switch (hdr) {
        case HDR_SUCCESS:
        case HDR_ERROR:
        case HDR_GET_PARAM:
        case HDR_SET_PARAM:
        case HDR_GET_STATE:
        case HDR_ARM:
        case HDR_SET_ARM_PARAM:
        case HDR_GET_ARM_PARAM:
        case HDR_DISARM: {
            return 1;
            break;
        }
        default: {
            return 0;
            break;
        }
    }
}