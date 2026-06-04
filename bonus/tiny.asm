BITS 64
ORG 0x400000

; ── ELF64 Header (64 bytes) ──────────────────────────────────────
db 0x7f, 0x45, 0x4c, 0x46   ; ELF magic
db 2, 1, 1, 0               ; 64-bit, little-endian, v1, SYSV ABI
dq 0                        ; padding
dw 2                        ; ET_EXEC
dw 0x3e                     ; EM_X86_64
dd 1                        ; version
dq _start                   ; e_entry
dq 0x40                     ; e_phoff (program header at offset 64)
dq 0                        ; e_shoff (no section headers)
dd 0                        ; e_flags
dw 64                       ; e_ehsize
dw 56                       ; e_phentsize
dw 1                        ; e_phnum
dw 64                       ; e_shentsize
dw 0                        ; e_shnum
dw 0                        ; e_shstrndx

; ── ELF64 Program Header (56 bytes) ──────────────────────────────
dd 1                        ; PT_LOAD
dd 5                        ; PF_R | PF_X
dq 0                        ; p_offset
dq 0x400000                 ; p_vaddr
dq 0x400000                 ; p_paddr
dq _end - $$                ; p_filesz
dq _end - $$                ; p_memsz
dq 0x200000                 ; p_align

; ── Code (entry at offset 0x78) ──────────────────────────────────
_start:
    xor ebp, ebp            ; counter = 0

.loop:
    ; Write newline sentinel one byte past the last digit slot.
    ; We use [rsp+7..rsp+11] as the digit buffer and [rsp+11] = '\n'.
    mov byte [rsp+11], 0x0a
    lea rdi, [rsp+11]       ; rdi -> byte just past digit area
    mov eax, ebp            ; number to convert
    push 10
    pop rsi                 ; esi = 10 (divisor, balanced push/pop)

.cvt:
    xor edx, edx            ; clear high half before division
    div esi                 ; eax /= 10,  edx = eax % 10
    add dl, 0x30            ; digit → ASCII
    dec rdi
    mov [rdi], dl           ; store digit going right-to-left
    test eax, eax
    jnz .cvt               ; more digits?

    ; rdi → first digit char;  [rsp+11] = '\n'
    lea rdx, [rsp+12]       ; one past newline
    sub rdx, rdi            ; rdx = total length (digits + newline)
    mov rsi, rdi            ; rsi = string start  (save before clobbering rdi)
    push 1
    pop rax                 ; rax = 1  (SYS_WRITE)
    push 1
    pop rdi                 ; rdi = 1  (STDOUT)
    syscall

    inc ebp
    cmp ebp, 10001          ; printed 0..10000 yet?
    jl .loop

    push 60
    pop rax                 ; rax = 60 (SYS_EXIT)
    xor edi, edi
    syscall

_end:
