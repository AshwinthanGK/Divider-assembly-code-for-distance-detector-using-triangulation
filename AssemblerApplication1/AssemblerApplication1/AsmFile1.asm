FIXED_POINT_DIV:

    clr R23             ; Clear quotient
    tst R18             ; Check if divisor is zero
    breq DIV_BY_ZERO    ; Handle division by zero case

DIVIDE_LOOP:
    ;SUB_16_8:     
		cp R20, R18 
		brmi BORROW_OCCURRED	; Branch if negative (Borrow happened)
		sub R20,R18				; No borrow occurred, continue normal execution
        rjmp END

BORROW_OCCURRED:				; If borrow occurred, subtract 1 from R25 (high byte)
		cpi R21,0
        breq NO_OVERFLOW
		subi R21 , 1			; handling the high byte 

		sub R20,R18				; magnitude of the negative result 
		ldi R16,0x80			
		sub R20, R16			; Subtract from borrowed bit 10000000 
		mov R20 , R16			; Reuslt of low byte after subtraction
        


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
