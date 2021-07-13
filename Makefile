bin = ./bin
config = ./config
src=./src
bootloader = $(src)/bootloader
include = $(src)/include
kernel = $(src)/kernel

all: boot.bin loader.bin system
	objcopy -I elf64-x86-64 -S -R ".eh_frame" -R ".comment" -O binary $(bin)/system $(bin)/kernel.bin
	mount $(bin)/boot.img /media/ -t vfat -o loop
	cp $(bin)/loader.bin /media/
	cp $(bin)/kernel.bin /media/
	sync
	umount /media/
	exit

all_1:boot.bin loader_1.bin system
	objcopy -I elf64-x86-64 -S -R ".eh_frame" -R ".comment" -O binary $(bin)/system $(bin)/kernel.bin
	mount $(bin)/boot.img /media/ -t vfat -o loop
	cp $(bin)/loader.bin /media/
	cp $(bin)/kernel.bin /media/
	sync
	umount /media/
	exit

clean:
	rm -rf $(bin)/*.bin $(bin)/*.lst $(bin)/*.o

run:
	bochs -q -f $(config)/bochsrc.properties -rc $(config)/run.cfg

run-g:
	bochs -q -f $(config)/bochsrc.gui.properties -rc $(config)/run.cfg

loader.bin:$(bootloader)/loader.asm
	nasm -o $(bin)/$@ $< -l $(bin)/boot.lst -I $(bootloader)

boot.bin:$(bootloader)/boot.asm
	nasm -o $(bin)/$@ $< -l $(bin)/boot.lst 

system:	head.o main.o 
	ld -b elf64-x86-64 -o $(bin)/system $(bin)/head.o $(bin)/main.o -T $(include)/Kernel.lds 

main.o:
	gcc -mcmodel=large -fno-builtin -m64 -c $(kernel)/main.c -o $(bin)/main.o

head.o:$(kernel)/head.S
	gcc -E $< > $(bin)/head.s
	as --64 -o $(bin)/head.o $(bin)/head.s

boot.img: boot.bin
	dd if=$(bin)/boot.bin of=$(bin)/boot.img bs=512 count=1 conv=notrunc