#!/bin/bash
# 使用 makefile 执行时，命令中的路径以 makefile 为基准添加相对路径
mount bin/boot.img /media -t vfat -o loop
cp -f bin/loader.bin /media
cp -f bin/kernel.bin /media
sync
umount /media
