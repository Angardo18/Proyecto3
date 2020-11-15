; TODO INSERT CONFIG CODE HERE USING CONFIG BITS GENERATOR

; PIC16F887 Configuration Bit Settings

; Assembly source line config statements

#include "p16f887.inc"

; CONFIG1
; __config 0x20D4
 __CONFIG _CONFIG1, _FOSC_INTRC_NOCLKOUT & _WDTE_OFF & _PWRTE_OFF & _MCLRE_OFF & _CP_OFF & _CPD_OFF & _BOREN_OFF & _IESO_OFF & _FCMEN_OFF & _LVP_OFF
; CONFIG2
; __config 0x3FFF
 __CONFIG _CONFIG2, _BOR4V_BOR40V & _WRT_OFF
 
 VALORTMR0 EQU .216
 PERIODO    EQU .125
 
 VARS UDATA
 ADC0 RES 1
 ADC1 RES 1
 ADC2 RES 1
 ADC3 RES 1  ;EN ESTAS VARIABLES SE ALMACENA EL VALOR DE LOS CANALES 0-3 DEL ADC
 CONTADOR_ADC RES 1 ;CONTADOR QUE INDICA QUE CANAL SE ESTA LEYENDO
 FLAGS RES 1
 W_RAM RES 1
 STATUS_RAM RES 1
 CONTADOR_PWM RES 1
 AJUSTE_PWM RES 1 ;VARIABLE QUE TENDRA EL VALOR AJUSTADO DEL PWM
 
 TRABAJO1 RES 1 ;ESTABLECE EL MOMENTO EN EL QUE SE COLOCA EN 0 EL VALOR PWM
 TRABAJO2 RES 1 ;LO MISMO QUE TRABAJO 1
 CONTADOR_TMR0 RES 1 
 
RES_VECT  CODE    0x0000            ; processor reset vector
    GOTO    START                   ; go to beginning of program

; TODO ADD INTERRUPTS HERE IF USED
INT_VECT    CODE 0x0004
    
SAVE:
    MOVWF   W_RAM
    SWAPF   STATUS,W
    MOVWF   STATUS_RAM
    
INT_ADC:
    BTFSC   PIR1, ADIF 
    GOTO    INT_TMR2
    
    BCF	PIR1, ADIF
    MOVF    CONTADOR_ADC,W
    ADDWF   PCL,F   
    GOTO    ES_ADC0
    GOTO    ES_ADC1
    GOTO    ES_ADC2
    GOTO    ES_ADC3
    CLRF    CONTADOR_ADC
    ES_ADC0
    MOVF    ADRESH, W
    MOVWF   ADC0
    BCF	ADCON0,CHS1
    BSF	ADCON0,CHS0 ;SE SELECCIONA EL CANAL 1
    GOTO FIN
    
    ES_ADC1
    MOVF    ADRESH, W
    MOVWF   ADC1
    BSF	ADCON0,CHS1
    BCF	ADCON0,CHS0 ;SE SELECCIONA EL CANAL 2
    GOTO FIN
   
    ES_ADC2
    MOVF    ADRESH,W
    MOVWF   ADC2
    BSF	ADCON0,CHS1
    BSF	ADCON0,CHS0 ;SE SELECCIONA EL CANAL 3
    GOTO FIN
    
    ES_ADC3
    MOVF    ADRESH,W
    MOVWF   ADC3
    BCF	ADCON0,CHS1
    BCF	ADCON0,CHS0 ;SE SELECCIONA CANAL 0
    
    FIN
    INCF    CONTADOR_ADC,F
    BSF	ADCON0,GO ;INICIA CONVERSION
    
INT_TMR2:
    BTFSC   PIR1,TMR2IF
    GOTO    LOAD
    
    BCF	PIR1, TMR2IF
    BSF	PORTC, RC0
    BSF	PORTC,RC3
    
LOAD:
    SWAPF   STATUS_RAM,W
    MOVWF   STATUS
    SWAPF   W_RAM,F
    SWAPF   W_RAM,W
    RETFIE
    

    
