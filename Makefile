all: boot.bin loader.bin

clean:
	rm -rf ./bin/*.bin ./bin/*.lst

run:
	bochs -q -f ./config/bochsrc.properties -rc ./config/run.cfg

loader.bin:
	nasm ./src/loader.asm -o ./bin/loader.bin -l ./bin/loader.lst 

boot.bin:
	nasm ./src/boot.asm -o ./bin/boot.bin -l ./bin/boot.lst 

boot.img: boot.bin
	dd if=./bin/boot.bin of=./bin/boot.img bs=512 count=1 conv=notrunc