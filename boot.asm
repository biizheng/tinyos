org 0x7c00

BaseOfStack             equ 0x7c00

; BaseOfLoader << 4+ OffsetOfLoader = 0x10000
BaseOfLoader            equ 0x1000
OffsetOfLoader          equ 0x1000

; ceil 根据扇区大小向上取整
; 代码RootDirSectors equ 14定义了根目录占用的扇区数，这个数值是根据FAT12文件系统提供的信息经过计算而得
; (BPB_RootEntCnt ＊ 32 + BPB_BytesPerSec -1) / BPB_Bytes PerSec =(224×32 + 512-1) / 512 = 14
RootDirSectors          equ 14

; 等价语句SectorNumOfRootDirStart equ 19 定义了根目录的起始扇区号
; 这个数值也是通过计算而得，即：保留扇区数 + FAT表扇区数 * FAT表份数
; BPB_RsvdSecCnt + (BPB_FATSz16 * BPB_NumFATs) = 19
SectorNumOfRootDirStart equ    19
SectorNumOfFAT1Start    equ 1
SectorBalance           equ 17

    jmp short Label_Start
    nop
;生产厂商名字
BS_OEMName      db  'MINEboot'

;每扇区字节数
BPB_BytesPerSec dw  512

;每扇区簇数
BPB_SecPerClus  db  1

;保留扇区数
BPB_RsvdSecCnt  dw  1

;FAT表的份数
BPB_NumFATs     db  2

;根目录可容纳总数
BPB_RootEntCnt  dw  224

;总扇区数
BPB_TotSec16    dw  2880

;介质描述符
BPB_Media       db  0xf0

;每FAT扇区数
BPB_FATSz16     dw  9

;每磁道扇区数
BPB_SecPerTrk   dw  18

;磁头数
BPB_NumHeads    dw  2

;隐藏扇区数
BPB_HiddSec     dd  0

;如果BPB_TotSec16的值为0,则有这个值来记录扇区数
BPB_TotSec32    dd  0

;int 13h 的驱动器号
BS_DrvNum       db  0

;未使用
BS_Reserved1    db  0

;扩展引导标记（29h）
BS_BootSig      db  0x29

;卷序列号
BS_VolID        dd  0

;卷标
BS_VolLab       db  'boot loader'

;文件系统类型
BS_FileSysType  db  'FAT12   '

;引导代码初始地址
Label_Start:
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, BaseOfStack

;======= clear sreen 

    mov ax, 0600h
    mov bx, 0700h
    mov cx, 0
    mov dx, 0184fh
    int 10h

;========  set fcous  

    mov ax, 0200h
    mov bx, 0000h
    mov dx, 0000h
    int 10h

;=======  display on screen :Strat Booting ... --bizheng 

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

;=======  reset floppy  

    xor ah, ah
    xor dl, dl
    int 13h
;=======  Search Loader.bin
    mov word [SectorNo], SectorNumOfRootDirStart

;=======  先将根目录加载到内存中(es:bx => 0x08000h)
;         加载完成后，在根目录中查找"loader.bin"文件
Lable_Search_In_Root_Dir_Begin:

    cmp word [RootDirSizeForLoop],  0
    ;在完成搜索后未发现"loader bin"文件则给出提示
    jz  Label_No_LoaderBin
    dec word [RootDirSizeForLoop]
    ; ax = 19
    ; cl = 1
    ; es:bx => 0x08000h
    mov ax, 00h
    mov es, ax
    mov bx, 8000h
    mov cl, 1
    mov ax, [SectorNo]
    ;读取一个扇区
    call Func_ReadOneSector
    mov si, LoaderFileName
    mov di, 8000h
    cld
    ; dx记录每个扇区可容纳的目录项个数
    ; (512/32 = 16 = 0x10)
    mov dx, 10h

