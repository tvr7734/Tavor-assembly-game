;------------------------------------------
; PURPOSE : Test number 1 
; SYSTEM  : Turbo Assembler Ideal Mode  
; AUTHOR  :  
;------------------------------------------

IDEAL
		
MODEL small

STACK 100h

DATASEG
    dot_size dw 04h
    ;x dw 7fh
    ;y dw 79h
    color db 02h
    cotx dw 00h
    coty dw 0c8h
    ud dw 1
    cot_size dw 04h
    xxx dw 2h
    time_aux db 0
    WINDOW_WIDTH DW 140h 
	WINDOW_HEIGHT DW 0c8h
    ballx dw 7fh
    bally dw 79h
    dotx dw 0eh + 7fh
    doty dw 0eh + 79h
    holex dw 0Ah
    holey dw 0Ah
    ball_size dw 08h ;ball size in pixels
    hole_size dw 07h
    ballxspeed dw 1h
    ballyspeed dw 1h
    filename db 'gg.bmp',0
    filehandle dw ?
    Header db 54 dup (0)
    Palette db 256*4 dup (0)
    ScrLine db 320 dup (0)
    ErrorMsg db 'Error', 13, 10,'$'
		
CODESEG
    Start: 
    mov ax, @data
    mov ds, ax
    ; Graphic mode
    mov ax, 13h
    int 10h
        call OpenFile
        call ReadHeader
        call ReadPalette
        call CopyPal
        call CopyBitmap
        CHECK_TIME:
            MOV AH,2Ch 					 ;get the system time
			INT 21h    					 ;CH = hour CL = minute DH = second DL = 1/100 seconds
			
			CMP DL, TIME_AUX  			 ;is the current time equal to the previous one(TIME_AUX)?
			JE CHECK_TIME
            mov TIME_AUX, dl

        CHECK_KP:
            mov ah, 01h
            int 16h
            ;jmp CHECK_A
        CHECK_SPACE:
            mov ah, 00h
            int 16h
            cmp al, 20h
            JE srt_mov
            ;jmp CHECK_KP
        CHECK_A:
            mov ah, 00h
            int 16h
            cmp al, 61h
            JE left
			cmp al, 41h
			je left
        CHECK_D:
            cmp al, 64h
			je right
			cmp al, 44h
			je right
			;jmp CHECK_TIME
        CHECK_S:
            mov ah, 00h
            int 16h
            cmp al, 73h
            JE spdm
			cmp al, 53h
			je spdm
        CHECK_W:
            cmp al, 77h
			je spdp
			cmp al, 57h
			je spdp
			jmp CHECK_TIME
        right:
            call clear_screen
            call drawball
            call move_dot_r
            call drawdot
            jmp CHECK_TIME
        	
		left:
            call clear_screen
            call drawball
            call move_dot_l
            call drawdot
            jmp CHECK_TIME

        spdp:
			call drawcot
			call move_cot
			jmp CHECK_TIME
		spdm:
			call drawot
			call move_ot
			jmp CHECK_TIME

        srt_mov:
            mov ax, dotx
            sub ax, ballx
            ;div [xxx]
            mov [ballxspeed], ax
            mov ax, doty
            sub ax, bally
            ;div [xxx]
            mov [ballyspeed], ax
            ;cmp color, 0ah
            ;je lightg
            ;cmp color,0eh
            ;je ylw
            ;cmp color,70h
            ;je orng
            ;cmp color,2ah
            ;je lightr
            ;cmp color,04h
            ;je darkr
            jmp next
            ;lightg:
			;	mov ax, [ballxspeed]
              ;  mul ax, 2
              ;  mov [ballxspeed], ax
             ;   mov ax, [ballyspeed]
              ;  mul ax, 2
                ;mov [ballyspeed], ax
				;jmp next
			;ylw:
			;	mov ax, [ballxspeed]
              ;  mul ax, 3
              ;  mov [ballxspeed], ax
             ;   mov ax, [ballyspeed]
              ;  mul ax, 3
             ;   mov [ballyspeed], ax
				;jmp next
			;orng:
			;	mov ax, [ballxspeed]
              ;  mul ax, 4
              ;  mov [ballxspeed], ax
               ; mov ax, [ballyspeed]
              ;  mul ax, 4
              ;;  mov [ballyspeed], ax
				;jmp next
			;lightr:
				;mov ax, [ballxspeed]
               ; mul ax, 5
              ;  mov [ballxspeed], ax
               ; mov ax, [ballyspeed]
               ; mul ax, 5
               ; mov [ballyspeed], ax
				;jmp next
			;darkr:
				;mov ax, [ballxspeed]
                ;mul ax, 6
                ;mov [ballxspeed], ax
                ;mov ax, [ballyspeed]
                ;mul ax, 6
                ;mov [ballyspeed], ax
				
        next:
        CHECK_TIME2:
            MOV AH,2Ch 					 ;get the system time
			INT 21h    					 ;CH = hour CL = minute DH = second DL = 1/100 seconds
			
			CMP DL, TIME_AUX  			 ;is the current time equal to the previous one(TIME_AUX)?
			JE CHECK_TIME2
            mov TIME_AUX, dl
            call clear_screen
            call move_ball
            call drawball
            jmp next
        
        PROC greenscreen 
            mov ax,0A000h
            mov es,ax ;ES points to the video memory.
            mov dx,03C4h ;dx = indexregister
            mov ax,0202h ;INDEX = MASK MAP, 
            out dx,ax ;write all the bitplanes.
            mov di,0 ;DI pointer in the video memory.
            mov cx,38400 ;(640 * 480)/8 = 38400
            mov ax,0ffffh ;write to every pixel.
            rep stosb ;fill the screen
            ret
        ENDP greenscreen 

        PROC clear_screen
			MOV AH,00h                   ;set the configuration to video mode
			MOV AL,13h                   ;choose the video mode
			INT 10h    					 ;execute the configuration 
		
			MOV AH,0Bh 					 ;set the configuration
			MOV BH,00h 					 ;to the background color
			MOV BL,00h 					 ;choose black as background color
			INT 10h    					 ;execute the configuration
			
			RET
        ENDP clear_screen

        PROC drawball
            xor ax, ax
            xor bh, 0h
            mov cx, [ballx]
            mov dx, [bally]

		    DRAW_BALL_HORIZONTAL:
                mov ah, 0ch
                mov al, 0fh
                mov bh, 00h
                int 10h 
                inc cx
                MOV AX,CX          	  		 ;CX - BALL_X > BALL_SIZE (Y -> We go to the next line,N -> We continue to the next column
			    SUB AX, ballx
			    CMP AX, ball_size
			    JNG DRAW_BALL_HORIZONTAL    ;cx-ballx > ballsize
                
                MOV CX, ballx				 ;the CX register goes back to the initial column
			    INC DX       				 ;we advance one line
			    MOV AX,DX             		 ;DX - BALL_Y > BALL_SIZE (Y -> we exit this procedure,N -> we continue to the next line
			    SUB AX, bally
			    CMP AX, ball_size
			    JNG DRAW_BALL_HORIZONTAL
            ret
        ENDP drawball 

        PROC drawcot
            xor ax, ax
            mov bh, 0h
            mov cx, [cotx]
            mov dx, [coty]
			cmp coty, 21h
			je orng
			jl orng
			cmp coty, 42h
			je darkr
			jl darkr
			cmp coty, 63h
			je lightr
			jl lightr
			cmp coty, 84h
			je ylw
			jl ylw
			cmp coty, 0a5h
			je lightg
			jl lightg
			jmp DRAW_COT_HORIZONTAL
			lightg:
				mov [color], 0ah
				jmp DRAW_COT_HORIZONTAL
			ylw:
				mov [color], 0eh
				jmp DRAW_COT_HORIZONTAL
			orng:
				mov [color], 70h
				jmp DRAW_COT_HORIZONTAL
			lightr:
				mov [color], 2ah
				jmp DRAW_COT_HORIZONTAL
			darkr:
				mov [color], 04h

		    DRAW_COT_HORIZONTAL:
                mov ah, 0ch
                mov al, [color]
                mov bh, 00h
                int 10h 
                inc cx
                MOV AX,CX          	  		 ;CX - BALL_X > BALL_SIZE (Y -> We go to the next line,N -> We continue to the next column
			    SUB AX, cotx
			    CMP AX, cot_size
			    JNG DRAW_COT_HORIZONTAL      ;cx-ballx > ballsize
                
                MOV CX, cotx				 ;the CX register goes back to the initial column
			    INC DX       				 ;we advance one line
			    MOV AX,DX             		 ;DX - BALL_Y > BALL_SIZE (Y -> we exit this procedure,N -> we continue to the next line
			    SUB AX, coty
			    CMP AX, cot_size
			    JNG DRAW_COT_HORIZONTAL
            ret
        ENDP drawcot  

		PROC drawot
            xor ax, ax
            mov bh, 0h
            mov cx, [cotx]
            mov dx, [coty]

		    DRAW_OT_HORIZONTAL:
                mov ah, 0ch
                mov al, 0h
                mov bh, 00h
                int 10h 
                inc cx
                MOV AX,CX          	  		 ;CX - BALL_X > BALL_SIZE (Y -> We go to the next line,N -> We continue to the next column
			    SUB AX, cotx
			    CMP AX, cot_size
			    JNG DRAW_OT_HORIZONTAL      ;cx-ballx > ballsize
                
                MOV CX, cotx				 ;the CX register goes back to the initial column
			    INC DX       				 ;we advance one line
			    MOV AX,DX             		 ;DX - BALL_Y > BALL_SIZE (Y -> we exit this procedure,N -> we continue to the next line
			    SUB AX, coty
			    CMP AX, cot_size
			    JNG DRAW_OT_HORIZONTAL
            ret
        ENDP drawot  

		PROC move_cot
			cmp coty,0h
			je n
			dec coty
		n: 
			ret
        ENDP move_cot
		
		PROC move_ot
			cmp coty,0c8h
			je q
			inc coty
		q: 
			ret
        ENDP move_ot

 
        PROC drawhole 
            xor ax, ax
            xor bh, 0h
            mov cx, [holex]
            mov dx, [holey]

		    DRAW_HOLE_HORIZONTAL:
                mov ah, 0ch
                mov al, 00h
                mov bh, 01h
                int 10h 
                inc cx
                MOV AX,CX          	  		 ;CX - BALL_X > BALL_SIZE (Y -> We go to the next line,N -> We continue to the next column
			    SUB AX, holex
			    CMP AX, hole_size
			    JNG DRAW_HOLE_HORIZONTAL    ;cx-ballx > ballsize
                
                MOV CX, holex				 ;the CX register goes back to the initial column
			    INC DX       				 ;we advance one line
			    MOV AX,DX             		 ;DX - BALL_Y > BALL_SIZE (Y -> we exit this procedure,N -> we continue to the next line
			    SUB AX, holey
			    CMP AX, hole_size
			    JNG DRAW_HOLE_HORIZONTAL
            ret
        ENDP drawhole 
        PROC move_ball
            mov ax, ballxspeed
            add ballx, ax

            cmp ballx, 02h 
            jl negxspeed

            mov ax, WINDOW_WIDTH
            sub ax, ball_size
            sub ax, 10
            cmp ballx, ax
            JG negxspeed

            mov ax, ballyspeed
            add bally, ax
            
            cmp bally, 02h 
            jl negyspeed

            mov ax, WINDOW_HEIGHT
            sub ax, ball_size
            sub ax, 10
            cmp bally, ax
            JG negyspeed
            ret
            negxspeed:
                neg ballxspeed
                ret
            negyspeed:
                neg ballyspeed
                ret
        ENDP move_ball

        PROC drawdot
            xor ax, ax
            mov bh, 0h
            mov cx, [dotx]
            mov dx, [doty]

		    DRAW_DOT_HORIZONTAL:
                mov ah, 0ch
                mov al, 03h
                mov bh, 00h
                int 10h 
                inc cx
                MOV AX,CX          	  		 ;CX - BALL_X > BALL_SIZE (Y -> We go to the next line,N -> We continue to the next column
			    SUB AX, dotx
			    CMP AX, dot_size
			    JNG DRAW_DOT_HORIZONTAL      ;cx-ballx > ballsize
                
                MOV CX, dotx				 ;the CX register goes back to the initial column
			    INC DX       				 ;we advance one line
			    MOV AX,DX             		 ;DX - BALL_Y > BALL_SIZE (Y -> we exit this procedure,N -> we continue to the next line
			    SUB AX, doty
			    CMP AX, dot_size
			    JNG DRAW_DOT_HORIZONTAL
            ret
        ENDP drawdot  

		PROC move_dot_l
			
			mov ax, ballx
			cmp dotx, ax 
			JE comp1l
			JG comp2l
			jl comp3l

			comp1l:
				mov ax, bally
				cmp doty, ax
				jl rev1l
				jg rev3l

			comp2l:
				mov ax, bally
				cmp doty, ax
				JE rev4l
				jl rev4l
				jg rev3l

			comp3l:
				mov ax, bally
				cmp doty, ax
				je rev2l
				jg rev2l
				jl rev1l

			rev1l:
				inc doty
				sub dotx, 1
				ret

			rev2l:
				inc dotx
				inc doty
				ret

			rev3l:
				inc dotx
				sub doty, 1
				ret

			rev4l:
				sub dotx, 1
				sub doty, 1
				ret
            
        ENDP move_dot_l

		PROC move_dot_r
			
			mov ax, ballx
			cmp dotx, ax 
			JE comp1
			JG comp2
			jl comp3

			comp1:
				mov ax, bally
				cmp doty, ax
				jl rev4
				jg rev2

			comp2:
				mov ax, bally
				cmp doty, ax
				JE rev3
				jl rev4
				jg rev3

			comp3:
				mov ax, bally
				cmp doty, ax
				je rev1
				jg rev2
				jl rev1

			rev3:
				inc doty
				sub dotx, 1
				ret

			rev4:
				inc dotx
				inc doty
				ret

			rev1:
				inc dotx
				sub doty, 1
				ret

			rev2:
				sub dotx, 1
				sub doty, 1
				ret
            
        ENDP move_dot_r



















        proc OpenFile
        ; Open file
            mov ah, 3Dh
            xor al, al
            mov dx, offset filename
            int 21h
            jc openerror
            mov [filehandle], ax
            ret
        openerror:
            mov dx, offset ErrorMsg
            mov ah, 9h
            int 21h
            ret
        endp OpenFile
        proc ReadHeader
        ; Read BMP file header, 54 bytes
            mov ah,3fh
            mov bx, [filehandle]
            mov cx,54
            mov dx,offset Header
            int 21h
            ret
        endp ReadHeader
        proc ReadPalette
        ; Read BMP file color palette, 256 colors * 4 bytes (400h)
            mov ah,3fh
            mov cx,400h
            mov dx,offset Palette
            int 21h
            ret
        endp ReadPalette
        proc CopyPal
        ; Copy the colors palette to the video memory
        ; The number of the first color should be sent to port 3C8h
        ; The palette is sent to port 3C9h
            mov si,offset Palette
            mov cx,256
            mov dx,3C8h
            mov al,0
            ; Copy starting color to port 3C8h
            out dx,al
            ; Copy palette itself to port 3C9h
            inc dx
        PalLoop:
            ; Note: Colors in a BMP file are saved as BGR values rather than RGB.
            mov al,[si+2] ; Get red value.
            shr al,2 ; Max. is 255, but video palette maximal
            ; value is 63. Therefore dividing by 4.
            out dx,al ; Send it.
            mov al,[si+1] ; Get green value.
            shr al,2
            out dx,al ; Send it.
            mov al,[si] ; Get blue value.
            shr al,2
            out dx,al ; Send it.
            add si,4 ; Point to next color.
            ; (There is a null chr. after every color.
            loop PalLoop
            ret
        endp CopyPal
        proc CopyBitmap
        ; BMP graphics are saved upside-down.
        ; Read the graphic line by line (200 lines in VGA format),
        ; displaying the lines from bottom to top.
            mov ax, 0A000h
            mov es, ax
            mov cx,200
        PrintBMPLoop:
            push cx
            ; di = cx*320, point to the correct screen line
            mov di,cx
            shl cx,6
            shl di,8
            add di,cx
            ; Read one line
            mov ah,3fh
            mov cx,320
            mov dx,offset ScrLine
            int 21h
            ; Copy one line into video memory
            cld ; Clear direction flag, for movsb
            mov cx,320
            mov si,offset ScrLine
            rep movsb ; Copy line to the screen
            ;rep movsb is same as the following code:
            ;mov es:di, ds:si
            ;inc si
            ;inc di
            ;dec cx
            ;loop until cx=0
            pop cx
            loop PrintBMPLoop
            ret
        endp CopyBitmap
        mov ah, 00h
        int 16h
    Exit:
        mov ax, 4C00h
        int 21h
END start