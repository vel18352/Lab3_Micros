;Archivo:	Lab3_Vel18352
;Dispositivo:   PIC16F887
;Autor:		Emilio Velasquez 18352
;Compilador:	XC8, MPLABX 5.40
;Programa:      Contador binario de 4 bits con Timer0
;Hardware:	Leds Puerto A
;Creado:	5/01/2023
;Ultima modificacion: 6/01/2023
    
    
// PIC16F887 Configuration Bit Settings

// 'C' source line CONFIG statements
    
// CONFIG1
CONFIG FOSC = INTRC_NOCLKOUT// Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
CONFIG WDTE = OFF       // Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
CONFIG PWRTE = OFF      // Power-up Timer Enable bit (PWRT disabled)
CONFIG MCLRE = OFF      // RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
CONFIG CP = OFF         // Code Protection bit (Program memory code protection is disabled)
CONFIG CPD = OFF        // Data Code Protection bit (Data memory code protection is disabled)
CONFIG BOREN = OFF      // Brown Out Reset Selection bits (BOR disabled)
CONFIG IESO = OFF       // Internal External Switchover bit (Internal/External Switchover mode is disabled)
CONFIG FCMEN = OFF      // Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
CONFIG LVP = OFF       // Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

// CONFIG2
CONFIG BOR4V = BOR21V   // Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
CONFIG WRT = OFF        // Flash Program Memory Self Write Enable bits (Write protection off)

//#pragma CONFIG statements should precede project file includes.
// Use project enums instead of #define for ON and OFF.

PROCESSOR 16F887
#include <xc.inc>
    
PSECT udata_bank0
  Contador: DS 1
  Contador_1s: DS 1 
  Bandera_1: DS 1
  Bandera_2: DS 1
    
PSECT resVect, CLASS=CODE, ABS, DELTA=2
;--------------------------- VECTOR RESET -----------------------------------
    ORG 00h	    ;Posicion para reset
resetVec:
    PAGESEL main    ;Pagina de main
    goto    main    ;Buscar label de main

PSECT CODE, DELTA=2, ABS
    ORG	100h	    ;Posicion inicio del codigo

;----------------------------- CONFIGURACIONES ---------------------------------


;------------- MAIN -------------
main:
    call    config_IO
    call    config_reloj
    call    config_TMR0	    ;Sub rutina para configuracion del PIC
    
;------------- LOOP -------------    
loop:
    btfsc   PORTD,0	    ;Si el botón 1 está presionado
    call    Incrementar	    ;Incrementar el contador 1
    btfsc   PORTD,1	    ;Si el botón 2 está presionado
    call    Decrementar	    ;Decrementar el contador 1
    btfss   T0IF	    ;Si el bit es 1 en T0IF skipea el goto
    goto    $-1		    ;Si es 0 regresa a la instrucci?n anterior
    call    reinicio_TMR0   ;Llamamos a la subrutina para que reinicie el timer0
    INCF    PORTB	    ;Incrementa F en el puerto B
    call    Contador_1seg   ;llama al contador de 1 segundo
    call    Comparar	    ;llama al comparador de de valores
    goto loop

;----------------------------- SUBRUTINAS --------------------------------------    
    
;----------- CONFIGURACION DE ENTRADAS Y SALIDAS -----------
config_IO:
    banksel ANSEL	;Va al banco de ANSEL
    clrf    ANSEL
    clrf    ANSELH	;Seleccion I/O digital
    
    banksel TRISA	;Seleccionar banco al que pertenece el TRISA
    clrf    TRISA
    bsf	    TRISA,7	;se configuran los primeros 7 bits para salida y se apaga el ultimo
    
    banksel TRISB	;Seleccionar banco al que pertenece el TRISB
    clrf    TRISB	;Configurado como output
    movlw   0xF0 	;4 bits
    movwf   TRISB	;se seleccionan 4 bits para mostrar
    
    banksel TRISC	;Seleccionar banco al que pertenece el TRISC
    clrf    TRISC	;Configurado como output
    movlw   0x70 	;5 bits
    movwf   TRISC	;se seleccionan 5 bits para mostrar
    
    banksel TRISD	;Seleccionar banco al que pertenece el TRISD
    movlw   0x03  	;Configurar primeros 2 pins inputs 
    movwf   TRISD	;Mover W a TRSID
    
    banksel PORTA
    clrf    PORTA	;Limpiar Puerto A
    
    banksel PORTB	
    clrf    PORTB	;Limpiar Puerto B
    
    banksel PORTC
    clrf    PORTC	;Limpiar Puerto C
    
    movlw   0x00
    movwf   Contador    ;Limpiar Contador
    movlw   0x00
    movwf   Contador_1s ;Limpiar contador 1sec
    
    return
    
