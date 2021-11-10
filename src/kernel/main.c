#include "font.h"
#define NULL 0
#define WHITE 0x00ffffff  //白
#define BLACK 0x00000000  //黑
#define RED 0x00ff0000    //红
#define ORANGE 0x00ff8000 //橙
#define YELLOW 0x00ffff00 //黄
#define GREEN 0x0000ff00  //绿
#define BLUE 0x000000ff   //蓝
#define INDIGO 0x0000ffff //靛
#define PURPLE 0x008000ff //紫
void putchar(unsigned int *fb, int Xsize, int x, int y, unsigned int FRcolor, unsigned int BKcolor, unsigned char font);
void Start_Kernel(void)
{

    int *addr = (int *)0xffff800000a00000;
    char *addr2 = (char *)0xffff800000a00000;
    int i;
    putchar(addr, 1440, 0, 0, RED, YELLOW, '0');
    for (i = 0; i < 1440 * 20; i++)
    {
        // 方法一：
        // *((char *)addr + 0) = (char)0x00;
        // *((char *)addr + 1) = (char)0x00;
        // *((char *)addr + 2) = (char)0xff;
        // *((char *)addr + 3) = (char)0x00;
        // addr += 1;

        // 方法二：
        *((unsigned long int *)addr) = (unsigned long int)0x00ff0000;
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

    putchar(addr, 1440, 0x00, 0, RED, YELLOW, '0');
    putchar(addr, 1440, 0x10, 0, RED, YELLOW, 'a');
    putchar(addr, 1440, 0x20, 0, RED, YELLOW, 'B');
    putchar(addr, 1440, 0x30, 0, RED, YELLOW, '@');
    putchar(addr, 1440, 0, 0x00, RED, YELLOW, '0');
    putchar(addr, 1440, 0, 0x10, RED, YELLOW, 'a');
    putchar(addr, 1440, 0, 0x20, RED, YELLOW, 'B');
    putchar(addr, 1440, 0, 0x30, RED, YELLOW, '@');
    while (1)
        ;
}

void putchar(unsigned int *fb, int Xsize, int x, int y, unsigned int FRcolor, unsigned int BKcolor, unsigned char font)
{
    int i = 0, j = 0;
    unsigned int *addr = NULL;
    unsigned char *fontp = NULL;
    int testval = 0;
    // 待打印的像素点矩阵
    fontp = font_ascii[font];
    // 定位到字符的左上角第一个像素
    addr = fb + Xsize * y + x;

    for (i = 0; i < 16; i++)
    {
        testval = 0x100;
        for (j = 0; j < 8; j++)
        {
            testval = testval >> 1;
            if (*fontp & testval)
                *addr = FRcolor;
            else
                *addr = BKcolor;
            addr++;
        }
        fontp++;
        // 像素换行
        addr += (Xsize - 8);
    }
}