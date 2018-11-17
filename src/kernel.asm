bits 16

org 0

;macro to check stack for threads params: 

SECTION .text
main:
	;jmp main

    mov ax, 0x13
    int 0x10

	mov ax, 0x800
	mov ds, ax

	mov     byte [task_status], 1               ; set main task to active

	lea     di, [task_a]                        ; create task a
	call    spawn_new_task

	lea     di, [task_b]                        ; create task b
	call    spawn_new_task

.loop_forever_main:                             ; have main print for eternity
	;lea     di, [task_main_str]
	;call    putstring
	call    yield                               ; we are done printing, let another task know they can print
	jmp     .loop_forever_main	
	; does not terminate or return

; di should contain the address of the function to run for a task
spawn_new_task:
	lea     bx, [stack_pointers]                ; get the location of the stack pointers
    add     bx, [current_task]                  ; get the location of the current stack pointer
	mov     [bx], sp                            ; save current stack so we can switch back
	mov     cx, [current_task]                  ; look for a new task 
	add     cx, 2                               ; start searching at the next one though
.sp_loop_for_available_stack:
	cmp     cx, [current_task]                  ; we are done when we get back to the original
	jne     .sp_check_if_available
	jmp     .sp_no_available_stack
.sp_check_if_available:
	lea     bx, [task_status]                   ; get status of this stack
	add     bx, cx                              
	cmp     word [bx], 0
	je      .sp_is_available
	add     cx, 2                               ; next stack to search
    and     cx, 0x2F                            ; make sure stack to search is always less than 64
	jmp     .sp_loop_for_available_stack
.sp_is_available:
	lea     bx, [task_status]                   ; we found a stack, set it to active
	add     bx, cx
	mov     word [bx], 1
	lea     bx, [stack_pointers]                ; switch to the fake stack so we can do stuff with it
	add     bx, cx
	mov     sp, [bx]                            ; swap stacks
	push    di                                  ; push address of function to run
	pusha                                       ; push registers
	pushf                                       ; push flags
	lea     bx, [stack_pointers]                ; update top of this stack
	add     bx, cx
	mov     [bx], sp
.sp_no_available_stack:                         ; restore to original stack
	lea     bx, [stack_pointers]
	add     bx, [current_task]
	mov     sp, [bx]
	ret

yield:
	pusha                                       ; push registers
	pushf                                       ; push flags
	lea     bx, [stack_pointers]                ; save current stack pointer
	add     bx, [current_task]
	mov     [bx], sp
	mov     cx, [current_task]                  ; look for a new task 
	add     cx, 2                               ; start searching at the next one though
.y_check_if_enabled:
	lea     bx, [task_status]
	add     bx, cx
	cmp     word [bx], 1
	je      .y_task_available
	add     cx, 2                               ; next stack to search
    and     cx, 0x2F                            ; make sure stack to search is always less than 64
	jmp     .y_check_if_enabled
.y_task_available:
	mov     bx, cx
	mov     [current_task], bx
	mov     bx, stack_pointers                  ; update stack pointer
	add     bx, [current_task]
	mov     sp, [bx]
	popf
	popa
	ret

task_a:
.loop_forever_1:
	;mov     ax, 0xA000
	;mov     es, ax
	;mov     cx, 0x0C8F            ; color
	;mov     [es:bx], cx

    mov ax, 0x0C8F
    mov bx, 0x0
	mov cx, [rect_a_x]
    mov dx, 0x0
    int 0x10

	inc word [rect_a_x]

	call    yield
	jmp     .loop_forever_1
	; does not terminate or return

task_b:
.loop_forever_2:
    mov ax, 0x0C73
    mov bx, 0x0
	mov cx, [rect_b_x]
    mov dx, 100
    int 0x10

	inc word [rect_b_x]

	call    yield
	jmp     .loop_forever_2
	; does not terminate or return

; takes a char to print in dx
; no return value
; putchar:
; 	mov     ax, dx          ; call interrupt x10 sub interrupt xE
; 	mov     ah, 0x0E
; 	mov     cx, 1
; 	int     0x10
; 	ret

;takes an address to write to in di
;writes to address until a newline is encountered
;returns nothing
; putstring:
; 	cmp     byte [di], 0        ; see if the current byte is a null terminator
; 	je     	.done 				; nope keep printing
; .continue:
; 	mov     dl, [di]            ; grab the next character of the string
; 	mov     dh, 0               ; print it
; 	call    putchar
; 	inc     di                  ; move to the next character
; 	jmp     putstring
; .done:
; 	ret

SECTION .data
	rect_a_x: dw 0
	rect_b_x: dw 0

	current_task: dw 0 ; must always be a multiple of 2
	stacks: times (256 * 4) db 0 ; 31 fake stacks of size 256 bytes
	task_status: times 5 dw 0 ; 0 means inactive, 1 means active
	stack_pointers: dw 0 ; the first pointer needs to be to the real stack !
                %assign i 1
                %rep    4
                    dw stacks + (256 * i)
                %assign i i+1
                %endrep
