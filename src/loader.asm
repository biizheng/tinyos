; 起始地址位于物理地址0x10000(1MB)处，
; 因为1MB以下的物理地址并不全是可用内存地址
org 10000h
    jmp Label_Loader_Start 
; 引入FAT12文件系统结构
%include "./include/fat12.inc"

; 内核程序起始物理地址基址  0x00
BaseOfKernelFile        equ 0x00

; 内核程序起始物理地址偏移地址  0x100000
OffsetOfKernelFile      equ 0x100000

; 内核程序临时转存空间基址
BaseTmpOfKernelAddr     equ 0x00

; 内核程序临时转存空间偏移地址
OffsetTmpOfKernelFile   equ 0x7E00


MemoryStructBufferAddr  equ 0x7E00

[SECTION gdt]

LABEL_GDT:          dd  0,0
LABEL_DESC_CODE32:  dd  0x0000FFFF,0x00CF9A00
LABEL_DESC_DATA32:  dd  0x0000FFFF,0x00CF9200

GdtLen  equ $ - LABEL_GDT
GdtPtr  dw  GdtLen - 1
        dd  LABEL_GDT

SelectorCode32  equ  LABEL_DESC_CODE32 - LABEL_GDT
SelectorData32  equ  LABEL_DESC_DATA32 - LABEL_GDT
; BITS伪指令可以告知编译器，下述代码将在16位宽的处理器上运行
; 
[SECTION .s16]
[BITS 16]
Label_Loader_Start:
    mov ax, cs 
    mov ds, ax
    mov es, ax
    mov ax,0x00
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
    
;   open address A20
;   开启A20地址线
    push ax
    ; 读入
    in al, 92h
    or al, 00000010b
    ; 输出
    out 92h,al 
    pop ax

    cli

    db 0x66
    lgdt [GdtPtr]

    mov eax, cr0
    or eax, 1
    mov cr0, eax

    mov ax, SelectorData32
    mov fs, ax
    mov eax, cr0
    and al,11111110b
    mov cr0, eax

    sti

    mov al, '#'
    call Func_Loader_PrintCharInAL

;=======  reset floppy
;=======  调用系统中断重置软盘

    xor ah, ah
    xor dl, dl
    int 13h

;=======  查找kernel.bin 
    mov word [SectorNo], SectorNumOfRootDirStart


Lable_Search_In_Root_Dir_Begin:

    mov al, '1'
    call Func_Loader_PrintCharInAL

    cmp word [RootDirSizeForLoop], 0
    jz Label_No_KernelBin
    dec word [RootDirSizeForLoop]  
    mov ax, 00h
    mov es, ax
    mov bx, 8000h
    mov ax, [SectorNo]
    mov cl, 1
    ;call Func_ReadOneSector
    mov si, KernelFileName
    mov di, 8000h
    cld
    mov dx, 10h

    jmp Label_Loader_Halt

;=======  在屏幕上打印 "ERROR:No KERNEL Found"
Label_No_KernelBin:

    mov ax, 1301h
    mov bx, 008Ch
    mov dx, 0300h ;row 3
    mov cx, 21
    push ax
    mov ax, ds
    mov es, ax
    pop ax 
    mov bp, NoKernelMessage
    int 10h
    jmp Label_Loader_Halt

Label_Loader_Halt:
    hlt
    jmp Label_Loader_Halt

;=======  打印寄存器‘AL’中字符
Func_Loader_PrintCharInAL:
    push bx
    push cx
    ; call int 10h,function num = 0x0e
    ; al = '.'
    ; bl = 字体前景色
    mov ah, 0eh
    mov bh, 00h
    mov bl, 0fh
    mov cx, 00h
    int 10h
    pop cx
    pop bx
    ret

;=======  临时变量

; 根目录所占扇区中待遍历扇区的个数，初始值：14
RootDirSizeForLoop dw RootDirSectors

;=======  display messages

;loader启动时打印的信息
StartLoaderMessage: db "Start Loader"

;kernel.bin 文件未找到时打印的信息
NoKernelMessage: db "ERROR:No KERNEL Found"

;内核文件在文件系统中的 DIR_Name
KernelFileName: db "KERNEL  BIN",0

;当前遍历的扇区号，初始值：0
SectorNo dw 0