;=======  对载入内存的根目录进行遍历
Label_Search_For_LoaderBin:

    ;若当前扇区的目录项遍历完后未发现目标文件
    ;则加载根目录的下一个扇区
    cmp dx, 0
    jz Label_Goto_Next_Sector_In_Root_Dir
    dec dx
    ;文件名长度
    mov cx, 11

Label_Cmp_FileName:

    call Func_PrintDot
    cmp cx, 0
    jz Label_FileName_Found
    dec cx
    ;该命令可从DS:(R|E)SI寄存器指定的内存地址中读取数据到AL/AX/EAX/RAX寄存器
    ;当前ds = es = cs = 0x0000h
    ;此处加载到al的数据源是 "LoaderFileName"=>"LOADER  BIN",0
    lodsb
    ;ds:si => LoaderFileName => "LOADER  BIN",0
    ;es:di => 0x8000h
    cmp al, byte [es:di]
    ;若相同则继续进行比较
    jz Label_Go_on
    jmp Label_Different
Label_Go_on:
    ; 比较下一位
    inc di
    jmp Label_Cmp_FileName
Label_Different:
    ;取整
    and di,0ffe0h
    ;跳至下一个目录项
    add di,20h
    mov si, LoaderFileName
    jmp Label_Search_For_LoaderBin
;加载根目录占用的下一个扇区
Label_Goto_Next_Sector_In_Root_Dir:
    ; add word [SectorNo], 1
    ; jmp Lable_Search_In_Root_Dir_Begin
    jmp Label_Halt

;=======  display hints: ERROR:No LOADER Found
Label_No_LoaderBin:
    mov  ax,  1301h
    mov  bx,  000ch
    mov  cx,  21
    mov  dx,  0100h
    push  ax
    mov  ax,  ds
    mov  es,  ax
    pop  ax
    mov  bp,  NoLoaderMessage
    int  10h
    jmp Label_Halt

;=======  read one sector from floppy
Func_ReadOneSector:
    
    push  bp
    mov  bp,  sp
    ; 入栈cl
    sub  esp,  2
    mov  byte  [bp - 2],  cl
    push  bx
    mov  bl,  [BPB_SecPerTrk]
    div  bl
    ; Sector 
    inc  ah
    mov  cl,  ah
    ; Head
    mov  dh,  al
    and  dh,  1
    ; Sylinder
    shr  al,  1
    mov  ch,  al
    
    pop  bx
    mov  dl,  [BS_DrvNum]
Label_Go_On_Reading:
    mov  ah,  2
    mov  al,  byte  [bp - 2]
    int  13h
    jc  Label_Go_On_Reading
    ; 出栈cl
    add  esp,  2
    pop  bp
    ret

;=======  found loader.bin name in root director struct
; 找到文件
Label_FileName_Found:
    jmp Label_Halt

;=======  HLT
Label_Halt:
    hlt
    jmp Label_Halt
;=======  print 
Func_PrintDot:
    push    ax
    push    bx
    push    cx
    ; call int 10h,function num = 0x0e
    ; al = '.'
    ; bl = 字体前景色
    mov     ah,     0eh
    mov     al,     '.'
    mov     bh,     00h
    mov     bl,     0fh
    mov     cx,     00h
    int     10h
    pop     cx
    pop     bx
    pop     ax
    ret

;=======  tmp variable

; 待搜索的根目录文件个数，初始值：14
RootDirSizeForLoop  dw  RootDirSectors

;当前遍历的扇区号
SectorNo    dw  0
Odd      db  0

;=======  display messages=

; "Start Booting --bizheng"
StartBootMessage:   db "Start Booting --bizheng"
; "ERROR:No LOADER Found"
NoLoaderMessage:    db "ERROR:No LOADER Found"
; "LOADER  BIN",0
LoaderFileName:    db  "LOADER  BIN",0
;==========  fill the rest of remaining sector with zero ==========

    times 510 - ( $ - $$ ) db 0
    ; dw 0xaa55
    db 0x55,0xaa
    

