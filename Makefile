DIR_SRC = ./src
DIR_OBJ = ./obj
DIR_BIN = ./bin
DIR_CONFIG = ./config
DIR_BOOTLOADER = $(DIR_SRC)/bootloader
DIR_KERNEL = $(DIR_SRC)/kernel

# Source Code
SRC_C = $(wildcard ${DIR_KERNEL}/*.c)
SRC_ASM = $(wildcard ${DIR_BOOTLOADER}/*.asm)

# Options   -ggdb -fno-stack-protector -ffreestanding -fno-exceptions
CC = gcc
C_FLAGS = -mcmodel=large -fno-builtin -m64 -c -I$(DIR_KERNEL)
LD_FLAGS = -z muldefs -b elf64-x86-64 -T $(DIR_CONFIG)/Kernel.lds 

# Objects ASM_SRC
OBJ_KERNEL = $(DIR_BIN)/kernel.bin
OBJ_SYSTEM = $(DIR_BIN)/system
OBJ_BOOT = $(patsubst %.asm, ${DIR_BIN}/%.bin, $(notdir ${SRC_ASM}))
OBJ_C = $(patsubst %.c, ${DIR_OBJ}/%.o, $(notdir ${SRC_C}))

.PHONY:all clean install run

all:$(OBJ_C) $(OBJ_BOOT) $(OBJ_KERNEL) $(OBJ_SYSTEM) 

clean:
	-rm -rf ${DIR_OBJ}/%.o $(OBJ_BOOT) $(OBJ_KERNEL) $(OBJ_SYSTEM) $(DIR_BIN)/head.s

install:$(DIR_BIN)/boot.bin
	dd if=$(DIR_BIN)/boot.bin of=$(DIR_BIN)/boot.img bs=512 count=1 conv=notrunc
	sudo sh script/cp.sh

run:all install
	sh script/run.sh

g-run:all install
	sh script/run-g.sh

$(DIR_BIN)/%.bin:${DIR_BOOTLOADER}/%.asm
	$(info ========== Building $@ ==========)
	nasm -l$(DIR_BIN)/boot.lst -I$(DIR_BOOTLOADER) -o $@ $< 

$(OBJ_KERNEL):$(OBJ_SYSTEM)
	$(info ========== Remove extra sections of the kernel ==========)
	objcopy -S -R ".eh_frame" -R ".comment" -I elf64-x86-64 -O binary $< $@

$(OBJ_SYSTEM):$(DIR_OBJ)/head.o $(OBJ_C)
	$(info ========== Linking the kernel ==========)
	ld $(LD_FLAGS) -o $@ $^

$(DIR_OBJ)/head.o:$(DIR_KERNEL)/head.S
	gcc -E $< > $(DIR_BIN)/head.s
	as --64 -o $(DIR_OBJ)/head.o $(DIR_BIN)/head.s

${DIR_OBJ}/%.o:$(DIR_KERNEL)/%.c
	$(CC) $(C_FLAGS) $< -o $@

$(DIR_BIN)/boot.img:
	@echo "写入 bootloader 前需要创建硬盘镜像"