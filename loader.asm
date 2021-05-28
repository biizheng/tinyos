org 10000h
    mov ax, cs 
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7c00

;=======  在屏幕上打印字符串：”Start Loader .....“
;=======  display message on screen : Start Loader .....

    mov ax, 1301h   
    mov bx, 000fh   ;color
    mov cx, 12      ;length of string
    mov dx, 0200h   ;row 2

    push ax
    mov ax, ds
    mov es, ax
    pop ax
    mov bp, StartLoaderMessage

    int 10h

Halt:
    hlt
    jmp Halt

;=======  loader启动时打印的信息
StartLoaderMessage: db "Start Loader"