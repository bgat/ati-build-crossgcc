#!/bin/sh

set -x

#LOG="2>&1 | tee -a log"
#JOBS="-j `cat /proc/cpuinfo | grep processor | wc -l`"

TARGET=powerpc-eabi
HOST=i586-mingw32msvc
#HOST=i686-w64-mingw32

SRC=${PWD}/src

GCC2=gcc-3.4.6
GCC=gcc-3.4.6
BINUTILS=binutils-2.19.1
NEWLIB=newlib-1.19.0

# TODO: clean this up so that the directory includes the date
DATEZ=`date -u +%Y%m%d%H%MZ`
WRK=`mktemp -d wrk-${DATEZ}-XXX`
BLD=${PWD}/${WRK}/bld
HST=${PWD}/${WRK}/hst
BPFX=${PWD}/${WRK}/bpfx
HPFX=${PWD}/${WRK}/hpfx

# TODO: do we need HPFX in the PATH?
export PATH=${BPFX}/bin:$PATH

mkdir -p ${BLD} || exit
mkdir -p ${BPFX} || exit
mkdir -p ${HPFX} || exit

echo "WRK=${WRK}"
echo "   BLD=${BLD}"
echo "   PFX=${PFX}"
echo "   JOBS=${JOBS}"


# cross-binutils for build->target
(mkdir -p ${BLD}/binutils && cd ${BLD}/binutils &&
    BUILD=`${SRC}/${BINUTILS}/config.guess` &&
    ${SRC}/${BINUTILS}/configure \
	--prefix=${BPFX} --target=${TARGET} \
	--with-sysroot=${BPFX}/${TARGET} --disable-nls --disable-werror &&
    make ${JOBS} all install
) || exit


# cross gcc-core for build->target
#	--with-headers=${SRC}/${NEWLIB}/newlib/libc/include --with-newlib \
#	--with-sysroot=${BPFX}/${TARGET} --with-local-prefix=${BPFX}/${TARGET} \
(mkdir -p ${BLD}/gcc-core && cd ${BLD}/gcc-core &&
    BUILD=`${SRC}/${GCC2}/config.guess` &&
    ${SRC}/${GCC2}/configure \
	--prefix=${BPFX} --target=${TARGET} \
	--without-headers --with-newlib \
	--disable-nls --enable-threads=no --enable-symvers=gnu --enable-__cxa_atexit \
	--disable-shared --disable-multilib \
	--enable-languages=c &&
    make ${JOBS} all-build-libiberty &&
    make ${JOBS} all-gcc install-gcc
) || exit


# newlib for target
(mkdir -p ${BLD}/newlib && cd ${BLD}/newlib &&
    ${SRC}/${NEWLIB}/configure \
	--prefix=${BPFX} --target=${TARGET} &&
    make ${JOBS} all install
) || exit


# cross gcc for build->target
#	--with-sysroot=${BPFX}/${TARGET} \
(mkdir -p ${BLD}/gcc && cd ${BLD}/gcc &&
    BUILD=`${SRC}/${GCC2}/config.guess` &&
    ${SRC}/${GCC2}/configure \
	--prefix=${BPFX} --target=${TARGET} \
	--with-newlib \
	--with-headers=${BPFX}/${TARGET} \
	--with-local-prefix=${BPFX}/${TARGET} \
	--disable-nls --enable-threads=no --enable-symvers=gnu --enable-__cxa_atexit \
	--disable-shared --disable-multilib \
	--enable-languages=c --with-newlib &&
    make ${JOBS} all install
) || exit


# cross g++ for build->target
(mkdir -p ${BLD}/g++ && cd ${BLD}/g++ &&
    BUILD=`${SRC}/${GCC2}/config.guess` &&
    ${SRC}/${GCC2}/configure \
	--prefix=${BPFX} --target=${TARGET} \
	--with-newlib \
	--with-headers=${BPFX}/${TARGET} \
	--with-local-prefix=${BPFX}/${TARGET} \
	--disable-nls --enable-threads=no --enable-symvers=gnu --enable-__cxa_atexit \
	--disable-shared --disable-multilib \
	--enable-languages="c,c++" --with-newlib &&
    make ${JOBS} all install
) || exit


# ok, with that out of the way...


# TODO: I don't if --with-sysroot is correct in the following

# cross-binutils for host->target
(mkdir -p ${HST}/binutils && cd ${HST}/binutils &&
    BUILD=`${SRC}/${BINUTILS}/config.guess` &&
    ${SRC}/${BINUTILS}/configure \
	--prefix=${HPFX} \
	--build=${BUILD} --host=${HOST} \
	--target=${TARGET} \
	--with-sysroot=${HPFX}/${TARGET} --disable-nls --disable-werror &&
    make ${JOBS} all install
) || exit

 cross gcc-core for host->target
