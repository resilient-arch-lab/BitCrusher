/* USER CODE BEGIN Header */
/**
  ******************************************************************************
  * @file           : main.c
  * @brief          : Main program body
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
/* Includes ------------------------------------------------------------------*/
#include "main.h"
#include "adc.h"
#include "comp.h"
#include "dac.h"
#include "dma.h"
#include "stm32f3xx_hal.h"
#include "stm32f3xx_hal_def.h"
#include "stm32f3xx_hal_uart.h"
#include "tim.h"
#include "usart.h"
#include "gpio.h"
#include "protocol.h"
#include "arming.h"
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <sys/_pthreadtypes.h>

/* Private includes ----------------------------------------------------------*/
/* USER CODE BEGIN Includes */

/* USER CODE END Includes */

/* Private typedef -----------------------------------------------------------*/
/* USER CODE BEGIN PTD */

/* USER CODE END PTD */

/* Private define ------------------------------------------------------------*/
/* USER CODE BEGIN PD */

/* USER CODE END PD */

/* Private macro -------------------------------------------------------------*/
/* USER CODE BEGIN PM */

/* USER CODE END PM */

/* Private variables ---------------------------------------------------------*/

/* USER CODE BEGIN PV */
uint8_t uart_buf[MSG_MAX_LEN];
msg_hdr_t msg_hdr;
msg_len_t msg_len;
uint8_t msg_body[BODY_MAX_LEN];

arming_config_t arming_config = {
  0,
  1,
  0,
  0
};

/* USER CODE END PV */

/* Private function prototypes -----------------------------------------------*/
void SystemClock_Config(void);
/* USER CODE BEGIN PFP */

/* USER CODE END PFP */

/* Private user code ---------------------------------------------------------*/
/* USER CODE BEGIN 0 */
// Get message from UART, decode into msg_hdr, msg_len, and msg_body vars
// returns 1 on error, 0 on success
int get_message(void) {
  // get header byte, validate
  HAL_StatusTypeDef res = HAL_UART_Receive(&huart1, &msg_hdr, 1, 1000);
  if (res != HAL_OK || !is_valid_header(msg_hdr)) return 1;

  // get length byte
  res = HAL_UART_Receive(&huart1, &msg_len, 1, 100);
  if (res != HAL_OK) return 1;

  // get the message body
  res = HAL_UART_Receive(&huart1, msg_body, (uint16_t )msg_len, 100);
  if (res != HAL_OK) return 1;
  return 0;
}

// Encode message from msg_hdr, msg_len, and msg_body, and send over UART
// returns 1 on error, 0 on success
int send_message(void) {
  // validate header, format message
  if (!is_valid_header(msg_hdr)) return 1;
  uart_buf[0] = msg_hdr;
  uart_buf[1] = msg_len;
  memcpy((void *)uart_buf+2, (void *)msg_body, msg_len);

  // send over UART
  // TODO: error check
  HAL_StatusTypeDef res = HAL_UART_Transmit(&huart1, uart_buf, (uint16_t)msg_len+2, 100);
  if (res != HAL_OK) return 1;
  return 0;
}

int process_command(void) {
  switch (msg_hdr) {
    case HDR_GET_ARM_PARAM: {
      if (msg_len != 1) return 1;
      switch ((int )msg_body[0]) {
        case 0: 
      }
    }
  }
}

int get_arm_param(void) {
  if (msg_len != 1) return 1;

  switch ((int )msg_body[0]) {
    case 0: {
      uint16_t voltage = arming_config.voltage;
      break;
    }
  }
}




/* USER CODE END 0 */

/**
  * @brief  The application entry point.
  * @retval int
  */
int main(void)
{
  /* Reset of all peripherals, Initializes the Flash interface and the Systick. */
  HAL_Init();

  /* USER CODE BEGIN Init */

  /* Configure the system clock */
  SystemClock_Config();

  /* USER CODE BEGIN SysInit */

  /* Initialize all configured peripherals */
  MX_GPIO_Init();
  MX_DMA_Init();
  MX_ADC1_Init();
  MX_COMP2_Init();
  MX_COMP3_Init();
  MX_TIM2_Init();
  MX_DAC1_Init();
  MX_TIM3_Init();
  MX_USART1_UART_Init();

  char *tmp_str = "Error\n";

  /* USER CODE BEGIN 2 */
  while (1) {
    // UART loop
    // HAL_UART_Transmit(&huart1, (uint8_t *)tmp_str, 8, 100);
    // HAL_Delay(1000);
    int res = get_message();
    if (res) {
      HAL_UART_Transmit(&huart1, (uint8_t *)tmp_str, 6, 100);
    } else {
      res = send_message();  // send the same message back
    }
    HAL_Delay(100);
  }
}



