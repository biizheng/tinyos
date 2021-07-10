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

; 物理地址空间结构体数组地址
MemoryStructBufferAddr  equ 0x7E00

[SECTION gdt]

LABEL_GDT:          dd  0,0
LABEL_DESC_CODE32:  dd  0x0000FFFF,0x00CF9A00   ;基址 0x 0000 0000
LABEL_DESC_DATA32:  dd  0x0000FFFF,0x00CF9200   ;基址 0x 0000 0000

GdtLen  equ $ - LABEL_GDT
GdtPtr  dw  GdtLen - 1
        dd  LABEL_GDT

SelectorCode32  equ  LABEL_DESC_CODE32 - LABEL_GDT
SelectorData32  equ  LABEL_DESC_DATA32 - LABEL_GDT

[SECTION gdt64]

LABEL_GDT64:        dq  0x0000000000000000
LABEL_DESC_CODE64:  dq  0x0020980000000000
LABEL_DESC_DATA64:  dq  0x0000920000000000

GdtLen64    equ $ - LABEL_GDT64
GdtPtr64    dw  GdtLen64 - 1
            dd  LABEL_GDT64

SelectorCode64  equ   LABEL_DESC_CODE64 - LABEL_GDT64
SelectorData64  equ   LABEL_DESC_DATA64 - LABEL_GDT64

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
    ; mov al, 0x0A
    ; call Func_Loader_PrintCharInAL
    ; mov al, 0x0A
    ; call Func_Loader_PrintCharInAL
    ; mov al, 0x0D
    ; call Func_Loader_PrintCharInAL


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
    
    ; mov bp, 8000h
    ; call Func_PrintFileName

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

    ; mov al, '.'
    ; call Func_Loader_PrintCharInAL

    cmp cx, 0
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

    mov al, '+'
    call Func_Loader_PrintCharInAL

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
    mov ax, 0B800h
    mov gs, ax
    mov ah, 8Fh    ; 0000: 黑底    1111: 白字
    mov al, 'G'
    mov [gs:((80 * 0 + 39) * 2)], ax ; 屏幕第 0 行, 第 39 列。

KillMotor:

    push dx
    mov dx, 03F2h
    mov al, 0 
    out dx, al
    pop dx

;=======  get memory address size type

    ; 打印提示信息
    mov ax, 1301h
    mov bx, 000Fh
    mov dx, 0400h   ;row 4
    mov cx, 44
    push ax
    mov ax, ds
    mov es, ax
    pop ax
    mov bp, StartGetMemStructMessage
    int 10h

    ;在int 15h中断函数中，ebx用于确定下一个能够探测的内存区域，初始值需要设置为0
    mov ebx, 0
    ; es:di => 0x7e00
    mov ax, 0x00
    mov es, ax
    mov di, MemoryStructBufferAddr 
Label_Get_Mem_Struct:

    ; 借助int 15中断服务程序来获取物理地址空间信息
    ; 获取到的信息保存在0x7e00 地址处
    mov eax, 0x0E820
    mov ecx, 20
    mov edx, 0x534D4150
    int 15h
    ; 若内存信息获取失败，跳转至相应为位置
    ; 当没有发生错误时,CF=0,否则CF=1
    jc Label_Get_Mem_Fail
    add di, 20
    inc	dword [MemStructNumber]

    ;int 15h中断返回一个ebx，用于确定下一个能够探测的内存区域
    cmp ebx, 0
    jne Label_Get_Mem_Struct
    ;当ebx=0时，表示当前已经是最后一个内存区域了
    jmp Label_Get_Mem_OK
Label_Get_Mem_Fail:

    mov dword [MemStructNumber],0

    mov ax, 1301h
    mov bx, 008Ch
    mov dx, 0500h   ;row 5
    mov cx, 23
    push ax
    mov ax, ds
    mov es, ax
    pop ax
    mov bp, GetMemStructErrMessage
    int 10h
    jmp $
Label_Get_Mem_OK:
    mov ax, 1301h
    mov bx, 000Fh
    mov dx, 0600h   ;row 6
    mov cx, 29
    push ax
    mov ax, ds
    mov es, ax
    pop ax
    mov bp, GetMemStructOKMessage
    int 10h 

