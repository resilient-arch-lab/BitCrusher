/* USER CODE BEGIN Header */
/**
  ******************************************************************************
  * @file           : main.h
  * @brief          : Header for main.c file.
  *                   This file contains the common defines of the application.
  ******************************************************************************
  * @attention
  *
  * Copyright (c) 2026 STMicroelectronics.
  * All rights reserved.
  *
  * This software is licensed under terms that can be found in the LICENSE file
  * in the root directory of this software component.
  * If no LICENSE file comes with this software, it is provided AS-IS.
  *
  ******************************************************************************
  */
/* USER CODE END Header */

/* Define to prevent recursive inclusion -------------------------------------*/
#ifndef __MAIN_H
#define __MAIN_H

#ifdef __cplusplus
extern "C" {
#endif

/* Includes ------------------------------------------------------------------*/
#include "stm32f3xx_hal.h"

/* Private includes ----------------------------------------------------------*/
/* USER CODE BEGIN Includes */

/* USER CODE END Includes */

/* Exported types ------------------------------------------------------------*/
/* USER CODE BEGIN ET */

/* USER CODE END ET */

/* Exported constants --------------------------------------------------------*/
/* USER CODE BEGIN EC */

/* USER CODE END EC */

/* Exported macro ------------------------------------------------------------*/
/* USER CODE BEGIN EM */

/* USER CODE END EM */

/* Exported functions prototypes ---------------------------------------------*/
void Error_Handler(void);

/* USER CODE BEGIN EFP */

/* USER CODE END EFP */

/* Private defines -----------------------------------------------------------*/
#define TIM2_PWM_Period 100000
#define HVSense__Pin GPIO_PIN_0
#define HVSense__GPIO_Port GPIOA
#define HVSense_A1_Pin GPIO_PIN_1
#define HVSense_A1_GPIO_Port GPIOA
#define HVPWM_Pin GPIO_PIN_5
#define HVPWM_GPIO_Port GPIOA
#define HWTrig__Pin GPIO_PIN_7
#define HWTrig__GPIO_Port GPIOA
#define HVCS_Pin GPIO_PIN_14
#define HVCS_GPIO_Port GPIOB
#define PulseEN_Pin GPIO_PIN_11
#define PulseEN_GPIO_Port GPIOA
#define IntTrig__Pin GPIO_PIN_9
#define IntTrig__GPIO_Port GPIOB

/* USER CODE BEGIN Private defines */

/* USER CODE END Private defines */

#ifdef __cplusplus
}
#endif

#endif /* __MAIN_H */
