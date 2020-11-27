#include "p16f887.inc"

; CONFIG1
; __config 0x20D4
 __CONFIG _CONFIG1, _FOSC_INTRC_NOCLKOUT & _WDTE_OFF & _PWRTE_OFF & _MCLRE_OFF & _CP_OFF & _CPD_OFF & _BOREN_OFF & _IESO_OFF & _FCMEN_OFF & _LVP_OFF
; CONFIG2
; __config 0x3FFF
 __CONFIG _CONFIG2, _BOR4V_BOR40V & _WRT_OFF

PR_VAR		    UDATA
;------------------------------------Generales-------------------------------------------
ANTIREB	    RES 1			;Boton
CONT1		    RES 1			;Delay
;-----------------------------------Operaciones------------------------------------------
CT1		    RES 1			;Ciclo de Trabajo 1, para ajustar el valor que va al TMR0.
ROTF		    RES 1			;Para la funcion de ajuste.
CICLO		    RES 1
;--------------------------------------ADC-----------------------------------------------
SERVO0	    RES 1
SERVO1		    RES 1
SERVO2	    RES 1			;Para mostrar el ciclo de trabajo de los PMW
CONT_ADC	    RES 1			;Para llevar  registro de que canal analogico toca.
;-----------------------------------Interrupcion------------------------------------------
TEMP_STATUS	    RES 1
TEMP_W	    RES 1
TEMP_FSR	    RES 1

RES_VECT  CODE    0x0000            ; processor reset vector
    GOTO    START                   ; go to beginning of program

;************************************Interrupcion********************************
ISR_VECT   CODE    0X0004
SAVE:					;Sirve para guardar el valor actual de:
    MOVWF	TEMP_W		;"W"
    SWAPF	STATUS, W
    MOVWF	TEMP_STATUS		;& STATUS
    SWAPF	FSR, W
    MOVWF	TEMP_FSR
ISR:
    BTFSS	INTCON,T0IF
     GOTO	ADC_INT
    BCF	INTCON,T0IF
    MOVF    CICLO,W
    ADDWF   PCL, F
    GOTO    INICIO_PERIODO ;este contador LLEVA EN CONTROL DE LA SECUENCIA PARA LA GENERACION PWM
    GOTO    PWM2

    CLRF    CICLO

    INICIO_PERIODO ;EN LA PRIMERA FASE SE COLOCA EN 1 EL PIN RC0 Y RC3 SE ENCUENTRA EN 0
    BSF	PORTC, RC0 ;SE COLOCA EN 1
    MOVF   CT1,W
    CLRF	TMR0
    SUBWF   TMR0,F  ;TMRO =  256 - TRABAJO1
    INCF    CICLO,F ;A LA SIGUIENTE ENTRADA SE EJECUTA PWM1
    GOTO  ADC_INT

PWM2
    BCF	PORTC,RC0
    CLRF	TMR0 ;LA SIGUIENTE INTERRUPCION OCURRIRA DENTRO DE 4.09mS
    INCF CICLO,F
;TMR0_INT:
;    BCF		INTCON,T0IF
;    MOVF		CICLO,W
;    ADDWF	PCL,F
;    GOTO		POSITIVO
;    GOTO		NEGATIVO
;    CLRF		CICLO
;POSITIVO:
;    BSF		PORTC, RC0
;    MOVF		CT1,W
;    CLRF		TMR0
;    SUBWF	TMR0,F
;    INCF		CICLO,F
;    GOTO		ADC_INT
;NEGATIVO:
;    BCF		PORTC, RC0
;    CLRF		TMR0
;    INCF		CICLO, F

ADC_INT:
    BTFSS	PIR1, ADIF
    GOTO		LOAD

    BCF		PIR1, ADIF
    MOVF		CONT_ADC, W
    ADDWF	PCL, F

    GOTO		SERVO0_ADC
    GOTO		SERVO1_ADC
    GOTO		SERVO2_ADC
    CLRF		CONT_ADC

SERVO0_ADC:
    MOVF    	ADRESH,W
    MOVWF	SERVO0
    BCF		ADCON0, CHS1
    BSF		ADCON0, CHS0		;Canal 1
    GOTO		INICIAR_CONV

SERVO1_ADC:
    MOVF    	ADRESH,W
    MOVWF	SERVO1
    BSF		ADCON0, CHS1
    BCF		ADCON0, CHS0		 ;Canal 2
    GOTO		INICIAR_CONV

SERVO2_ADC:
    MOVF		ADRESH,W
    MOVWF	SERVO2
    BCF		ADCON0, CHS1
    BCF		ADCON0, CHS0		;Canal 0