;======= get SVGA information
    mov ax, 1301h
    mov bx, 000Fh
    mov dx, 0800h   ;row 8
    mov cx, 23
    push ax
    mov ax, ds
    mov es, ax
    pop ax
    mov bp, StartGetSVGAVBEInfoMessage
    int 10h

    mov ax,  0x00
    mov es,  ax
    mov di,  0x8000
    mov ax,  4F00h
    int 10h

    cmp ax,  004Fh
    jz  .KO
;=======    Fail
    mov ax,  1301h
    mov bx,  008Ch
    mov dx,  0900h ;row 9
    mov cx,  23
    push    ax
    mov ax,  ds
    mov es,  ax
    pop ax
    mov bp,  GetSVGAVBEInfoErrMessage
    int 10h

    jmp $
.KO:
    mov ax, 1301h
    mov bx, 000Fh
    mov dx, 0A00h ;row 10
    mov cx, 29
    push ax
    mov ax, ds
    mov es, ax
    pop ax
    mov bp, GetSVGAVBEInfoOKMessage
    int 10h

;=======    Get SVGA Mode Info
    mov ax,  1301h
    mov bx,  000Fh
    mov dx,  0C00h ;row 12
    mov cx,  24
    push    ax
    mov ax,  ds
    mov es,  ax
    pop ax
    mov bp,  StartGetSVGAModeInfoMessage
    int 10h


    mov ax,  0x00
    mov es,  ax
    mov si,  0x800e

    mov esi, dword    [es:si]
    mov edi, 0x8200
Label_SVGA_Mode_Info_Get:

    mov cx,  word  [es:esi]

;=======    display SVGA mode information

    push    ax

    mov ax,  00h
    mov al,  ch
    call    Func_Loader_DispAL

    mov ax,  00h
    mov al,  cl    
    call    Func_Loader_DispAL

    mov eax, [DisplayPosition]
    add eax, 2
    mov [DisplayPosition], eax

    pop ax
;=======

    cmp cx,  0FFFFh
    jz  Label_SVGA_Mode_Info_Finish

    mov ax,  4F01h
    int 10h

    cmp ax,  004Fh

    jnz Label_SVGA_Mode_Info_FAIL    

    inc dword [SVGAModeCounter]
    add esi, 2
    add edi, 0x100

    jmp Label_SVGA_Mode_Info_Get
Label_SVGA_Mode_Info_FAIL:

    mov ax,  1301h
    mov bx,  008Ch
    mov dx,  0D00h ;row 13
    mov cx,  24
    push    ax
    mov ax,  ds
    mov es,  ax
    pop ax
    mov bp,  GetSVGAModeInfoErrMessage
    int 10h

Label_SET_SVGA_Mode_VESA_VBE_FAIL:

    jmp $
Label_SVGA_Mode_Info_Finish:

    mov ax,  1301h
    mov bx,  000Fh
    mov dx,  0E00h ;row 14
    mov cx,  30
    push    ax
    mov ax,  ds
    mov es,  ax
    pop ax
    mov bp,  GetSVGAModeInfoOKMessage
    int 10h

    

;=======    set the SVGA mode(VESA VBE)

    mov ax,  4F02h
    mov bx,  180h ;========================mode : 0x180 or 0x143
    int     10h

    cmp ax,  004Fh
    jnz Label_SET_SVGA_Mode_VESA_VBE_FAIL


;=======    init IDT GDT goto protect mode 

    cli ;======close interrupt

    db  0x66
    lgdt    [GdtPtr]

;   db 0x66
;   lidt   [IDT_POINTER]

    mov eax, cr0
    or  eax,  1
    mov cr0, eax  

    jmp dword SelectorCode32:GO_TO_TMP_Protect

[SECTION .s32]
[BITS 32]

GO_TO_TMP_Protect:

    call Func_Loader_Halt

;=======    go to tmp long mode

    mov ax,  0x10
    mov ds,  ax
    mov es,  ax
    mov fs,  ax
    mov ss,  ax
    mov esp, 7E00h

    call    support_long_mode
    test    eax,    eax

    jz  no_support

;=======    init temporary page table 0x90000

    mov dword    [0x90000],  0x91007
    mov dword    [0x90004],  0x00000
    mov dword    [0x90800],  0x91007
    mov dword    [0x90804],  0x00000

    mov dword    [0x91000],  0x92007
    mov dword    [0x91004],  0x00000

    mov dword    [0x92000],  0x000083
    mov dword    [0x92004],  0x000000

    mov dword    [0x92008],  0x200083
    mov dword    [0x9200c],  0x000000

    mov dword    [0x92010],  0x400083
    mov dword    [0x92014],  0x000000

    mov dword    [0x92018],  0x600083
    mov dword    [0x9201c],  0x000000

    mov dword    [0x92020],  0x800083
    mov dword    [0x92024],  0x000000

    mov dword    [0x92028],  0xa00083
    mov dword    [0x9202c],  0x000000

