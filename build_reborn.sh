#!/bin/bash
# Script to build flashable RebornKernel zip for jalebi

BUILD_START=$(date +"%s")

# Colours
blue='\033[0;34m'
cyan='\033[0;36m'
yellow='\033[0;33m'
red='\033[0;31m'
nocol='\033[0m'

# Kernel details
KERNEL_NAME="RebornKernel"
VERSION="X1-Phoenix"
DATE=$(date +"%d-%m-%Y")
DEVICE="jalebi"
FINAL_ZIP=$KERNEL_NAME-$VERSION-$DATE-$DEVICE.zip
defconfig=reborn_jalebi_defconfig

# Toolchain repo
TC_REPO="https://github.com/dev-harsh1998/GCC_BUILDS"

# Dirs
KERNEL_DIR=$(pwd)
ANYKERNEL_DIR=$KERNEL_DIR/AnyKernel2
KERNEL_IMG=$KERNEL_DIR/out/arch/arm/boot/zImage
DT_IMAGE=$KERNEL_DIR/out/arch/arm/boot/dt.img
UPLOAD_DIR=$KERNEL_DIR/OUTPUT/$DEVICE
DTBTOOL=$KERNEL_DIR/tools/dtbToolCM
TOOLCHAIN=$KERNEL_DIR/tc

# Export
export ARCH=arm
export SUBARCH=arm
export CROSS_COMPILE=$TOOLCHAIN/bin/arm-eabi-
export KBUILD_BUILD_USER="ThePhoenix"
export KBUILD_BUILD_USER="AllSpark"

if [ ! -d "$TOOLCHAIN" ]; then git clone -b kek $TC_REPO $TOOLCHAIN; fi

## Functions ##

# Make kernel
function make_kernel() {
  mkdir out
  echo -e "$cyan***********************************************"
  echo -e "          Initializing defconfig          "
  echo -e "***********************************************$nocol"
  make $defconfig O=out
  echo -e "$cyan***********************************************"
  echo -e "             Building kernel          "
  echo -e "***********************************************$nocol"
  make -j`nproc --all` O=out
  if ! [ -a $KERNEL_IMG ];
  then
    echo -e "$red Kernel Compilation failed! Fix the errors! $nocol"
    exit 1
  fi
}

# Make DT.IMG
function make_dt(){
$DTBTOOL -2 -o $DT_IMAGE -s 2048 -p $KERNEL_DIR/scripts/dtc/ $KERNEL_DIR/out/arch/arm/boot/dts/
}

# Making zip
function make_zip() {
mkdir -p tmp_mod
make -j16 modules_install INSTALL_MOD_PATH=tmp_mod INSTALL_MOD_STRIP=1
find tmp_mod/ -name '*.ko' -type f -exec cp '{}' $ANYKERNEL_DIR/modules/system/lib/modules/ \;
cp $KERNEL_IMG $ANYKERNEL_DIR
cp $DT_IMAGE $ANYKERNEL_DIR
mkdir -p $UPLOAD_DIR
cd $ANYKERNEL_DIR
zip -r9 UPDATE-AnyKernel2.zip * -x README UPDATE-AnyKernel2.zip
mv $ANYKERNEL_DIR/UPDATE-AnyKernel2.zip $UPLOAD_DIR/$FINAL_ZIP
mv $ANYKERNEL_DIR/UPDATE-AnyKernel2.zip $UPLOAD_DIR/$FINAL_ZIP
rm -rf $KERNEL_DIR/tmp_mod
cd $UPLOAD_DIR
}

# Options
function options() {
echo -e "$cyan***********************************************"
  echo "               Compiling RebornKernel                "
  echo -e "***********************************************$nocol"
  echo -e " "
  echo -e " Select one of the following types of build : "
  echo -e " 1.Dirty"
  echo -e " 2.Clean"
  echo -n " Your choice : ? "
  read ch

  echo -e " Select if you want zip or just kernel : "
  echo -e " 1.Get flashable zip"
  echo -e " 2.Get kernel only"
  echo -n " Your choice : ? "
  read ziporkernel

case $ch in
  1) echo -e "$cyan***********************************************"
     echo -e "          	Dirty          "
     echo -e "***********************************************$nocol"
     make_kernel
     make_dt ;;
  2) echo -e "$cyan***********************************************"
     echo -e "          	Clean          "
     echo -e "***********************************************$nocol"
     make clean
     make mrproper
     rm -rf tmp_mod
     make_kernel
     make_dt ;;
esac

if [ "$ziporkernel" = "1" ]; then
     echo -e "$cyan***********************************************"
     echo -e "     Making flashable zip        "
     echo -e "***********************************************$nocol"
     make_zip
else
     echo -e "$cyan***********************************************"
     echo -e "     Building Kernel only        "
     echo -e "***********************************************$nocol"
fi
}

# Clean Up
function cleanup(){
rm -rf $KERNEL_IMG
rm -rf $DT_IMAGE
rm -rf $ANYKERNEL_DIR/modules/system/lib/modules/*.ko
}

options
cleanup
BUILD_END=$(date +"%s")
DIFF=$(($BUILD_END - $BUILD_START))
echo -e "$yellow Build completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds.$nocol"
