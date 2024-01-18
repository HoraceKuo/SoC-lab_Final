// This file is Copyright (c) 2020 Florent Kermarrec <florent@enjoy-digital.fr>
// License: BSD

#include <csr.h>
#include <soc.h>
#include <irq_vex.h>
#include <user_uart.h>
#include <defs.h>

extern int uart_read();
extern char uart_read_char();
extern char uart_write_char();
extern int uart_write();

void isr(void);

#ifdef CONFIG_CPU_HAS_INTERRUPT

#ifdef USER_PROJ_IRQ0_EN
uint32_t counter = 0xFFFF0000;
#endif

void isr(void)
{

#ifndef USER_PROJ_IRQ0_EN

    irq_setmask(0);


#else
    uint32_t irqs = irq_pending() & irq_getmask();
    int buf1, buf2, buf3, buf4, buf5, buf6, buf7, buf8;

    if ( irqs & (1 << USER_IRQ_0_INTERRUPT)) {
        user_irq_0_ev_pending_write(1); //Clear Interrupt Pending Event
        buf1 = uart_read();
        buf2 = uart_read();
        buf3 = uart_read();
        buf4 = uart_read();
        buf5 = uart_read();
        buf6 = uart_read();
        buf7 = uart_read();
        buf8 = uart_read();
        uart_write(buf1);
        uart_write(buf2);
        uart_write(buf3);
        uart_write(buf4);
        uart_write(buf5);
        uart_write(buf6);
        uart_write(buf7);
        uart_write(buf8);

    }
#endif

    return;

}

#else

void isr(void){};

#endif