;=======    load GDTR

    db  0x66
    lgdt    [GdtPtr64]
    mov ax,  0x10
    mov ds,  ax
    mov es,  ax
    mov fs,  ax
    mov gs,  ax
    mov ss,  ax

    mov esp, 7E00h

;=======    open PAE

    mov eax, cr4
    bts eax, 5
    mov cr4, eax

;=======    load    cr3

    mov eax, 0x90000
    mov cr3, eax

;=======    enable long-mode

    mov ecx, 0C0000080h   ;IA32_EFER
    rdmsr

    bts eax, 8
    wrmsr

;=======    open PE and paging

    mov eax, cr0
    bts eax, 0
    bts eax, 31
    mov cr0, eax

    jmp SelectorCode64:OffsetOfKernelFile

;=======    test support long mode or not

support_long_mode:

    mov eax, 0x80000000
    cpuid
    cmp eax, 0x80000001
    setnb   al 
    jb  support_long_mode_done
    mov eax, 0x80000001
    cpuid
    bt  edx,  29
    setc    al
support_long_mode_done:

    movzx   eax,   al
    ret

;=======    no support

no_support:
    jmp Func_Loader_Halt

;=======    read one sector from floppy
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

    pop bx  
    mov dl, [BS_DrvNum]
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

;======= display num in al

Func_Loader_DispAL:
    push ecx
    push edx
    push edi

    mov edi, [DisplayPosition]
    mov ah, 0Fh
    mov dl, al
    shr al, 4
    mov ecx, 2
.begin:
    and al, 0Fh
    cmp al, 9
    ja .1
    add al, '0'
    jmp .2
.1:
    sub al, 0Ah
    add al, 'A'
.2:
    mov [gs:edi], ax
    add edi, 2

    mov al, dl
    loop .begin

    mov [DisplayPosition], edi

    pop edi
    pop edx
    pop ecx

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

;======= get FAT Entry

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

;=======    tmp IDT

IDT:
    times   0x50   dq 0
IDT_END:

IDT_POINTER:
    dw  IDT_END - IDT - 1
    dd  IDT


;=======  临时变量

; 根目录所占扇区中待遍历扇区的个数，初始值：14
RootDirSizeForLoop      dw   RootDirSectors
;当前遍历的扇区号，初始值：0
SectorNo    dw  0
Odd         db  0
;由于内核体积庞大必须逐个簇地读取和转存，每次转存内核程序片段时必须保存目标偏移值，
;该值（EDI寄存器）保存于临时变量OffsetOfKernelFileCount中。
OffsetOfKernelFileCount dd  OffsetOfKernelFile

MemStructNumber		dd	0

SVGAModeCounter		dd	0

DisplayPosition  dd ((80 * 16) + 0) * 2 ;屏幕地16行，第0列开始

;=======  display messages

;loader启动时打印的信息
StartLoaderMessage: db "Start Loader"

;kernel.bin 文件未找到时打印的信息
NoKernelMessage: db "ERROR:No KERNEL Found"

;内核文件在文件系统中的 DIR_Name : "KERNEL  BIN"
KernelFileName: db "KERNEL  BIN",0

; 获取物理地址空间信息提示字符串    
StartGetMemStructMessage:       db "Start Get Memory Struct (address,size,type)."
StartGetSVGAModeInfoMessage:    db "Start Get SVGA Mode Info"
StartGetSVGAVBEInfoMessage:     db "Start Get SVGA VBE Info"
GetMemStructOKMessage:          db "Get Memory Struct SUCCESSFUL!"
GetSVGAVBEInfoOKMessage:        db "Get SVGA VBE Info SUCCESSFUL!"
GetSVGAModeInfoOKMessage:       db "Get SVGA Mode Info SUCCESSFUL!"

; 获取物理地址空间信息失败提示
GetMemStructErrMessage:         db "Get Memory Struct ERROR"
GetSVGAVBEInfoErrMessage:       db "Get SVGA VBE Info ERROR"
GetSVGAModeInfoErrMessage:      db "Get SVGA Mode Info ERROR"
