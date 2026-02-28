/* USER CODE BEGIN Header */
/**
  ******************************************************************************
  * @file    comp.c
  * @brief   This file provides code for the configuration
  *          of the COMP instances.
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
#include "comp.h"

/* USER CODE BEGIN 0 */

/* USER CODE END 0 */

COMP_HandleTypeDef hcomptrig;
COMP_HandleTypeDef hcompHVCS;

/* COMP2 init function */
void MX_COMP2_Init(void)
{

  /* USER CODE BEGIN COMP2_Init 0 */

  /* USER CODE END COMP2_Init 0 */

  /* USER CODE BEGIN COMP2_Init 1 */

  /* USER CODE END COMP2_Init 1 */
  hcomptrig.Instance = COMP2;
  hcomptrig.Init.InvertingInput = COMP_INVERTINGINPUT_VREFINT;
  hcomptrig.Init.NonInvertingInput = COMP_NONINVERTINGINPUT_IO1;
  hcomptrig.Init.Output = COMP_OUTPUT_NONE;
  hcomptrig.Init.OutputPol = COMP_OUTPUTPOL_NONINVERTED;
  hcomptrig.Init.BlankingSrce = COMP_BLANKINGSRCE_NONE;
  hcomptrig.Init.TriggerMode = COMP_TRIGGERMODE_NONE;
  if (HAL_COMP_Init(&hcomptrig) != HAL_OK)
  {
    Error_Handler();
  }
  /* USER CODE BEGIN COMP2_Init 2 */

  /* USER CODE END COMP2_Init 2 */

}
/* COMP3 init function */
void MX_COMP3_Init(void)
{

  /* USER CODE BEGIN COMP3_Init 0 */

  /* USER CODE END COMP3_Init 0 */

  /* USER CODE BEGIN COMP3_Init 1 */

  /* USER CODE END COMP3_Init 1 */
  hcompHVCS.Instance = COMP3;
  hcompHVCS.Init.InvertingInput = COMP_INVERTINGINPUT_DAC1_CH1;
  hcompHVCS.Init.NonInvertingInput = COMP_NONINVERTINGINPUT_IO1;
  hcompHVCS.Init.Output = COMP_OUTPUT_TIM2OCREFCLR;
  hcompHVCS.Init.OutputPol = COMP_OUTPUTPOL_NONINVERTED;
  hcompHVCS.Init.BlankingSrce = COMP_BLANKINGSRCE_NONE;
  hcompHVCS.Init.TriggerMode = COMP_TRIGGERMODE_NONE;
  if (HAL_COMP_Init(&hcompHVCS) != HAL_OK)
  {
    Error_Handler();
  }
  /* USER CODE BEGIN COMP3_Init 2 */

  /* USER CODE END COMP3_Init 2 */

}

void HAL_COMP_MspInit(COMP_HandleTypeDef* compHandle)
{

  GPIO_InitTypeDef GPIO_InitStruct = {0};
  if(compHandle->Instance==COMP2)
  {
  /* USER CODE BEGIN COMP2_MspInit 0 */

  /* USER CODE END COMP2_MspInit 0 */

    __HAL_RCC_GPIOA_CLK_ENABLE();
    /**COMP2 GPIO Configuration
    PA7     ------> COMP2_INP
    PA12     ------> COMP2_OUT
    */
    GPIO_InitStruct.Pin = HWTrig__Pin;
    GPIO_InitStruct.Mode = GPIO_MODE_ANALOG;
    GPIO_InitStruct.Pull = GPIO_NOPULL;
    HAL_GPIO_Init(HWTrig__GPIO_Port, &GPIO_InitStruct);

    GPIO_InitStruct.Pin = IntTrig__Pin;
    GPIO_InitStruct.Mode = GPIO_MODE_AF_PP;
    GPIO_InitStruct.Pull = GPIO_NOPULL;
    GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
    GPIO_InitStruct.Alternate = GPIO_AF8_COMP2;
    HAL_GPIO_Init(IntTrig__GPIO_Port, &GPIO_InitStruct);

  /* USER CODE BEGIN COMP2_MspInit 1 */

  /* USER CODE END COMP2_MspInit 1 */
  }
  else if(compHandle->Instance==COMP3)
  {
  /* USER CODE BEGIN COMP3_MspInit 0 */

  /* USER CODE END COMP3_MspInit 0 */

    __HAL_RCC_GPIOB_CLK_ENABLE();
    /**COMP3 GPIO Configuration
    PB14     ------> COMP3_INP
    */
    GPIO_InitStruct.Pin = HVCS_Pin;
    GPIO_InitStruct.Mode = GPIO_MODE_ANALOG;
    GPIO_InitStruct.Pull = GPIO_NOPULL;
    HAL_GPIO_Init(HVCS_GPIO_Port, &GPIO_InitStruct);

  /* USER CODE BEGIN COMP3_MspInit 1 */

  /* USER CODE END COMP3_MspInit 1 */
  }
}

void HAL_COMP_MspDeInit(COMP_HandleTypeDef* compHandle)
{

  if(compHandle->Instance==COMP2)
  {
  /* USER CODE BEGIN COMP2_MspDeInit 0 */

  /* USER CODE END COMP2_MspDeInit 0 */

    /**COMP2 GPIO Configuration
    PA7     ------> COMP2_INP
    PA12     ------> COMP2_OUT
    */
    HAL_GPIO_DeInit(GPIOA, HWTrig__Pin|IntTrig__Pin);

  /* USER CODE BEGIN COMP2_MspDeInit 1 */

  /* USER CODE END COMP2_MspDeInit 1 */
  }
  else if(compHandle->Instance==COMP3)
  {
  /* USER CODE BEGIN COMP3_MspDeInit 0 */

  /* USER CODE END COMP3_MspDeInit 0 */

    /**COMP3 GPIO Configuration
    PB14     ------> COMP3_INP
    */
    HAL_GPIO_DeInit(HVCS_GPIO_Port, HVCS_Pin);

  /* USER CODE BEGIN COMP3_MspDeInit 1 */

  /* USER CODE END COMP3_MspDeInit 1 */
  }
}

/* USER CODE BEGIN 1 */

/* USER CODE END 1 */
