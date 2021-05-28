org 0x7c00

BaseOfStack             equ 0x7c00

; BaseOfLoader << 4+ OffsetOfLoader = 0x10000
; Loader的段基址 0x1000
BaseOfLoader            equ 0x1000
; Loader的段内偏移地址
OffsetOfLoader          equ 0x00

; ceil 根据扇区大小向上取整
; 代码RootDirSectors equ 14定义了根目录占用的扇区数，这个数值是根据FAT12文件系统提供的信息经过计算而得
; (BPB_RootEntCnt ＊ 32 + BPB_BytesPerSec -1) / BPB_Bytes PerSec =(224×32 + 512-1) / 512 = 14
RootDirSectors          equ 14

; 等价语句SectorNumOfRootDirStart equ 19 定义了根目录的起始扇区号
; 这个数值也是通过计算而得，即：保留扇区数 + FAT表扇区数 * FAT表份数
; BPB_RsvdSecCnt + (BPB_FATSz16 * BPB_NumFATs) = 19
SectorNumOfRootDirStart equ    19

; FAT1表的起始扇区号 值：1
SectorNumOfFAT1Start    equ 1
; 用于在使用文件名查找文件时方便计算 值：17
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
    mov cx, 10
    ; es:bp => start of string 
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
;
;         +---------------------------------+
;         | Lable_Search_In_Root_Dir_Begin  |
;         +----------------+----------------+
;                          |      RootDirSizeForLoop=0
;                          +------------+
;                          |            |
;                          |  +---------v----------+
;                          |  | Label_No_LoaderBin |
;                          |  +--------------------+
;                          v
;           +--------------+-------------+
;       +-> | Label_Search_For_LoaderBin |
;       |   +--------------+-------------+
;       |                  |           DX=0
;       |                  +------------+
;       |                  |            |
;       |                  |  +---------v--------------------------+
;       |                  |  | Label_Goto_Next_Sector_In_Root_Dir |
;       |                  |  +------------------------------------+
;       |                  v
;       |       +----------+---------+
;       |   +-> | Label_Cmp_FileName |
;       |   |   +----------+---------+
;       |   |              |          CX=0
;       | +-------------+  +------------+
;       | | Label_Go_On |  |            |
;       | +-------------+  |  +---------v------------+
;       |    ^             |  | Label_FileName_Found |
;       |    |             |  +----------------------+
;       |    +-------------+
;       |   Not Equal      |
;       |                  v
;       |       +----------+------+
;       +-------+ Label_Different |
;               +-----------------+
;=======  初始化查找扇区的编号
    mov word [SectorNo], SectorNumOfRootDirStart
;=======  先将根目录占用的扇区依次加载到内存中
;         加载完成后，在根目录中查找"loader.bin"文件
;         1.数据缓冲区内存地址: es:bx => 0x08000h，
;         2.当前加载的扇区编号: ax = [SectorNo]，初始值19
Lable_Search_In_Root_Dir_Begin:

    ;判断扇区是否全部遍历
    cmp word [RootDirSizeForLoop],  0
    ;若在完成搜索后未发现"loader bin"文件，则给出提示
    jz  Label_No_LoaderBin
    ; mov ax, '.'
    ; call Func_PrintCharInAL
    dec word [RootDirSizeForLoop]
    ; 调用 Func_ReadOneSector ，从软盘中读取一个扇区，参数如下
    ; ax = [SectorNo]
    ; cl = 1
    ; es:bx => 0x8000
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
    ; dx初始值为每个扇区可容纳的目录项个数
    ; (512/32 = 16 = 0x10)
    mov dx, 10h
;=======  对新载入内存的根目录扇区进行遍历,查找文件名与目标文件名相同的目录项
;         1.缓冲区内存地址 es:di => 8000h
;         2.待遍历扇区个数 dx(初始值为16)
Label_Search_For_LoaderBin:
    ;若当前扇区的目录项遍历完后未发现目标文件
    ;则加载根目录的下一个扇区
    cmp dx, 0
    jz Label_Goto_Next_Sector_In_Root_Dir
    dec dx
    ;文件名长度
    mov cx, 11
Label_Cmp_FileName:
    cmp cx, 0
    jz Label_FileName_Found
    dec cx
    ;该命令可从DS:(R|E)SI寄存器指定的内存地址中读取数据到AL/AX/EAX/RAX寄存器
    ;当前ds = es = cs = 0x0000h
    ;此处加载到al的数据源是 "LoaderFileName"=>"LOADER  BIN",0
    lodsb
    ;al = [ds:si]
    ;ds:si => LoaderFileName => "LOADER  BIN",0
    ;es:di => 0x8000h
    cmp al, byte [es:di]
    ;若相同则继续进行比较
    jz Label_Go_On
    jmp Label_Different
Label_Go_On:
    ; 比较目录项下一位字符是与"loader  bin"对应位置的字符相同
    call Func_PrintCharInAL
    inc di
    jmp Label_Cmp_FileName
