all: boot.bin loader.bin

loader.bin:
	nasm ./src/loader.asm -o ./bin/loader.bin -l ./bin/loader.lst 

boot.bin:
	nasm ./src/boot.asm -o ./bin/boot.bin -l ./bin/boot.lst 

clean:
	rm -rf ./bin/*.bin ./bin/*.lst
