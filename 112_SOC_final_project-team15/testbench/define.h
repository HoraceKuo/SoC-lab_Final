#ifndef __DEFINE_H__
#define __DEFINE_H__
#include <defs.h>

#define NUM_FIR_TAP    11
#define NUM_FIR_INPUT  64
#define NUM_FIR_OUTPUT 64
#define MAT_SIZE 4
#define NUM_MAT_A      (MAT_SIZE*MAT_SIZE)
#define NUM_MAT_B      (MAT_SIZE*MAT_SIZE)
#define NUM_MAT_OUTPUT (MAT_SIZE*MAT_SIZE)
#define QSORT_SIZE 10
#define NUM_QSORT_INPUT  QSORT_SIZE
#define NUM_QSORT_OUTPUT QSORT_SIZE
#define DMA_cfg_length  0
#define DMA_cfg_channel 7
#define DMA_cfg_type    9
#define DMA_cfg_start   10
#define DMA_cfg_idle    11
#define DMA_cfg_done    12
#define DMA_addr_base   0

#define DMA_ch_FIR    0
#define DMA_ch_matmul 1
#define DMA_ch_qsort  2

#define DMA_type_MEM2IO 0
#define DMA_type_IO2MEM 1
// Memory-Map Address
//DMA
#define reg_DMA_cfg  (*(volatile uint32_t*)0x30008000)  // 0x3000_8000
#define reg_DMA_addr (*(volatile uint32_t *)0x30008004) // 0x3000_8004
//Uart
#define reg_rx_data   (*(volatile uint32_t *)0x31000000) // 0x3100_0000
#define reg_tx_data   (*(volatile uint32_t *)0x31000004) // 0x3100_0004
#define reg_uart_stat (*(volatile uint32_t *)0x31000008)    // 0x3100_0008


// Memory Map of BRAM u0 (data - unprocessed)
typedef enum
{
    fir_taps_base,
    fir_taps_end     = (fir_taps_base + NUM_FIR_TAP - 1),
    fir_input_base,
    fir_input_end    = (fir_input_base + NUM_FIR_INPUT - 1),
    mat_A_base,
    mat_A_end        = (mat_A_base + NUM_MAT_A - 1),
    mat_B_base,
    mat_B_end        = (mat_B_base + NUM_MAT_B - 1),
    qsort_input_base,
    qsort_input_end  = (qsort_input_base + NUM_QSORT_INPUT - 1)
} MM_BRAM_u0;

// Memory Map of BRAM u1 (data - processed)
typedef enum
{
    fir_output_base,
    fir_output_end    = (fir_output_base + NUM_FIR_OUTPUT - 1),
    mat_output_base,
    mat_output_end    = (mat_output_base + NUM_MAT_OUTPUT - 1),
    qsort_output_base,
    qsort_output_end  = (qsort_output_base + NUM_QSORT_OUTPUT - 1)
} MM_BRAM_u1;

int fir_taps[NUM_FIR_TAP] = {0,-10,-9,23,56,63,56,23,-9,-10,0};
int fir_input[NUM_FIR_INPUT] = 
{
     1, 2, 3, 4, 5, 6, 7, 8, 9,10,
    11,12,13,14,15,16,17,18,19,20,
    21,22,23,24,25,26,27,28,29,30,
    31,32,33,34,35,36,37,38,39,40,
    41,42,43,44,45,46,47,48,49,50,
    51,52,53,54,55,56,57,58,59,60,
    61,62,63,64
};
int fir_output[NUM_FIR_INPUT];

// matmul
int mat_A[NUM_MAT_A] = 
{
        0, 1, 2, 3,
        0, 1, 2, 3,
        0, 1, 2, 3,
        0, 1, 2, 3,
};
int mat_B[NUM_MAT_B] = 
{   
    1, 5, 9, 13,
    2, 6, 10, 14,
    3, 7, 11, 15,
    4, 8, 12, 16,
};
int mat_output[NUM_MAT_OUTPUT];

// qsort
int qsort_input[NUM_QSORT_INPUT] = {893, 40, 3233, 4267, 2669, 2541, 9073, 6023, 5681, 4622};
int qsort_output[NUM_QSORT_OUTPUT];

#endif