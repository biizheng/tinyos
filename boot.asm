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

;==========  set fcous  ==========

    mov ax, 0200h
    mov bx, 0000h
    mov dx, 0000h
    int 10h

;==========  display on screen :Strat Booting ... --bizheng  ==========

    mov ax, 1301h
    mov bx, 000fh
    mov dx, 0000h
    ; cx <= count of characters of the string you want to display
    mov cx, 23
    push ax
    mov ax, ds
    mov es, ax
    pop ax
    mov bp, StartBootMessage
    int 10h

;==========  reset floppy  ==========

    xor ah, ah
    xor dl, dl
    int 13h

    jmp $

StartBootMessage: db "Start Booting --bizheng"

;==========  fill the rest of remaining sector with zero ==========

    times 510 - ( $ - $$ ) db 0
    ; dw 0xaa55
    db 0x55,0xaa
    

