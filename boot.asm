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
    BS_OEMName      db  'MINEboot'
    BPB_BytesPerSec dw  512
    BPB_SecPerClus  db  1
    BPB_RsvdSecCnt  dw  1
    BPB_NumFATs     db  2
    BPB_RootEntCnt  dw  224
    BPB_TotSec16    dw  2880
    BPB_Media       db  0xf0
    BPB_FATSz16     dw  9
    BPB_SecPerTrk   dw  18
    BPB_NumHeads    dw  2
    BPB_HiddSec     dd  0
    BPB_TotSec32    dd  0
    BS_DrvNum       db  0
    BS_Reserved1    db  0
    BS_BootSig      db  0x29
    BS_VolID        dd  0
    BS_VolLab       db  'boot loader'
    BS_FileSysType  db  'FAT12   '
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

    jmp Label_No_LoaderBin

;=======  HLT
halt:
    hlt
    jmp halt
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
    jmp halt

;=======  display messages=
StartBootMessage:   db "Start Booting --bizheng"
NoLoaderMessage:    db "ERROR:No LOADER Found"
;==========  fill the rest of remaining sector with zero ==========

    times 510 - ( $ - $$ ) db 0
    ; dw 0xaa55
    db 0x55,0xaa
    

