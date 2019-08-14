.dseg 
.org	0x100

minutes:	.byte 1
seconds:	.byte 1

.cseg
.include "m169def.inc"
.org 0x1000
.include "print.inc"
.org	0

	  jmp init

init_time:
	
	  ldi r16, 0x00			; store 00:00 into memory
	  sts  minutes, r16
	  sts  seconds, r16
	  ret

print:						; print minutes and seconds
	  mov r16, r20
	  clr r18
	  cpi r16, 10
	  brlt div2
	  div: inc r18
	  subi r16,10
	  cpi r16,10
	  brsh div
	  div2:
	  subi r16, 0xD0	  
	  subi r18, 0xD0
	  ldi r17, 5
	  call show_char
	  mov r16, r18
	  ldi r17, 4
	  call show_char

	  mov r16, r21
	  clr r18
	  cpi r16, 10
	  brlt div3
	  div4: inc r18
	  subi r16, 10
	  cpi r16, 10
	  brsh div4
	  div3:
	  subi r16, 0xD0	  
	  subi r18, 0xD0
	  ldi r17, 7
	  call show_char
	  mov r16, r18
	  ldi r17, 6
	  call show_char	  
	  ret

pause:
	; wait approximately 1 second
	ldi 	r16, 25
	p3: ldi r17, 140
	  	p2: ldi r18, 190
	 	p1: dec r18
		brne p1
	  dec	r17
	  brne	p2
	dec r16
	brne p3
	ret

init:

	; init stack
	ldi r16, 0xFF
	out SPL, r16 
	ldi r16, 0x04
	out SPH, r16

	; init display
	call init_disp

	; init joystick
	in r17, DDRE
	andi r17, 0b11110011
	in r16, PORTE
	ori r16, 0b00001100
	out DDRE, r17
	out PORTE, r16
	ldi r16, 0b00000000
	sts DIDR1, r16
	in r17, DDRB
	andi r17, 0b00101111
	in r16, PORTB
	ori r16, 0b11010000
	out DDRB, r17
	out PORTB, r16

	call init_time

start:

	ldi r16, 0x01			; enable colons
	sts LCDDR0+8, r16
      
	ldi r16, '0'			; initialize leading zeros
	ldi r17, 2
	call show_char
	ldi r17, 3
	call show_char
		
	lds  r20, minutes		; load data from memory
	lds  r21, seconds
	
	call print 

loop:

	; read joystick position
	in 	 r16, PINE
	andi r16, 0b00001100  		
	in	 r17, PINB
	andi r17, 0b11010000
	add  r16, r17

	; wait a few milliseconds
	ldi r22, 30
	  s2: ldi r23, 255
	  s1: dec r23
	  brne s1
	dec	r22
	brne s2
	  
	in 	 r17, PINE
	andi r17, 0b00001100  		
	in	 r18, PINB
	andi r18, 0b11010000
	add  r17, r18

	cp  r16, r17

	breq loop

	sbis PINB,4			; ENTER
		rjmp   enter  
	sbis PINB,6			; UP
		rjmp   up    	
	sbis PINB,7			; DOWN
 		rjmp   down            
	sbis PINE,2			; LEFT
		rjmp   left
	sbis PINE,3			; RIGHT
		rjmp   right

	jmp loop

enter:
	sts  minutes, r20
	sts  seconds, r21
	jmp countdown

up:
	cpi r21, 59
	breq loop
	inc r21
	call print
	jmp loop

down:
	cpi r21, 0
	breq loop
	dec r21
	call print
	jmp loop

left:
	cpi r20, 0
	breq loop
	dec r20
	call print
	jmp loop

right:
	cpi r20, 59
	breq loop
	inc r20
	call print
	jmp loop

countdown:
	first:
	  cpi r21, 0
	  breq rest
	  call pause
	  dec r21
	  call print
	  rjmp first

	rest:
	  cpi r20, 0
	  breq end	
	  ldi r21, 59
	  dec r20
	  wait:
	  	call pause
	  	call print
	    dec r21
	  brne wait
	  call pause
	  call print
	  jmp rest	  	  
		
end:				; print final message and start over
	call pause

	ldi r16, 0x00
	sts LCDDR0+8, r16

	ldi r16, ' '
	ldi r17, 7
	call show_char

	ldi r16, 'M'
	ldi r17, 6
	call show_char

	ldi r16, 'O'
	ldi r17, 5
	call show_char

	ldi r16, 'O'
	ldi r17, 4
	call show_char

	ldi r16, 'B'
	ldi r17, 3
	call show_char

	ldi r16, ' '
	ldi r17, 2
	call show_char
	
	call pause
	call pause

	jmp start

