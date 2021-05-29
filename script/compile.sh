nasm ../src/boot.asm -o ../bin/boot.bin -l ../bin/boot.lst 
nasm ../src/loader.asm -o ../bin/loader.bin -l ../bin/loader.lst 


# mount loader program
sudo su
mount ../bin/boot.img /media/ -t vfat -o loop
cp ../bin/loader.bin /media/
sync
umount /media/
# same as : ctrl + d
exit  