INICIAR_CONV:
    INCF		CONT_ADC, F
    BSF		ADCON0, GO

LOAD:					;Se recupera el valor de:
    SWAPF	TEMP_STATUS, W
    MOVWF	STATUS		;STATUS
    SWAPF	TEMP_FSR, W
    MOVWF	FSR
    SWAPF	TEMP_W, F
    SWAPF	TEMP_W, W		;& de "W"
    RETFIE
;-----------------------------------------------------------------------------------------
MAIN_PROG CODE			; let linker place main program
START
    BSF		 STATUS, 6
    BSF		STATUS, 5		;--------------------Banco 3----------------
    MOVLW	B'00000111'
    MOVWF	ANSEL			;Se habilita el analogico en A0, A1 & A2
    BCF		OPTION_REG, T0CS	;TMR0: Oscilador interno
    BCF		OPTION_REG, PSA	;Prescaler a TMR0
    BCF		OPTION_REG, PS2
    BSF		OPTION_REG, PS1
    BSF		OPTION_REG, PS0	;Prescaler de 1:16
    BCF		STATUS, 6		;-------------------Banco 1------------------
    MOVLW	.255
    MOVWF	TRISA			;Puerto A como entrada.
    CLRF		TRISC			;Salida: Señales PMW.
;----------------------------Configuración Timers----------------------------------------
    BSF		INTCON,GIE		;Habilita las interrupciones globales
    BSF		INTCON, PEIE		;& perifericas.

    BSF		PIE1, ADIE		;Interrupcion del ADC activa
     BSF		PIE1, RCIE		;Interrupcion del receptor EUSART
    ;---------------------------------------------------------------------------------------
    MOVLW	.255
    MOVWF	PR2			;Periodo de 4.09 mS aproximadamente en PWM
 ;----------------------------------  EUSART---------------------------------------------
;      BCF		TXSTA,TX9	                  ;Transmicion de 8 bits.
;     BSF		TXSTA, TXEN	                  ;Bit de transmicion activo.
;     BCF		TXSTA, SYNC	                  ;Modo Asincronico.
;     BSF		TXSTA, BRGH	                  ;Modo de alta velocidad.
;      MOVLW	.25		                  ;9615 de Baudrate
;     MOVWF	SPBRG
    CLRF		ADCON1
    BCF		STATUS, 5		;----------------BANCO 0-------------------
    BCF		INTCON, T0IF		;Se apaga la bandera
    CLRF		TMR0
    BSF		INTCON, T0IE		;Se habilita la interrrupcion del Timer 0.

    MOVLW	B'00001100'
    MOVWF	CCP1CON		;Modo de PWM en RC2
    MOVWF	CCP2CON		; & RC1.

    MOVLW	B'0000110'		;TMR2 encendido con prescales de 1:16
    MOVWF	T2CON			;& postcaler de 1

    MOVLW	B'01000001'		 ;ADC con FOSC/8, canal 0
    MOVWF	ADCON0		 ;& encendido.
;-------------------------------Limpiar variables/puertos--------------------------------
   CLRF		TEMP_STATUS
   CLRF		TEMP_W
   CLRF		SERVO0
   CLRF		SERVO1
   CLRF		SERVO2
   CLRF		CT1
   CLRF		CONT_ADC
   CLRF		ANTIREB
   CLRF		CONT1
   BSF		ADCON0, GO

LOOP:
    MOVLW    	SERVO0
    MOVWF	FSR
    CALL		AJUSTE_CT
    MOVF		ROTF, W
    MOVWF	CCPR1L

    MOVLW    	SERVO1
    MOVWF	FSR
    CALL		AJUSTE_CT
    MOVF		ROTF, W
    MOVWF	CCPR2L

     MOVLW    	SERVO2
    MOVWF	FSR
    CALL		AJUSTE_CT
    MOVF		ROTF, W
    MOVWF	CT1
    GOTO		LOOP
;--------------------------------------RUTINAS-----------------------------------------
AJUSTE_CT
    BCF		STATUS, IRP
    BCF		STATUS, C		;Se asegura que carry este en 0.
    RRF		INDF, W		;Se procede a rotar a la derecha para emular la division
					;ahora el valor esta entre 0 - 127.
    ADDLW	.31			;Se adiciona 97 para que el tiempo en el TRM0, este
    MOVWF	ROTF			;entre 0.512ms < t < 2.544ms.
    RETURN
DELAY_4US				;DELAY DE  4us (supuestamente)
    BCF		STATUS,5
    BCF		STATUS,6
    MOVLW	 .128
    MOVWF	CONT1
    DECFSZ	CONT1, F
    GOTO		$-1
   RETURN
    END