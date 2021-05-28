nasm boot.asm -o boot.bin -l boot.lst 
nasm loader.asm -o loader.bin -l loader.lst 


# mount loader program
sudo su
mount boot.img /media/ -t vfat -o loop
cp loader.bin /media/
sync
umount /media/
# same as : ctrl + d
exit  