(mkdir -p ${HST}/gcc-core && cd ${HST}/gcc-core &&
    BUILD=`${SRC}/${GCC2}/config.guess` &&
    ${SRC}/${GCC2}/configure \
	--prefix=${HPFX} \
	--build=${BUILD} --host=${HOST} \
	--target=${TARGET} \
	--without-headers --with-newlib \
	--disable-nls --enable-threads=no --enable-symvers=gnu --enable-__cxa_atexit \
	--disable-shared --disable-multilib \
	--enable-languages=c &&
    make ${JOBS} all-build-libiberty &&
    make ${JOBS} all-gcc install-gcc
) || exit


# newlib for target
(mkdir -p ${HST}/newlib && cd ${HST}/newlib &&
    ${SRC}/${NEWLIB}/configure \
	--prefix=${HPFX} --target=${TARGET} &&
    make ${JOBS} all install
) || exit


# cross gcc for host->target
(mkdir -p ${HST}/gcc && cd ${HST}/gcc &&
    BUILD=`${SRC}/${GCC2}/config.guess` &&
    ${SRC}/${GCC2}/configure \
	--prefix=${HPFX} \
	--build=${BUILD} --host=${HOST} \
	--target=${TARGET} \
	--with-newlib \
	--with-headers=${HPFX}/${TARGET} \
	--with-local-prefix=${HPFX}/${TARGET} \
	--disable-nls --enable-threads=no --enable-symvers=gnu --enable-__cxa_atexit \
	--disable-shared --disable-multilib \
	--enable-languages=c --with-newlib &&
    make ${JOBS} all install
) || exit


# cross g++ for build->target
(mkdir -p ${HST}/g++ && cd ${HST}/g++ &&
    BUILD=`${SRC}/${GCC2}/config.guess` &&
    ${SRC}/${GCC2}/configure \
	--prefix=${HPFX} \
	--build=${BUILD} --host=${HOST} \
	--target=${TARGET} \
	--with-newlib \
	--with-headers=${HPFX}/${TARGET} \
	--with-local-prefix=${HPFX}/${TARGET} \
	--disable-nls --enable-threads=no --enable-symvers=gnu --enable-__cxa_atexit \
	--disable-shared --disable-multilib \
	--enable-languages="c,c++" --with-newlib &&
    make ${JOBS} all install
) || exit






### bgat: old stuff is below here
exit




################################################################################################
# the build will happen in the following order
################################################################################################
# build all the linux stuff first
make_binutils_linux=no
make_gcc_core_linux=no
make_newlib_linux=no
# then build all the windows stuff
make_binutils_win32=no
make_gcc_core_win32=yes
make_gcc_win32=no


#export PATH="${PATH}:/home/ati/gccwork.3.4.6/sources/newlib_1.14.0/newlib-1.14.0/newlib/libc/include"




	
LOG_DIR=${PREFIX}/logs
mkdir -pv ${LOG_DIR} || exit
DATEZ="date -u +%Y%m%d%H%MZ"

#================================================================================================
#================================================================================================
#== BUILD THE LINUX EXECUTABLES =================================================================
#================================================================================================
#================================================================================================

#------------------------------------------------------------------------------------------------
#--- BINUTILS LINUX------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------
# configure binary utilities for target
if [ "$make_binutils_linux" = "yes" ]; then

echo; echo "-----> configuring ${BINUTILS} for ${TARGET}"


echo ${BUILD}

exit

# create the build directory
BUILD_DIR=${PREFIX}/build/${TARGET}/${BINUTILS}
rm -rvf ${BUILD_DIR} && mkdir -pv ${BUILD_DIR} || exit

# build a cross-binutils for the build machine
echo; echo "-----> building ${BINUTILS} for ${TARGET}"
cd ${BUILD_DIR} &&
(${SOURCE}/binutils/${BINUTILS}/configure \
  --prefix=${PREFIX} \
  --target=${TARGET} \
  || exit) 2>&1 | tee ${LOG_DIR}/${BINUTILS}-${TARGET}-build-config-`${DATEZ}`.log
make all install 2>&1 | tee ${LOG_DIR}/${BINUTILS}-${TARGET}-build-make-`${DATEZ}`.log || exit
fi

#-- END BINUTILS LINUX---------------------------------------------------------------------------

#------------------------------------------------------------------------------------------------
#---- GCC CORE LINUX ----------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------
# configure core compiler to use to compile newlib
if [ "$make_gcc_core_linux" = "yes" ]; then

echo; echo "-----> configuring core cross-compiler for ${TARGET}"

# create the build directory
BUILD_DIR=${PREFIX}/build/${TARGET}/xgcc-core
rm -rvf ${BUILD_DIR} && mkdir -pv ${BUILD_DIR} || exit

# make sure we build an xgcc for the build machine
echo; echo "-----> buildinging core cross-compiler for ${TARGET}"
cd ${BUILD_DIR} &&
(${SOURCE}/gcc/${GCC}/configure \
  --target=${TARGET} \
  --prefix=${PREFIX} \
#  --enable-languages=c,c++ \
  --without-headers \
  --with-newlib \
  || exit) 2>&1 | tee ${LOG_DIR}/gcc-core-${TARGET}-config-`${DATEZ}`.log
