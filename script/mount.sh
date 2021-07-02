# mount loader program
# 有待改进
#sudo su
mount ./bin/boot.img /media/ -t vfat -o loop
cp ./bin/loader.bin /media/
sync
umount /media/
#exit
# same as : ctrl + d

