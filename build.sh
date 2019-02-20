#!/bin/bash
#
# Script to compile RebornKernel Image for lettuce
#
export ARCH=arm
export SUBARCH=arm
export CROSS_COMPILE=$(pwd)/gcc8/bin/arm-eabi-

git clone -b kek https://github.com/dev-harsh1998/GCC_BUILDS/ gcc8

rm -rf out
mkdir -p out
make O=out reborn_jalebi_defconfig
make O=out -j16