(make all-gcc install-gcc || exit) 2>&1 | tee ${LOG_DIR}/gcc-build-core-${TARGET}-make-`${DATEZ}`.log
fi
#-- END GCC CORE LINUX -------------------------------------------------------------------------

#------------------------------------------------------------------------------------------------
#---- NEWLIB LINUX-------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------
# configure newlib to use with the full cross-compiler
if [ "$make_newlib_linux" = "yes" ]; then

echo; echo "-----> configuring ${NEWLIB} for ${TARGET}"

# create a build directory
BUILD_DIR=${PREFIX}/build/${TARGET}/${NEWLIB}
rm -rvf ${BUILD_DIR} && mkdir -pv ${BUILD_DIR} || exit

# switch to build directory and configure newlib for target
cd ${BUILD_DIR}
(${SOURCE}/newlib/${NEWLIB}/configure \
  --target=${TARGET} \
  --prefix=${PREFIX} \
   || exit) 2>&1 | tee ${LOG_DIR}/${NEWLIB}-${TARGET}-config-`${DATEZ}`.log

# make and install newlib
echo; echo "-----> building ${NEWLIB} for ${TARGET}"
(make all install info install-info || exit ) \
   2>&1 | tee ${LOG_DIR}/${NEWLIB}-${TARGET}-make-`${DATEZ}`.log
fi
#-- END NEWLIB LINUX ---------------------------------------------------------------------------

#================================================================================================
#================================================================================================
#== BUILD THE WINDOWS EXECUTABLES ===============================================================
#================================================================================================
#================================================================================================

#------------------------------------------------------------------------------------------------
#--- BINUTILS WIN32------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------
# configure binary utilities for target
if [ "$make_binutils_win32" = "yes" ]; then

echo; echo "-----> configuring ${BINUTILS} for ${HOST}"

# create the build directory
BUILD_DIR=${PREFIX}/build/${TARGET}/${BINUTILS}
rm -rvf ${BUILD_DIR} && mkdir -pv ${BUILD_DIR} || exit

# switch to build directory and configure
cd ${BUILD_DIR} && 
(${SOURCE}/binutils/${BINUTILS}/configure \
  --prefix=${PREFIX} \
  --target=${TARGET} \
  --host=${HOST} \
  || exit) 2>&1 | tee ${LOG_DIR}/${BINUTILS}-${TARGET}-config-`${DATEZ}`.log

cd ${BUILD_DIR}
# make and install binutils for target
echo; echo "-----> building ${BINUTILS} for ${HOST}"
make all install 2>&1 | tee ${LOG_DIR}/${BINUTILS}-${TARGET}-make-`${DATEZ}`.log || exit
fi
#-- END BINUTILS WIN32---------------------------------------------------------------------------


#------------------------------------------------------------------------------------------------
#---- GCC CORE WIN32-----------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------
# configure core compiler to use to compile newlib
if [ "$make_gcc_core_win32" = "yes" ]; then

echo; echo "-----> configuring core cross-compiler for ${HOST}"

# create the build directory
BUILD_DIR=${PREFIX}/build/${TARGET}/xgcc-core
rm -rvf ${BUILD_DIR} && mkdir -pv ${BUILD_DIR} || exit

# switch to build directory and configure
cd ${BUILD_DIR} && 
(${SOURCE}/gcc/${GCC}/configure \
  --target=${TARGET} \
  --host=${HOST} \
  --prefix=${PREFIX} \
  || exit) 2>&1 | tee ${LOG_DIR}/gcc-core-${TARGET}-config-host-`${DATEZ}`.log

# make and install xgcc core compiler for target
echo; echo "-----> building core cross-compiler for ${HOST}"
(make all-gcc install-gcc || exit) 2>&1 | tee ${LOG_DIR}/gcc-core-${TARGET}-make-`${DATEZ}`.log
 fi
#-- END GCC CORE WIN32 --------------------------------------------------------------------------

 
#------------------------------------------------------------------------------------------------
#---- GCC WIN32----------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------  
if [ "$make_gcc_win32" = "yes" ]; then
# configure the full GCC cross-compiler with newlib for target
echo; echo "-----> configuring ${GCC} cross-compiler for ${HOST}"

# create a build directory
BUILD_DIR=${PREFIX}/build/${TARGET}/xgcc
rm -rvf ${BUILD_DIR} && mkdir -pv ${BUILD_DIR} || exit

# switch to build directory and configure for target
cd ${BUILD_DIR} && 
(${SOURCE}/gcc/${GCC}/configure \
  --target=$TARGET \
  --prefix=${PREFIX} \
  --host=${HOST} \
  --enable-languages=c,c++ \
  --with-newlib  || exit ) \
    2>&1 | tee ${LOG_DIR}/${GCC}-${TARGET}-config-`${DATEZ}`.log

# make and install cross-compiler for target
echo; echo "-----> building ${GCC} cross-compiler for ${HOST}"
(make all install || exit) 2>&1 | tee ${LOG_DIR}/${GCC}-${TARGET}-make-`${DATEZ}`.log
fi
#-- END GCC WIN32--------------------------------------------------------------------------------
