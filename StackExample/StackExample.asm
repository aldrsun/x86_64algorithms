global _start

section .data
	initial_message db "-- Usage --", 10, "Available Commands:", 10, "push <number>", 10, "pop", 10, "sum", 10, "<Ctrl + C> to exit", 10, 0
	initial_message_length equ $ - initial_message
	cursor db "> ", 0
	counter dq 0

section .bss
	input resb 32	;reserve 256 bytes
	buffer resb 256
	temp_buffer resb 32 ; for local uses

section .text

_start:
	mov rax, 1
	mov rdi, 1
	lea rsi, initial_message
	mov rdx, initial_message_length
	syscall

.inputLoop:

	mov rax, 1
	mov rdi, 1
	lea rsi, cursor
	mov rdx, 3
	syscall

	mov rax, 0
	mov rdi, 0
	lea rsi, input
	mov rdx, 32
	syscall

	mov rax, input
	call .handleCommands
	 
jmp .inputLoop

.exitSuccess:
	mov rax, 60
	mov rdi, 0
	syscall

.handleCommands:
	mov rsi, rax
	push rsi
	call .getLength ; rax is the length count now
	pop rsi
	
	.checkExit:
		cmp rax, 4
		jnz .checkPush
		cmp BYTE [rsi], 'e'
		jnz .checkPush
		cmp BYTE [rsi + 1], 'x'
		jnz .checkPush
		cmp BYTE [rsi + 2], 'i'
		jnz .checkPush
		cmp BYTE [rsi + 3], 't'
		jnz .checkPush
		
		jmp .exitSuccess
		
	.checkPush:
		cmp rax, 5
		jl .checkPop	
		cmp BYTE [rsi], 'p'
		jnz .checkPop
		cmp BYTE [rsi + 1], 'u'
		jnz .checkPop
		cmp BYTE [rsi + 2], 's'
		jnz .checkPop
		cmp BYTE [rsi + 3], 'h'
		jnz .checkPop
		cmp BYTE [rsi + 4], ' '
		jnz .checkPop

		add rsi, 5
		mov rdi, rsi
		call .atoiMax255
		

		mov rbx, [counter]	
		mov BYTE [buffer + rbx], al
		inc rbx
		mov [counter], rbx	

		ret

	.checkPop:
		cmp rax, 3
		jnz .checkSum
		cmp BYTE [rsi], 'p'
		jnz .checkSum
		cmp BYTE [rsi + 1], 'o'
		jnz .checkSum
		cmp BYTE [rsi + 2], 'p'
		jnz .checkSum

		;check if [counter] == 0
		cmp BYTE [counter], 0
		je .checkPopCounterCheckNotOK
		mov rbx, [counter]
		dec rbx
		movzx rax, BYTE [buffer + rbx]
		jmp .checkPopCounterCheckOKEnd
		.checkPopCounterCheckNotOK:
		mov rax, 0
		.checkPopCounterCheckOKEnd:
		mov rsi, temp_buffer
		call .itoa
		mov [counter], rbx

		mov BYTE [temp_buffer + rax], 10
		add rax, 1

		mov rdx, rax
		mov rax, 1
		mov rdi, 1
		mov rsi, temp_buffer
		syscall
		ret

	.checkSum:
		cmp rax, 3
		jnz .handleCommandsEnd
		cmp BYTE [rsi], 's'
		jnz .handleCommandsEnd
		cmp BYTE [rsi + 1], 'u'
		jnz .handleCommandsEnd
		cmp BYTE [rsi + 2], 'm'
		jnz .handleCommandsEnd
	
		mov rax, 0 ; sum value
		mov rbx, [counter]
		.sumLoop:
			cmp rbx, 0
			jl .sumLoopEnd
			dec rbx
			movzx rcx, BYTE [buffer + rbx]
			add rax, rcx
			jmp .sumLoop
		.sumLoopEnd:

		mov rsi, temp_buffer
		call .itoa

		mov BYTE [temp_buffer + rax], 10	
		add rax, 1

		mov rdx, rax
		mov rax, 1
		mov rdi, 1
		mov rsi, temp_buffer
		syscall
		ret

	.handleCommandsEnd:
	ret

.atoiMax255:
	mov rdx, rdi 	; char buffer
	
	mov rax, 0 	; will store return value
	mov rdi, 0	; loop index
	.atoiMax255Loop:
		movzx rcx, BYTE [rdx + rdi]
		sub rcx, '0'
		js .atoiMax255Return
		imul rax, 10
		add rax, rcx
		;check if it exceeds 255
		cmp rax, 255
		jle .atoiMax255CheckOK
		mov rax, 0
		ret
		.atoiMax255CheckOK:
		inc rdi
		jmp .atoiMax255Loop
	.atoiMax255Return:
		ret

.itoa:
	mov rdi, rax	; input integer
	mov r9, 0	; counter
	cmp rax, 0
	jne .itoaCalculateLengthLoop
	mov r9, 1
	jmp .itoaCalculateLengthEnd
	.itoaCalculateLengthLoop:
		cmp rax, 0
		jz .itoaCalculateLengthEnd
		mov rcx, 10
		xor rdx, rdx
		div rcx
		inc r9
		jmp .itoaCalculateLengthLoop
	.itoaCalculateLengthEnd:

	mov r10, 0

	.itoaLoop:
		xor rdx, rdx
		mov rcx, 10
		mov rax, rdi
		div rcx
		mov rdi, rax
		mov rax, rdx
		add rax, '0'
		mov r11, r9
		sub r11, r10
		sub r11, 1
		mov [rsi + r11], al
		inc r10
		cmp rdi, 0
		je .itoaReturn
		jmp .itoaLoop
	.itoaReturn:
	mov rax, r9 ; character count
	ret

.getLength:
	mov rdx, 0
	.getLengthLoop:
		mov sil, BYTE [rax + rdx]
		cmp sil, 0
		je .getLengthReturn
		cmp sil, 10
		je .getLengthReturn
		inc rdx
		jmp .getLengthLoop
	.getLengthReturn:
		mov rax, rdx
		ret
