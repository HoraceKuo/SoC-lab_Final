#include "define.h"
// #include <caravel.h>

void __attribute__ ( ( section ( ".mprjram" ) ) ) test(){

	reg_mprj_datal = 0xAB000000; // start fir
	reg_DMA_addr = fir_taps_base; // fir tap
	reg_DMA_cfg = (1 << DMA_cfg_start) | (DMA_type_MEM2IO << DMA_cfg_type) | (DMA_ch_FIR << DMA_cfg_channel) | (NUM_FIR_TAP<<DMA_cfg_length);
	while(!(reg_DMA_cfg & (1<<DMA_cfg_idle))) ; // wait for DMA done

	reg_DMA_addr = fir_input_base; // FIR input
	reg_DMA_cfg = (1 << DMA_cfg_start) | (DMA_type_MEM2IO << DMA_cfg_type) | (DMA_ch_FIR << DMA_cfg_channel) | (NUM_FIR_INPUT<<DMA_cfg_length);
	while(!(reg_DMA_cfg & (1<<DMA_cfg_idle))) ; // wait for DMA done

	reg_DMA_addr = fir_output_base;// FIR output
	reg_DMA_cfg = (1 << DMA_cfg_start) | (DMA_type_IO2MEM << DMA_cfg_type) | (DMA_ch_FIR << DMA_cfg_channel) | (NUM_FIR_OUTPUT<<DMA_cfg_length);
	while(!(reg_DMA_cfg & (1<<DMA_cfg_idle))) ;// wait for DMA done

	reg_mprj_datal = 0xAB010000;// end flag - FIR

	// start flag - matmul
	reg_mprj_datal = 0xAB100000;
	// matmul input A
	reg_DMA_addr = mat_A_base;
	reg_DMA_cfg = (1 << DMA_cfg_start) | (DMA_type_MEM2IO << DMA_cfg_type) | (DMA_ch_matmul << DMA_cfg_channel) | (NUM_MAT_A<<DMA_cfg_length);
	// wait for DMA done
	while(!(reg_DMA_cfg & (1<<DMA_cfg_idle))) ;
	// matmul input B
	reg_DMA_addr = mat_B_base;
	reg_DMA_cfg = (1 << DMA_cfg_start) | (DMA_type_MEM2IO << DMA_cfg_type) | (DMA_ch_matmul << DMA_cfg_channel) | (NUM_MAT_B<<DMA_cfg_length);
	// wait for DMA done
	while(!(reg_DMA_cfg & (1<<DMA_cfg_idle))) ;
	// matmul output
	reg_DMA_addr = mat_output_base;
	reg_DMA_cfg = (1 << DMA_cfg_start) | (DMA_type_IO2MEM << DMA_cfg_type) | (DMA_ch_matmul << DMA_cfg_channel) | (NUM_MAT_OUTPUT<<DMA_cfg_length);
	// wait for DMA done
	while(!(reg_DMA_cfg & (1<<DMA_cfg_idle))) ;
	// end flag - matmul
	reg_mprj_datal = 0xAB110000;

	// start flag - qsort
	reg_mprj_datal = 0xAB200000;
	// qsort input
	reg_DMA_addr = qsort_input_base;
	reg_DMA_cfg = (1 << DMA_cfg_start) | (DMA_type_MEM2IO << DMA_cfg_type) | (DMA_ch_qsort << DMA_cfg_channel) | (NUM_QSORT_INPUT<<DMA_cfg_length);
	// wait for DMA done
	while(!(reg_DMA_cfg & (1<<DMA_cfg_idle))) ;
	// qsort output
	reg_DMA_addr = mat_output_base;
	reg_DMA_cfg = (1 << DMA_cfg_start) | (DMA_type_IO2MEM << DMA_cfg_type) | (DMA_ch_qsort << DMA_cfg_channel) | (NUM_QSORT_OUTPUT<<DMA_cfg_length);
	// wait for DMA done
	while(!(reg_DMA_cfg & (1<<DMA_cfg_idle))) ;
	// end flag - qsort
	reg_mprj_datal = 0xAB210000;

	// return 0;
}

void __attribute__ ( ( section ( ".mprj" ) ) ) uart_write(int n)
{
    while(((reg_uart_stat>>3) & 1));
    reg_tx_data = n;
}

void __attribute__ ( ( section ( ".mprj" ) ) ) uart_write_char(char c)
{
	if (c == '\n')
		uart_write_char('\r');

    // wait until tx_full = 0
    while(((reg_uart_stat>>3) & 1));
    reg_tx_data = c;
}

void __attribute__ ( ( section ( ".mprj" ) ) ) uart_write_string(const char *s)
{
    while (*s)
        uart_write_char(*(s++));
}


char __attribute__ ( ( section ( ".mprj" ) ) ) uart_read_char()
{
	char num;
    if((((reg_uart_stat>>5) | 0) == 0) && (((reg_uart_stat>>4) | 0) == 0)){
        for(int i = 0; i < 1; i++)
            asm volatile ("nop");

        num = reg_rx_data;
    }

    return num;
}

int __attribute__ ( ( section ( ".mprj" ) ) ) uart_read()
{
    int num;
    if((((reg_uart_stat>>5) | 0) == 0) && (((reg_uart_stat>>4) | 0) == 0)){
        for(int i = 0; i < 1; i++)
            asm volatile ("nop");

        num = reg_rx_data;
    }

    return num;
}

