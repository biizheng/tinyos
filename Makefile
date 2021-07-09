all: boot.bin loader.bin system
	objcopy -I elf64-x86-64 -S -R ".eh_frame" -R ".comment" -O binary ./bin/system ./bin/kernel.bin

clean:
	rm -rf ./bin/*.bin ./bin/*.lst ./bin/*.o

run:
	bochs -q -f ./config/bochsrc.properties -rc ./config/run.cfg

run-g:
	bochs -q -f ./config/bochsrc.gui.properties -rc ./config/run.cfg

loader.bin:
	nasm ./src/bootloader/loader.asm -o ./bin/loader.bin -l ./bin/loader.lst 

boot.bin:
	nasm ./src/bootloader/boot.asm -o ./bin/boot.bin -l ./bin/boot.lst 
	

system:	head.o main.o 
	ld -b elf64-x86-64 -o ./bin/system ./bin/head.o ./bin/main.o -T ./script/Kernel.lds 

main.o:
	gcc  -mcmodel=large -fno-builtin -m64 -c ./src/kernel/main.c -o ./bin/main.o

head.o:
	gcc -E ./src/kernel/head.S > ./bin/head.s
	as --64 -o ./bin/head.o ./bin/head.s

boot.img: boot.bin
	dd if=./bin/boot.bin of=./bin/boot.img bs=512 count=1 conv=notrunc