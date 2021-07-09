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
    ;cs  => 0x0000
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

    ; mov al, '#'
    ; call Func_Loader_PrintCharInAL

;=======  reset floppy
;=======  调用系统中断重置软盘

    xor ah, ah
    xor dl, dl
    int 13h

;=======  查找kernel.bin 
    mov word [SectorNo], SectorNumOfRootDirStart


Lable_Search_In_Root_Dir_Begin:

    ; mov al, '1'
    ; call Func_Loader_PrintCharInAL


    ;=======  回车，换行
    mov al, 0x0A
    call Func_Loader_PrintCharInAL
    mov al, 0x0A
    call Func_Loader_PrintCharInAL
    mov al, 0x0D
    call Func_Loader_PrintCharInAL


    cmp word [RootDirSizeForLoop], 0
    jz Label_No_KernelBin
    dec word [RootDirSizeForLoop]  

    ; 调用 Func_ReadOneSector ，从软盘中读取一个扇区，参数如下
    ; ax = [SectorNo]   待读入的山区编号
    ; cl = 1            读入的扇区数
    ; es:bx => 0x8000   扇区内数据的临时转存地址
    mov ax, 00h
    mov es, ax
    mov bx, 8000h
    mov ax, [SectorNo]
    mov cl, 1
    call Func_ReadOneSector
    
    mov al, '%'
    call Func_Loader_PrintCharInAL

    mov bp, 8000h
    call Func_PrintFileName

    mov al, '@'
    call Func_Loader_PrintCharInAL

    ; ds:si => 预先定义的文件名"KERNEL  BIN"
    ; es:di => 从硬盘读入的山区数据缓存区
    mov si, KernelFileName
    mov di, 8000h

    cld
    ; dx初始值为每个扇区可容纳的目录项个数
    ; (512/32 = 16 = 0x10)
    mov dx, 10h
;=======  对新载入内存的根目录扇区进行遍历,查找文件名与目标文件名相同的目录项
;           1.缓冲区内存地址 es:di => 8000h
;             预定义的文件名 ds:si => KernelFileName ("KERNEL  BIN") 
;           2.待遍历的目录项个数 dx(初始值为16)
Label_Search_For_KernelBin:
    ;若当前扇区的目录项遍历完后未发现目标文件
    ;则加载根目录的下一个扇区
    cmp dx, 0
    jz Label_Goto_Next_Sector_Of_Root_Dir
    dec dx
    ;文件名长度
    mov cx, 11
Label_Cmp_FileName:

    mov al, '.'
    call Func_Loader_PrintCharInAL

    cmp cx,	0
    jz Label_FileName_Found
    dec cx
    ;该指令从DS:SI寄存器指定的内存地址中读取一字节数据到AL寄存器
    lodsb
    cmp al, byte [es:di]
    jz Label_Go_On
    jmp Label_Different
Label_Go_On:
    ; 比较目录项下一位字符是否与"loader  bin"对应位置的字符相同
    inc di
    jmp Label_Cmp_FileName
Label_Different:
    ;取整
    and di,0ffe0h
    ;跳至下一个目录项
    add di,20h
    mov si, KernelFileName
    jmp Label_Search_For_KernelBin

;加载根目录占用的下一个扇区
Label_Goto_Next_Sector_Of_Root_Dir:
    add word [SectorNo], 1
    jmp Lable_Search_In_Root_Dir_Begin
    ;jmp Label_Halt

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
    jmp Func_Loader_Halt

;=======  found loader.bin name in root director struct
; 找到文件
Label_FileName_Found:

    mov ax, RootDirSectors
    and di, 0ffe0h
    add di, 01ah

    ; 目录项中文件的起始簇号
    mov cx, word [es:di]
    push cx
    add cx, ax
    add cx, SectorBalance

    ; ex:bx => 读取扇区的临时转存地址
    mov eax, BaseTmpOfKernelAddr
    mov es, eax
    mov bx, OffsetTmpOfKernelFile
    ; ax = kernel.bin起始扇区号
    mov ax, cx

Label_Go_On_Loading_File:

    ; es：bx => 0x7E00 
    mov cl, 1
    call Func_ReadOneSector

    ; ax => 目录项中文件的起始簇号
    pop ax
;;;;;;;;;;;;;;;;;;;;;;;	
    push cx
    push eax
    push fs
    push edi
    push ds
    push esi

    mov cx, 200h
    mov ax, BaseOfKernelFile
    mov fs, ax
    ;由于内核体积庞大必须逐个簇地读取和转存，每次转存内核程序片段时必须保存目标偏移值，
    ;该值（EDI寄存器）保存于临时变量OffsetOfKernelFileCount中。
    mov edi, dword [OffsetOfKernelFileCount]

    mov ax, BaseTmpOfKernelAddr
    mov ds, ax
    mov esi, OffsetTmpOfKernelFile
    
