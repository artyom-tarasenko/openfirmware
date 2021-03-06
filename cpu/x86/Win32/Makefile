# Wrapper makefile for x86 Unix: FreeBSD, Linux, etc.

BP=../../..

# Flags for the OS and CPU
MFLAGS = -m32

OPT = -O
CFLAGS	= -g ${MFLAGS} -DTARGET_X86
LFLAGS = ${MFLAGS}

# Uncomment these lines to include X windows support to the wrapper
# via libxcb.  The libxcb development package (headers, etc) must be
# present on your compilation machine for this to work.
# CFLAGS += -DUSE_XCB
# LIBS += -lxcb
# OBJS += xcbifce.o

WRTAIL = forth/wrapper
WRDIR = ${BP}/${WRTAIL}

ifdef OMIT_ZIP
ZIPDIR = ${WRDIR}
ZIPOBJS = nullzip.o
INFLATEBIN =
else
ZIPTAIL = ${WRTAIL}/zip
ZIPDIR = ${BP}/${ZIPTAIL}

ZIPOBJS = adler32.o compress.o crc32.o deflate.o inflate.o trees.o zutil.o

endif

OBJS += wrapper.o logger.o ${ZIPOBJS}

all: forth x86forth.exe ../build/inflate.bin

# Use forth when you just need to run Forth but don't care what
# native instruction set it is on.
# Use x86forth when you need to compile new dictionaries that will
# run on x86 systems.
forth: ${OBJS}
	${CC} ${MFLAGS} -o $@ ${OBJS} ${LIBS}
	@ln -sf forth.exe x86forth.exe

xinflate.lo: ${ZIPDIR}/inflate.c
	${CC} -c ${MFLAGS} -Wall -fno-builtin -fno-stack-protector -ffreestanding -DNEED_BCOPY -O2 -fpic $< -o $@

# xinflate.o: xinflate.lo
# 	# ${LD} -melf_i386 -T inflate.ld $< -o $@
# 	${LD} -T inflate.ld $< -o $@

../build/inflate.bin: inflate.o
	objcopy -O binary $< $@

%.o: ${WRDIR}/%.c
	${CC} -c ${OPT} ${CFLAGS} $< -o $@

%.o: ${ZIPDIR}/%.c
	${CC} -c ${OPT} ${CFLAGS} -I${ZIPDIR} $< -o $@

# ARM simulator wrapper build rules

ARMDIR = ${BP}/cpu/arm
ARMCFLAGS = -g ${MFLAGS} -DARMSIM -DTARGET_ARM -DARM -DSIMNEXT
ARMSIMOBJS = wrapsim.o armsim.o logger.o ${ZIPOBJS}
ARMTRACEOBJS = wrapsim.o armsim.trace.o logger.o ${ZIPOBJS}

%.o: ${ARMDIR}/%.c
	${CC} -c ${ARMCFLAGS} $< -o $@

wrapsim.o: ${WRDIR}/wrapper.c
	${CC} -c ${ARMCFLAGS} -c $< -o $@

armsim.trace.o: ${ARMDIR}/armsim.c
	${CC} -c ${ARMCFLAGS} -DTRACE=1 -c $< -o $@

armforth: ${ARMSIMOBJS}
	${CC} ${LFLAGS} ${ARMSIMOBJS} -o $@

armforth.trace: ${ARMTRACEOBJS}
	${CC} ${LFLAGS} ${ARMTRACEOBJS}  -o $@

clean:
	@rm -f forth x86forth armforth *.o *.lo *~ inflate.bin
