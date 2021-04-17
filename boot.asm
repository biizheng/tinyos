org 0x7c00

BaseOfStack equ 0x7c00

Label_Start:
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, BaseOfStack

;========== clear sreen ==========

    mov ax, 0600h
    mov bx, 0700h
    mov cx, 0
    mov dx, 0184fh
    int 10h
    
    jmp $

;==========  fill zero the rest of remaining sector with zero ==========

    times 510 - ( $ - $$ ) db 0
    ; dw 0xaa55
    db 0x55,0xaa
    
    

