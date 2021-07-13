void Start_Kernel(void)
{

        
    int *addr = (int *)0xffff800000a00000;
    char *addr2 = (char *)0xffff800000a00000;
    int i;

    for (i = 0; i < 1440 * 20; i++)
    {
        // 方法一：
        // *((char *)addr + 0) = (char)0x00;
        // *((char *)addr + 1) = (char)0x00;
        // *((char *)addr + 2) = (char)0xff;
        // *((char *)addr + 3) = (char)0x00;
        // addr += 1;

        // 方法二：
        *((unsigned long int *) addr) = (unsigned long int) 0x00ff0000;
        addr += 1;

        // 方法三：
        // *(addr2++) = (char)0x00;
        // *(addr2++) = (char)0x00;
        // *(addr2++) = (char)0xff;
        // *(addr2++) = (char)0x00;
        // addr += 1; // 需要步进，否则红色区域会被覆盖
    }
    for (i = 0; i < 1440 * 20; i++)
    {
        *((char *)addr + 0) = (char)0x00;
        *((char *)addr + 1) = (char)0xff;
        *((char *)addr + 2) = (char)0x00;
        *((char *)addr + 3) = (char)0x00;
        addr += 1;
    }
    for (i = 0; i < 1440 * 20; i++)
    {
        *((char *)addr + 0) = (char)0xff;
        *((char *)addr + 1) = (char)0x00;
        *((char *)addr + 2) = (char)0x00;
        *((char *)addr + 3) = (char)0x00;
        addr += 1;
    }
    for (i = 0; i < 1440 * 20; i++)
    {
        *((char *)addr + 0) = (char)0xff;
        *((char *)addr + 1) = (char)0xff;
        *((char *)addr + 2) = (char)0xff;
        *((char *)addr + 3) = (char)0x00;
        addr += 1;
    }

    while (1)
        ;
}