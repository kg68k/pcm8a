# Makefile for pcm8a

ifeq ($(notdir $(CURDIR)),src)
$(error do not execute make in src directory)
endif

AS	= has060
ASFLAGS	=
LD	= hlk
LDFLAGS	=

BINDIR	= /usr/local/bin
MANDIR	= /usr/local/man/cat1

SRCS	= pcm8a.s
OBJS	= $(SRCS:.s=.o)
PCM8A_X	= pcm8a.x
DOCS	= pcm8a.doc pcm8atec.doc pcm8avup.doc README.md

DIST_ZIP = pcm8a.zip
ARCS	= $(DIST_ZIP)

all: $(PCM8A_X)


$(DIST_ZIP): $(DOCS) $(PCM8A_X)
	rm -f $@
	zip -9 $@ $^

$(SRC_ZIP): Makefile $(SRCS)
	rm -f $@
	zip -9 $@ $^


$(PCM8A_X): $(OBJS)
	$(LD) $(LDFLAGS) -o $@ $(OBJS)

%.o: %.s
	$(AS) $(ASFLAGS) $<


install:
	cp -p $(PCM8A_X) $(BINDIR)
	cp -p $(DOCS) $(MANDIR)

clean:
	rm -f $(PCM8A_X) $(OBJS) $(ARCS)


# EOF
