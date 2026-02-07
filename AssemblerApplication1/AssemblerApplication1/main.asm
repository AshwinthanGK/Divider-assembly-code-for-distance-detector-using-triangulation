;
; AssemblerApplication1.asm
;
; Created: 05/02/2025 16:47:21
; Author : gkash
;


;
.include "m328pdef.inc"   ; Include ATmega328 definitions
.org 0x0000               ; Start at address 0x0000
 rjmp RESET                ; Reset vector

; Sine values scaled to 255 from sin 0 to sin pi



SineTable:
    .db 0, 4, 9, 13, 18, 22, 27, 31, 35, 40, 44, 49, 53, 57, 62, 66, 70, 75
    .db 79, 83, 87, 91, 96, 100, 104, 108, 112, 116, 120, 124, 128, 131, 135, 139, 143, 146
    .db 150, 153, 157, 160, 164, 167, 171, 174, 177, 180, 183, 186, 190, 192, 195, 198, 201, 204
    .db 206, 209, 211, 214, 216, 219, 221, 223, 225, 227, 229, 231, 233, 235, 236, 238, 240, 241
    .db 243, 244, 245, 246, 247, 248, 249, 250, 251, 252, 253, 253, 254, 254, 254, 255, 255, 255
    .db 255, 255, 255, 255, 254, 254, 254, 253, 253, 252, 251, 250, 249, 248, 247, 246, 245, 244
    .db 243, 241, 240, 238, 236, 235, 233, 231, 229, 227, 225, 223, 221, 219, 216, 214, 211, 209
    .db 206, 204, 201, 198, 195, 192, 190, 186, 183, 180, 177, 174, 171, 167, 164, 160, 157, 153
    .db 150, 146, 143, 139, 135, 131, 128, 124, 120, 116, 112, 108, 104, 100, 96, 91, 87, 83
    .db 79, 75, 70, 66, 62, 57, 53, 49, 44, 40, 35, 31, 27, 22, 18, 13, 9, 4
    .db 0,0

Reset:
ldi r27 , 100
    ldi r16, low(RAMEND)      ; Initialize stack pointer
    out SPL, r16
    ldi r16, high(RAMEND)
    out SPH, r16

	; Configure ports for servo control
    sbi   DDRB, 3         ; Set PB3 as output (Servo control)

	ldi r25 , 60	;theta1
	ldi r26 , 60	;theta2



    mov r16, r25                ; Load angle in degrees into r16
    rcall ComputeSin		 ;sin theta1
    mov R19,R16

    mov r16, r26              ; Load angle in degrees into r16
    rcall ComputeSin         ;   sin theta2
    mov R18,R16

	mov r16, r25  
    mov R10,R16            ; Load angle in degrees into r16
    rcall ComputeCos		 ;cos theta1
    mov R14,R16

	 
    mov r16, r26              ; Load angle in degrees into r16
    mov R9, R16            ; Load angle in degrees into r16
    rcall ComputeCos
    mov R17,R16				; costheta2

    rcall COMPUTE_EXPRESSION

    rjmp Reset

; Compute Sine Subroutine
; Input: r16 = angle (0-180)
; Output: r16 = sine value mapped 0 --> 1 as 1 --> 255
ComputeSin:
    ldi r30, low(SineTable)   ; Load low byte of table address into Z pointer
    ldi r31, high(SineTable)  ; Load high byte of table address into Z pointer
    ldi r17, 1
    add r16, r17
    add r30, r16                ; Increment Z-register to point to the next byte
    lpm r16, Z                ; Load the next byte into r16
    ret

; Compute cos Subroutine
; Input: r16 = angle (0-180)
; Output: r16
ComputeCos:
	mov r17, r16
	subi r17, 90
	brmi CosAngleLess90 ; Branch if r16 < 90
	rjmp CosAngleGreater90

; subrutine cos angle less than 90
CosAngleLess90:
    ldi r17, 91              
    sub r17 , r16
    ldi r30, low(SineTable)   ; Load low byte of table address into Z pointer
    ldi r31, high(SineTable)  ; Load high byte of table address into Z pointer
    add r30, r17            ; Add index (angle) to Z register
    lpm r16, Z              ; Load sine value from table into r17
	ret

; subrutine cos angle greater than or equal 90
CosAngleGreater90:
    ldi r17, 89               ; load angle in degrees into r17
    sub r16 , r17
    ldi r30, low(SineTable)   ; Load low byte of table address into Z pointer
    ldi r31, high(SineTable)  ; Load high byte of table address into Z pointer
    add r30, r16            ; Add index (angle) to Z register
    lpm r16, Z              ; Load sine value from table into r17
	ret