;----------- CONFIGURACION DEL RELOJ -----------
config_reloj:
    banksel OSCCON  ;Ir al banco que pertenece OSCCON
    bcf	    IRCF2   
    bsf	    IRCF1
    bsf	    IRCF0   ;IRCF<2:0> = 011 ---> 500KHz
    bsf	    SCS	    ;Reloj interno
    return
    
;----------- CONFIGURACION DEL TIMER0 -----------    
config_TMR0: 
    banksel TRISB   ;Ir al banco que pertenece TRISB
    bcf	    T0CS    ;Reloj interno
    bcf	    PSA	    ;Prescaler	en TMR0
    bsf	    PS2
    bsf	    PS1
    bsf	    PS0	    ;PS<2:0> = 111 ---> 1:256
    banksel PORTB   
    call    reinicio_TMR0
    return
    
;----------- REINICIAR EL TIMER0 -----------    
reinicio_TMR0:		   
    movlw   207	    ;Mover la literal (207) a W
    movwf   TMR0    ;Mover W a F
    bcf	    T0IF    ;El overflow se apaga
    return
    
;----------- Incrementar Contador -----------        
Incrementar:
    btfsc   PORTD, 0 
    goto    $-1		;Antirrebote
    incf    Contador    ;Incrementar 1
    movf    Contador,0  ;almacena valor de contador en W
    andlw   0x0F	;Realiza un AND entre W y K, al llegar a 15 el contador lo reseteara
    call    Display	;Llamar a sub rutina de la tabla de display
    movwf   PORTA	;Escribir en puerto A
    return
 
;----------- Decrementar Contador -----------   
Decrementar:
    btfsc   PORTD, 1 
    goto    $-1		;Antirrebote
    decf    Contador	;Decrementa 1
    movf    Contador,0  ;almacena valor de contador en W
    andlw   0x0F	;Realiza un AND entre W y K, al llegar a 15 el contador lo reseteara
    call    Display	;Llamar a sub rutina de la tabla de display
    movwf   PORTA	;Escribir en puerto A
    return
    
;----------- Tabla del display -----------      
Display:
    clrf    PCLATH
    bsf	    PCLATH,0
    addwf   PCL
    retlw 0x3F	;0
    retlw 0x06	;1
    retlw 0x5B	;2
    retlw 0x4F	;3
    retlw 0x66	;4
    retlw 0x6D	;5
    retlw 0x7D	;6
    retlw 0x07	;7
    retlw 0xFF	;8
    retlw 0x6F	;9
    retlw 0x77	;A
    retlw 0x7C	;B
    retlw 0x39	;C
    retlw 0x5E	;D
    retlw 0x79	;E
    retlw 0x71	;F
  
;----------- Contador binario de 1 segundo -----------   
Contador_1seg:
    movf    Contador_1s,0	;Se mueve a W el valor de contador_1s
    sublw   10			;Se resta 10
    btfss   STATUS,2		;Se lee el valor de la bandera Z del Status
    goto    Else_If		;Si el resultado de la bandera Z no es 1, Salta la sub rutina de incrementar el contador de 1s
    incf    PORTC		;Incrementa Puerto C
    movf    PORTC,0		;Mueve valor de PORTC a W   
    andlw   0x0F		;Realiza un AND entre W y K, al llegar a 15 el contador lo reseteara
    movwf   PORTC		;Escribe en puerto C
    clrf    Contador_1s		;Limpia el contador de 1 segundo
    return
;----------- Else de if 1 segundo -----------       
Else_If: 
    incf    Contador_1s		;incrementar contador de 1 segundo
    return

;----------- Comparador de valores -----------       
Comparar:
    movf  PORTB,0		;Mover valor de PORTB a W
    subwf PORTC,0		;Se le resta PORTC a PORTB  
    btfsc STATUS,2		;Se lee el estatus de Z
    goto Led_On_Flag		;En caso de que Z=1 va a sub rutina bandera
    goto LED_Of_Flag		;Apaga la bandera de Valores iguales
    return    
	
;----------- Apaga led Bandera -----------   
LED_Of_Flag:
    bcf	PORTC,7			;Enciende led bandera
    return    
	
;----------- Enciende led Bandera y Limpiar puerto -----------   
Led_On_Flag:
    clrf PORTC			;Limpia Puerto C
    bsf PORTC,7			;Apaga led bandera
    return    
    
END

