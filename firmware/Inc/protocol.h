
#ifndef __PROTOCOL_H__
#define __PROTOCOL_H__

#ifdef __cplusplus
extern "C" {
#endif


#include <stdint.h>

#define BODY_MAX_LEN 256
typedef uint8_t msg_len_t;
typedef uint8_t msg_hdr_t;
#define MSG_MAX_LEN sizeof(msg_hdr_t) + sizeof(msg_len_t) + BODY_MAX_LEN

#define HDR_SUCCESS (uint8_t )0x01
#define HDR_ERROR (uint8_t )0x02
#define HDR_GET_PARAM (uint8_t )0x11
#define HDR_SET_PARAM (uint8_t )0x12
#define HDR_GET_STATE (uint8_t )0x21
#define HDR_ARM (uint8_t )0xa0
#define HDR_SET_ARM_PARAM (uint8_t )0xa1
#define HDR_GET_ARM_PARAM (uint8_t )0xa2
#define HDR_DISARM (uint8_t )0xaf
#define HDR_BOOTLOADER 0xb0

int is_valid_header(uint8_t hdr);

#ifdef __cplusplus
}
#endif

#endif  // #define __PROTOCOL_H__
    