COMPUTE_EXPRESSION:

    ; Multiply sin(?1) * cos(?2) (8-bit * 8-bit = 16-bit result)
    mul R19, R17
    mov R20, R0              ; Store lower byte
    mov R21, R1            ; Store higher byte
                        
    ; Fixed-point division: (sin(?1) * cos(?2)) / sin(?2)
    
    call FIXED_POINT_DIV     ; Call division subroutine
	
	cpi r25 , 90;
	breq Both_positive
	brmi check_other
	rjmp Theta1_neg

	check_other:
		cpi r26 , 90
		breq Both_positive
		brmi Both_positive
		rjmp Theta2_neg

Both_positive:
	ADD R23, R14		;adding cos(theta1) &  and rest
	ldi R16,0x00     ; Add the 8-bit number to the low byte
    ADC R22, R16       ; Add carry to the high byte (R16 is assumed to be zero
	ldi R16,255
	mul r27,R16
	mov R18,R0 
	mov R17,R1
	rjmp DIVIDE_LOOP2
Theta1_neg:
	sub R23,R14
	ldi R16,0
	sbc R22, R16
	ldi R16,255
	mul r27,R16
	mov R18,R0 
	mov R17,R1
	rjmp DIVIDE_LOOP2

Theta2_neg:
	ldi R16,0
	sub R14,R23
	;sbc R16 , R22
	mov R23,R14
	mov R22,R16
    ldi R16,255
	mul r27,R16
	mov R18,R0 
	mov R17,R1	
	rjmp DIVIDE_LOOP2


; 16-bit by 16-bit Division Routine
; Inputs:
;   R17:R18 - Dividend (16-bit number to be divided)
;   R22:R23 - Divisor  (16-bit number to divide by)
; Outputs:
;   R17:R18 - Quotient (result of division)
;   R19:R20 - Remainder


DIVIDE_LOOP2:
    ; Clear remainder registers
    clr r19
    clr r20
    
    ; Initialize counter to 16 (number of bits)
    ldi r21, 16

division_loop:
    ; Shift left the dividend/quotient (R17:R18) into remainder (R19:R20)
    lsl r18        ; Shift left dividend low byte
    rol r17        ; Shift left dividend high byte with carry
    rol r20        ; Shift carry into remainder low byte
    rol r19        ; Shift carry into remainder high byte
    
    ; Compare remainder with divisor
    cp r20, r23    ; Compare low bytes
    cpc r19, r22   ; Compare high bytes with carry
    brlo skip_sub  ; Branch if remainder < divisor
    
    ; Subtract divisor from remainder
    sub r20, r23   ; Subtract low byte
    sbc r19, r22   ; Subtract high byte with carry
    
    ; Set least significant bit in result
    inc r18        ; Set bit 0 in quotient
    
skip_sub:
    ; Decrement counter and check if done
    dec r21
    brne division_loop

	rjmp END1
    ; out put in R16 : R17
	

    ; Division subroutine (R21_R20 = dividend, R18 = divisor, result stored in R23)
FIXED_POINT_DIV:

    clr R23             ; Clear quotient
    tst R18             ; Check if divisor is zero
    breq DIV_BY_ZERO    ; Handle division by zero case

DIVIDE_LOOP:
    ;SUB_16_8:     
		cp R20, R18 
		brlo BORROW_OCCURRED	; Branch if negative (Borrow happened)
		sub R20,R18				; No borrow occurred, continue normal execution
        rjmp END

BORROW_OCCURRED:				; If borrow occurred, subtract 1 from R25 (high byte)
		cpi R21,0
        breq NO_OVERFLOW
		subi R21 , 1			; handling the high byte 

		sub R20,R18				; magnitude of the negative result 
		;ldi R16,0x80			
		;sub R16 , R20			; Subtract from borrowed bit 10000000 
		;mov R20 , R16			; Reuslt of low byte after subtraction
        


END:
        inc R23					;(low byte of quotient)
        brne RESTART			;Checking for overflow, if not restart loop      
        inc R22					;increment high byte in case of overflow

RESTART:
		rjmp DIVIDE_LOOP
	 
NO_OVERFLOW:
   
        ret

DIV_BY_ZERO :
	ldi R22,0xFF
	ldi R23,0xFF
	ret

END1:
	;print***********

