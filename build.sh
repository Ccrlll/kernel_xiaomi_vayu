#!/bin/bash

# Thanks to clhex for the script (Github username: clhexftw)

kernel_dir="${PWD}"
CCACHE=$(command -v ccache)
objdir="${kernel_dir}/out"
builddir="${kernel_dir}/build"
ZIMAGE=$kernel_dir/out/arch/arm64/boot/Image
CLANG_DIR=$HOME/tc/clang
export CONFIG_FILE="vayu_user_defconfig"
export ARCH="arm64"
export KBUILD_BUILD_HOST=ccrlll
export KBUILD_BUILD_USER=home
export PATH="$CLANG_DIR/bin:$PATH"

if ! [ -d "$CLANG_DIR" ]; then
	echo "Toolchain not found! Cloning to $CLANG_DIR..."
	if ! git clone -q --depth=1 --single-branch https://gitlab.com/crdroidandroid/android_prebuilts_clang_host_linux-x86_clang-r536225.git -b 15.0 $CLANG_DIR; then
		echo "Cloning failed! Aborting..."
		exit 1
	fi
fi

# Colors
NC='\033[0m'
LRD='\033[1;31m'
LGR='\033[1;32m'

make_defconfig()
{
	START=$(date +"%s")
	echo -e ${LGR}"########### Generating Defconfig ############"${NC}
	make -s ARCH=${ARCH} O=${objdir} ${CONFIG_FILE} -j$(nproc --all)
}
compile()
{
	cd ${kernel_dir}
	echo -e ${LGR}"######### Compiling kernel #########"${NC}
	make -j$(nproc --all) \
	O=out \
	ARCH=${ARCH}\
	CC="ccache clang" \
	AR="llvm-ar" \
	NM="llvm-nm" \
	LD="ld.lld" \
	OBJCOPY="llvm-objcopy" \
	OBJDUMP="llvm-objdump" \
	STRIP="llvm-strip" \
	CROSS_COMPILE="aarch64-linux-gnu-" \
	CROSS_COMPILE_ARM32="arm-linux-gnueabi-" \
	CROSS_COMPILE_COMPAT="arm-linux-gnueabi-" \
	LLVM=1 \
	LLVM_IAS=1 
}
completion()
{
	cd ${objdir}
	COMPILED_IMAGE=arch/arm64/boot/Image
	COMPILED_DTBO=arch/arm64/boot/dtbo.img
	COMPILED_DTB=arch/arm64/boot/dtb.img
	if [[ -f ${COMPILED_IMAGE} && ${COMPILED_DTBO} && ${COMPILED_DTB} ]]; then
		echo -e ${LGR}"#### build completed successfully (hh:mm:ss) ####"${NC}
	else
		echo -e ${LRD}"#### failed to build some targets (hh:mm:ss) ####"${NC}
	fi
}
zipping()
{
	cd ${kernel_dir}
	if [ -f "zip.sh" ]; then
		chmod +x zip.sh
		./zip.sh
	else
		echo -e ${LRD}"Skipping:${NC} zip.sh do not exist"
	fi
}
make_defconfig
compile
completion
zipping
cd ${kernel_dir}