Label_Different:
    ; 换行 LF
    ; mov al,0x0A
    ; call Func_PrintCharInAL
    ; 清空 CR
    ; mov al,0x0D
    ; call Func_PrintCharInAL
    ;取整
    and di,0ffe0h
    ;跳至下一个目录项
    add di,20h
    mov si, LoaderFileName
    jmp Label_Search_For_LoaderBin
    
;加载根目录占用的下一个扇区
Label_Goto_Next_Sector_In_Root_Dir:
    add word [SectorNo], 1
    jmp Lable_Search_In_Root_Dir_Begin
    ;jmp Label_Halt

;=======  display hints: ERROR:No LOADER Found
Label_No_LoaderBin:
    mov  ax,  1301h
    mov  bx,  000ch
    mov  cx,  13
    mov  dx,  0100h
    push  ax
    mov  ax,  ds
    mov  es,  ax
    pop  ax
    mov  bp,  NoLoaderMessage
    int  10h
    jmp Label_Halt

;=======  found loader.bin name in root director struct
; 找到文件
Label_FileName_Found:

    mov ax, RootDirSectors
    ; 此时es:di 指向文件名末尾后的第一个字节
    ; 0000 0000 0001 1111  :目录项大小 32B
    ; 1111 1111 1110 0000  :0xffe0
    ; di同0xffe0进行与运算，清除文件名比较过程中di作为索引自增的值
    and di, 0ffe0h
    ; 找到目录项中，‘DIR_FstClus’的位置
    add di, 01ah
    ; 文件的起始簇号
    mov cx, word [es:di]
    push cx
    ; 因为FAT12中一扇区为一簇，所以可以直接通过扇区数找到对应的簇
    add cx, ax
    ; FAT表中，前两个FAT表项在数据区中没有对应的簇，所以在目录项中\
    ; 的簇号‘DIR_FstClus’对应的扇区需要前移两位(在本书中计算簇号\
    ; 对应的扇区号采取直接计算的方式，没有采取更复杂的计算方式)，这\
    ; 里使用‘SectorBalance’直接进行计算。
    add cx, SectorBalance
    ; BaseOfLoader << 4+ OffsetOfLoader = 0x10000
    mov ax, BaseOfLoader
    mov es, ax
    mov bx, OffsetOfLoader
    ; ax = loader.bin起始扇区号
    mov ax, cx
Label_Go_On_Loading_File:
    ; ax = RootDirSectors + SectorBalance + DIR_FstClus(目录\
    ; 项中的起始簇号)
    ; cl = 1
    ; es:bx => BaseOfLoader << 4+ OffsetOfLoader = 0x10000
    mov cl, 1
    call Func_ReadOneSector
    ; ax = DIR_FstClus(目录项的起始簇号)
    pop ax
    call Func_GetFATEntry
    ; 0x0fff表示文件簇链表的末尾
    cmp ax, 0fffh
    jz Label_File_Loaded
    ; 在调用Func_GetFATEntry后，ax存储的是下一个待读入的簇号
    push ax
    ; 根据簇号计算该簇对应的扇区号
    mov dx, RootDirSectors
    add ax, dx
    add ax, SectorBalance
    ; 当前扇区内容加载完毕，更新es:bx所指向的内存地址，为加载下一个扇区做准备
    add bx, [BPB_BytesPerSec]
    jmp Label_Go_On_Loading_File
Label_File_Loaded:
    jmp BaseOfLoader:OffsetOfLoader

;=======  HLT
Label_Halt:
    hlt
    jmp Label_Halt

;=======  read one sector from floppy
; ax = 待读取的磁盘扇区起始号
; cl = 读入的扇区数量
; es:bx = 目标缓冲区起始地址
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

;=======  打印寄存器‘AL’中字符
Func_PrintCharInAL:
    push    ax
    push    bx
    push    cx
    ; call int 10h,function num = 0x0e
    ; al = '.'
    ; bl = 字体前景色
    mov     ah,     0eh
    mov     bh,     00h
    mov     bl,     0fh
    mov     cx,     00h
    int     10h
    pop     cx
    pop     bx
    pop     ax
    ret
;=======  根据当前FAT表项索引出下一个FAT表项
;         ah:FAT表项号(输入参数/输出参数)
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
    mov bx,2
    div bx
    cmp dx, 0
    jz Label_Even
    mov byte [Odd], 1
Label_Even:
    xor dx, dx
    mov bx,[BPB_BytesPerSec]
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
    and ax, 0fffh
    pop bx
    pop es 
    ret

;=======  tmp variable

; 根目录所占扇区中待遍历扇区的个数，初始值：14
RootDirSizeForLoop  dw  RootDirSectors

;当前遍历的扇区号，初始值：0
SectorNo    dw  0
Odd      db  0

;=======  display messages=

; "Start Booting --bizheng"
StartBootMessage:   db "Start Boot"
; "ERROR:No LOADER Found"
NoLoaderMessage:    db "ERR:No LOADER"
; "LOADER  BIN",0
LoaderFileName:    db  "LOADER  BIN",0
;==========  fill the rest of remaining sector with zero ==========

    times 510 - ( $ - $$ ) db 0
    ; dw 0xaa55
    db 0x55,0xaa
    

