#$1 is the first parameter
# imput the name without suffix of asm file

#  ./boot.sh boot
#nasm boot.asm -o boot.bin -l.lst 
nasm $1.asm -o $1.bin -l $1.lst 

dd if=$1.bin of=$1.img bs=512 count=1 conv=notrunc

# -q    skip the "Bochs Configuration Main menu"
# -f    to define a configuration file 
# -rc   
bochs -q -f ./bochsrc.properties -rc ./run.cfg