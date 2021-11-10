#!/bin/sh
ROOT=$(pwd)
IMAGE=$ROOT/bin/boot.img

if [ ! -f "$IMAGE" ]; then
    echo "Creating $IMAGE"
    bximage -mode=create -fd=1.44M -q $IMAGE
fi

if [ ! -d "$ROOT/bin" ]; then
    midir -p $ROOT/bin
fi 

if [ ! -d "$ROOT/obj" ]; then
    midir -p $ROOT/obj
fi 