;------------------
Label_Mov_Kernel:
    ; use for eliminate vscode outline display bug, pointless
    xor al,al

    mov al,byte [ds:esi]
    mov byte [fs:edi], al

    inc esi
    inc edi

    loop Label_Mov_Kernel

    mov eax, 0x1000
    mov ds, eax

    mov dword [OffsetOfKernelFileCount], edi

    pop esi
    pop ds
    pop edi
    pop fs
    pop eax
    pop cx
;;;;;;;;;;;;;;;;;;;;;;;	

    call Func_GetFATEntry
    cmp ax, 0fffh
    jz Label_File_Loaded
    push ax
    mov dx, RootDirSectors
    add ax, dx
    add ax, SectorBalance
    add bx, [BPB_BytesPerSec]
    jmp Label_Go_On_Loading_File
Label_File_Loaded:
    mov	ax, 0B800h
    mov	gs, ax
    mov	ah, 8Fh				; 0000: 黑底    1111: 白字
    mov	al, 'G'
    mov	[gs:((80 * 0 + 39) * 2)], ax	; 屏幕第 0 行, 第 39 列。

KillMotor:

    push	dx
    mov	dx,	03F2h
    mov	al,	0	
    out	dx,	al
    pop	dx

    jmp Func_Loader_Halt

;=======  读入一个扇区
; 本函数对int13h中断的02号函数进行了封装，详见P46
; ax = 待读取的磁盘扇区起始号
; cl = 读入的扇区数量
; es:bx = 目标缓冲区起始地址
[SECTION .s16lib]
[BITS 16]
Func_ReadOneSector:
    push bp
    mov  bp,  sp
    ; 入栈cl
    sub  esp,  2
    mov  byte  [bp - 2],  cl
    push bx
    mov  bl,  [BPB_SecPerTrk]
    div  bl
    ; Sector 
    inc  ah
    mov  cl,  ah
    ; Head
    mov  dh,  al
    and  dh,  1
    ; Cylinder
    shr  al,  1
    mov  ch,  al

    pop	bx  
    mov	dl,	[BS_DrvNum]
Label_Go_On_Reading:
    mov ah, 2
    mov al, byte [bp - 2] ; byte[bp-2]： cl的值
    int 13h
    jc Label_Go_On_Reading
    add esp, 2  ;
    pop bp
    ret

Func_Loader_Halt:
    hlt
    jmp Func_Loader_Halt

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

;=======  打印载入的扇区中的文件名
Func_PrintFileName:
    push ax
    push bx
    push cx
    push dx

    mov dx, 0300h ;row 5
label_print_filename:

    cmp byte [es:bp], 0x00
    jz func_pfn_end
    mov ax, 1301h
    mov bx, 0007h
    mov cx, 11
    add dx, 0100h ;从第五行开始累加
    int 10h

    ;取整
    and bp,0ffe0h
    ;跳至下一个目录项
    add bp,20h
    mov al, ','
    call Func_Loader_PrintCharInAL
    loop label_print_filename

func_pfn_end:
    pop dx
    pop cx
    pop bx
    pop ax
    ret

;=======	get FAT Entry

Func_GetFATEntry:

    push es
    push bx
    push ax
    mov ax, 00
    mov es, ax
    pop ax
    mov byte [Odd], 0
    mov bx, 3
    mul bx
    mov bx, 2
    div bx
    cmp dx, 0
    jz Label_Even
    mov byte [Odd], 1

Label_Even:

    xor dx, dx
    mov bx, [BPB_BytesPerSec]
    div bx
    push dx
    mov bx, 8000h
    add ax, SectorNumOfFAT1Start
    mov cl, 2
    call Func_ReadOneSector

    pop dx
    add bx, dx
    mov ax, [es:bx]
    cmp byte [Odd], 1
    jnz Label_Even_2
    shr ax, 4

Label_Even_2:
    and ax, 0FFFh
    pop bx
    pop es
    ret

;=======  临时变量

; 根目录所占扇区中待遍历扇区的个数，初始值：14
RootDirSizeForLoop      dw   RootDirSectors
;当前遍历的扇区号，初始值：0
SectorNo    dw  0
Odd         db  0
;由于内核体积庞大必须逐个簇地读取和转存，每次转存内核程序片段时必须保存目标偏移值，
;该值（EDI寄存器）保存于临时变量OffsetOfKernelFileCount中。
OffsetOfKernelFileCount dd  OffsetOfKernelFile

;=======  display messages

;loader启动时打印的信息
StartLoaderMessage: db "Start Loader"

;kernel.bin 文件未找到时打印的信息
NoKernelMessage: db "ERROR:No KERNEL Found"

;内核文件在文件系统中的 DIR_Name : "KERNEL  BIN"
KernelFileName: db "KERNEL  BIN",0

