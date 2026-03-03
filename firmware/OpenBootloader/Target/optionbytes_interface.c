/**
  ******************************************************************************
  * @file    optionbytes_interface.c
  * @author  MCD Application Team
  * @brief   Contains Option Bytes access functions
  ******************************************************************************
  * @attention
  *
  * Copyright (c) 2022 STMicroelectronics.
  * All rights reserved.
  *
  * This software is licensed under terms that can be found in the LICENSE file
  * in the root directory of this software component.
  * If no LICENSE file comes with this software, it is provided AS-IS.
  *
  ******************************************************************************
  */

/* Includes ------------------------------------------------------------------*/
#include "platform.h"
#include "openbl_mem.h"
#include "app_openbootloader.h"
#include "common_interface.h"
#include "optionbytes_interface.h"

/* Private typedef -----------------------------------------------------------*/
/* Private define ------------------------------------------------------------*/
/* Private macro -------------------------------------------------------------*/
/* Private variables ---------------------------------------------------------*/
/* Private function prototypes -----------------------------------------------*/
/* Exported variables --------------------------------------------------------*/
OPENBL_MemoryTypeDef OB1_Descriptor =
{
  OB1_START_ADDRESS,
  OB1_END_ADDRESS,
  OB1_SIZE,
  OB_AREA,
  OPENBL_OB_Read,
  OPENBL_OB_Write,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL
};

/* Exported functions --------------------------------------------------------*/

/**
  * @brief  Launch the option byte loading.
  * @retval None.
  */
void OPENBL_OB_Launch(void)
{
  /* Set the option start bit */
  HAL_FLASH_OB_Launch();

  /* Set the option lock bit and Lock the flash */
  HAL_FLASH_OB_Lock();
  HAL_FLASH_Lock();
}

/**
  * @brief  This function is used to read data from a given address.
  * @param  Address The address to be read.
  * @retval Returns the read value.
  */
uint8_t OPENBL_OB_Read(uint32_t Address)
{
  return (*(uint8_t *)(Address));
}

/**
  * @brief  This function is used to write data in Option bytes.
  * @param  Address The address where that data will be written.
  * @param  Data The data to be written.
  * @param  DataLength The length of the data to be written.
  * @retval None.
  */
void OPENBL_OB_Write(uint32_t Address, uint8_t *Data, uint32_t DataLength)
{
  uint32_t timeout = 0U;

  /* Unlock the FLASH & Option Bytes Registers access */
  HAL_FLASH_Unlock();
  HAL_FLASH_OB_Unlock();

  /* Clear error programming flags */
  __HAL_FLASH_CLEAR_FLAG(FLASH_FLAG_PGERR | FLASH_FLAG_WRPERR);

  /* Write USER OPT + RDP level */
  if (DataLength >= 1U)
  {
    WRITE_REG(FLASH->OBR, (*(Data) | (*(Data + 1U) << 8U) | (*(Data + 2U) << 16U) | (*(Data + 3U) << 24U)));
  }

  /* Check the BSY bit for potential FLASH on going operation */
  while (__HAL_FLASH_GET_FLAG(FLASH_FLAG_BSY))
  {
    if ((timeout++) >= OPENBL_OB_TIMEOUT)
    {
      NVIC_SystemReset();
    }
  }
  timeout = 0U;

  /* Check the PESD bit*/
  while (__HAL_FLASH_GET_FLAG(FLASH_FLAG_PESD))
  {
    if ((timeout++) >= OPENBL_OB_TIMEOUT)
    {
      NVIC_SystemReset();
    }
  }
  timeout = 0U;

  /* Trigger options bytes programming operation */
  SET_BIT(FLASH->CR, FLASH_CR_OPTSTRT);

  /* Check the BSY bit for potential FLASH on going operation */
  while (__HAL_FLASH_GET_FLAG(FLASH_FLAG_BSY))
  {
    if ((timeout++) >= OPENBL_OB_TIMEOUT)
    {
      NVIC_SystemReset();
    }
  }

  /* Register system reset callback */
  Common_SetPostProcessingCallback(OPENBL_OB_Launch);
}
