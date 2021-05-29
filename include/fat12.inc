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