MAIN_PROG CODE                      ; let linker place main program
 
 START
    BSF	STATUS, IRP ;BANCO 2 Y 3 EN EL DIRECCIONAMIENTO INDIRECTO
    BSF	STATUS, RP1
    BSF	STATUS, RP0 ;BANCO 3
    
    MOVLW B'00001111'
    MOVWF ANSEL
    CLRF    ANSELH 
    
    
    
    BCF	STATUS,RP1 ;BANCO 1
    MOVLW   .255
    MOVWF   TRISA
    CLRF	   TRISC
    CLRF	   TRISD
    
    
    ;------------- INTERRUPCIONES -------------------------------------------------
    BSF	INTCON,GIE 
    BSF	INTCON, PEIE
    
    BSF	PIE1, ADIE ;INTERRUPCION ADC ACTIVADA
    BSF	PIE1, TMR2IE ;INTERRUPCION 
    ;---------------------------------------------------------------------------------------
    MOVLW .255 
    MOVWF  PR2 ;PERIODO DE  4.09 mS aproximadamente EN PWM
    CLRF    ADCON1 
    
    
    BCF	STATUS,RP0 ;BANCO 0
    
    MOVLW   B'00001100' 
    MOVWF   CCP1CON ;MODO DE PWM EN P1A LOS DEMAS SON PINES NORMALES 
    MOVWF   CCP2CON ;PWM TAMBIEN
    
    MOVLW   B'0000110' ;TMR2 ENCENDIDO CON PRESCALES DE 1:16 Y POST SCALER DE 1 
    MOVWF   T2CON
    
    MOVLW   B'01000001' ;ADC CON FOSC/8, CANAL 0 Y ENCENDIDO
    MOVWF   ADCON0
    
    CLRF    ADC0
    CLRF    ADC1
    CLRF    ADC2
    CLRF    ADC3
    CLRF    CONTADOR_ADC
    CLRF    FLAGS
    CLRF    CONTADOR_TMR0
    
    BSF	ADCON0, GO ;INICIA LA CONVERSION
    
LOOP:
    
    CALL PWM
    
    MOVLW   ADC0
    MOVWF   FSR ;VALOR DEL ADC PARA EL VALO
    
    CALL PWM
    CALL    VALOR_PWM
    MOVF    AJUSTE_PWM,W
    MOVWF   CCPR1L
    
    CALL PWM
    
    MOVLW    ADC1
    MOVWF   FSR
    
    CALL PWM
    
    CALL    VALOR_PWM
    MOVF    AJUSTE_PWM
    MOVWF   CCPR2L
    
    CALL PWM
    
    MOVLW   ADC2
    MOVWF   FSR
    
    CALL PWM
	
    CALL   VALOR_PWM
    MOVF    AJUSTE_PWM,W
    MOVWF TRABAJO1
    
    CALL PWM
	
    MOVLW   ADC3
    MOVWF   FSR
    
    CALL PWM
    
    CALL   VALOR_PWM
    MOVF    AJUSTE_PWM,W
    MOVWF TRABAJO2
    
    CALL PWM
    
    GOTO LOOP
    

PWM:
    BCF	INTCON, GIE
    MOVF    TRABAJO1,W
    SUBWF   TMR2, W ;TMR2 - TRABAJO  
    BTFSC   STATUS,C ;SI ESTE BIT ESTA EN 1 ESTO QUIERE DECIR QUE TMR2>= TRABAJO 
    BCF	PORTC, RC0; CON LO QUE SE COLOCA EN 0
    
    INCF    TRABAJO2, W
    SUBWF   TMR2, W
    BTFSC   STATUS, C ;LO MISMO QUE CON TRABAJO 1
    BCF	PORTC, RC3
    BSF	INTCON, GIE
    RETURN    
    

    
VALOR_PWM:
    ;ESTA FUNCION LO QUE REALIZARA ES AJUSTAR EL VALOR QUE SE ENCUENTRA EN LA DIRECCION A LA
    ;QUE APUNTA EL REGISTRO SFR A UN VALOR EN EL CUAL EL PWM DE SALIDA TENGA UN ANCHO MINIMO
    ;DE 0.5 mS Y UN MAXIMO DE 2.4mS PARA QUE SE PUEDE APROVECHAR TODO EL RANGO DEL SERVOMOTOR
    BCF	STATUS, IRP ;DIRECCIONAMIENTO INDIRECTO APUNTANDO A BANCOS 0 Y 1
    
    BCF	STATUS,C ;SE COLOCA EN 0 BIT C PARA QUE RRF FUNCIONE COMO UN SHIFT 
    RRF	INDF, W ;SE DIVIDE POR 2 EL VALOR QUEDANDO ENTRE UN RANGO DE 0 A 126
    ADDLW   .31 ;SE LE SUMA 31 PARA QUE EL RESULTADO QUEDE ENTRE 31 Y 157 LO QUE SE TRADUCE A UN
		;ANCHO DE PULSO DE ENTRE 0.496 mS y 2.512 mS ABARCANDO LOS ANCHOS NECESARIOS
		;PARA QUE EL SERVOMOTOR FUNCIONEN DE 0 A 180 GRADOS
   MOVWF    AJUSTE_PWM 
   BSF	STATUS, IRP ;SE VUELVE A APUNTAR A LOS BANCOS 2 Y 3 PARA LA EEPROM
   RETURN
    
    END