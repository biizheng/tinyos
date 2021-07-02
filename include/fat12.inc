;=======  常量定义区

; 代码RootDirSectors equ 14定义了根目录占用的扇区数，这个数值是根据FAT12文件系统提供的信息经过计算而得
; (BPB_RootEntCnt ＊ 32 + BPB_BytesPerSec -1) / BPB_Bytes PerSec =(224×32 + 512-1) / 512 = 14
; 注：计算结果需要根据扇区大小向上取整，这里除法后的计算结果为14.99....，向上取整后为14
RootDirSectors	equ	14

; 等价语句SectorNumOfRootDirStart equ 19 定义了根目录的起始扇区号
; 这个数值也是通过计算而得，即：保留扇区数 + FAT表扇区数 * FAT表份数
; BPB_RsvdSecCnt + (BPB_FATSz16 * BPB_NumFATs) = 19
SectorNumOfRootDirStart	equ	19

; FAT1表的起始扇区号 值：1
SectorNumOfFAT1Start	equ	1

; 用于在使用文件名查找文件时方便计算 值：17
SectorBalance	equ	17	

;=======  数据区

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
