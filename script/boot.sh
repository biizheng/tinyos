#$1 is the first parameter
# input the name without suffix of asm file

#  ./boot.sh boot
# nasm boot.asm -o boot.bin -l boot.lst 
# nasm loader.asm -o loader.bin -l loader.lst 
#nasm $1.asm -o $1.bin -l $1.lst 

# write your compiled progarm into a virtual iamge
# if    input file: in this case ,the input file is "$1.bin"
# of    output file: in this case ,the output file is "$1.img"
# bs    block size: the size of block you are going to transfer
# count the number of blocks that will be transferd
# conv  "conv=notrunc" means it will not truncate the output file 
#       even if the input file is smaller than the output file

#dd if=boot.bin of=boot.img bs=512 count=1 conv=notrunc
#dd if=../bin/boot.bin of=../bin/boot.img bs=512 count=1 conv=notrunc
dd if=../bin/$1.bin of=../bin/$1.img bs=512 count=1 conv=notrunc

# -q    skip the "Bochs Configuration Main menu"
# -f    to define a configuration file
# -rc   you can put the instruct you want to execute 
#       when your program in bochs start up
bochs -q -f ../config/bochsrc.properties -rc ../config/run.cfg