/**
  * @brief System Clock Configuration
  * @retval None
  */
void SystemClock_Config(void)
{
  RCC_OscInitTypeDef RCC_OscInitStruct = {0};
  RCC_ClkInitTypeDef RCC_ClkInitStruct = {0};
  RCC_PeriphCLKInitTypeDef PeriphClkInit = {0};

  /** Initializes the RCC Oscillators according to the specified parameters
  * in the RCC_OscInitTypeDef structure.
  */
  RCC_OscInitStruct.OscillatorType = RCC_OSCILLATORTYPE_HSI;
  RCC_OscInitStruct.HSIState = RCC_HSI_ON;
  RCC_OscInitStruct.HSICalibrationValue = RCC_HSICALIBRATION_DEFAULT;
  RCC_OscInitStruct.PLL.PLLState = RCC_PLL_ON;
  RCC_OscInitStruct.PLL.PLLSource = RCC_PLLSOURCE_HSI;
  RCC_OscInitStruct.PLL.PLLMUL = RCC_PLL_MUL9;
  RCC_OscInitStruct.PLL.PREDIV = RCC_PREDIV_DIV1;
  if (HAL_RCC_OscConfig(&RCC_OscInitStruct) != HAL_OK)
  {
    Error_Handler();
  }

  /** Initializes the CPU, AHB and APB buses clocks
  */
  RCC_ClkInitStruct.ClockType = RCC_CLOCKTYPE_HCLK|RCC_CLOCKTYPE_SYSCLK
                              |RCC_CLOCKTYPE_PCLK1|RCC_CLOCKTYPE_PCLK2;
  RCC_ClkInitStruct.SYSCLKSource = RCC_SYSCLKSOURCE_PLLCLK;
  RCC_ClkInitStruct.AHBCLKDivider = RCC_SYSCLK_DIV1;
  RCC_ClkInitStruct.APB1CLKDivider = RCC_HCLK_DIV2;
  RCC_ClkInitStruct.APB2CLKDivider = RCC_HCLK_DIV1;

  if (HAL_RCC_ClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_2) != HAL_OK)
  {
    Error_Handler();
  }
  PeriphClkInit.PeriphClockSelection = RCC_PERIPHCLK_USART1|RCC_PERIPHCLK_ADC12
                              |RCC_PERIPHCLK_TIM2|RCC_PERIPHCLK_TIM34;
  PeriphClkInit.Usart1ClockSelection = RCC_USART1CLKSOURCE_PCLK2;
  PeriphClkInit.Adc12ClockSelection = RCC_ADC12PLLCLK_DIV1;
  PeriphClkInit.Tim2ClockSelection = RCC_TIM2CLK_HCLK;
  PeriphClkInit.Tim34ClockSelection = RCC_TIM34CLK_HCLK;
  if (HAL_RCCEx_PeriphCLKConfig(&PeriphClkInit) != HAL_OK)
  {
    Error_Handler();
  }
}

/* USER CODE BEGIN 4 */

/* USER CODE END 4 */

/**
  * @brief  This function is executed in case of error occurrence.
  * @retval None
  */
void Error_Handler(void)
{
  /* USER CODE BEGIN Error_Handler_Debug */
  /* User can add his own implementation to report the HAL error return state */
  __disable_irq();
  while (1)
  {
  }
  /* USER CODE END Error_Handler_Debug */
}
#ifdef USE_FULL_ASSERT
/**
  * @brief  Reports the name of the source file and the source line number
  *         where the assert_param error has occurred.
  * @param  file: pointer to the source file name
  * @param  line: assert_param error line source number
  * @retval None
  */
void assert_failed(uint8_t *file, uint32_t line)
{
  /* USER CODE BEGIN 6 */
  /* User can add his own implementation to report the file name and line number,
     ex: printf("Wrong parameters value: file %s on line %d\r\n", file, line) */
  /* USER CODE END 6 */
}
#endif /* USE_FULL_ASSERT */
