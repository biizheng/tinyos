//===== GDT Table
.section .data
.globl GDT_Table

GDT_Table:
    .quad   0x0000000000000000  /* NULL descriptor 00*/


GDT_END: