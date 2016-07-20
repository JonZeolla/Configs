#	Contents from Hal Pomeranz (hal@deer-run.com)
#	No warranty expressed or implied.
#	Distributed under the Creative Commons "Attribution" (CC BY) License
#	See https://creativecommons.org/licenses/

GENKEYS         = /usr/local/cronjobs/dnssec/genkeys
DNSSEC_SIGNZONE = /usr/local/sbin/dnssec-signzone
DLV             =

INSTALLDIR      = /var/named/chroot/master
PKILL           = /usr/bin/pkill

SDIR = ../signed
KDIR = ../keys
TDIR = ../tmp

TARGETS := $(patsubst %.db, %.signed, $(wildcard *.db))

all:: dirs $(TARGETS)

install:: all
	cp ${SDIR}/*.signed ${INSTALLDIR}
	${PKILL} -HUP named

dirs: ${SDIR} ${KDIR} ${TDIR}

%.key : 
	@${GENKEYS} $(patsubst K%.curr.key, %, $@)

%.tmp : %.db K%.curr.key
	@cp $*.db ${TDIR}/$@
	@chmod 644 ${TDIR}/$@
	@for key in ${KDIR}/K$*.*.key; do echo \$$include $$key >>${TDIR}/$@; done

%.signed : %.tmp
	${DNSSEC_SIGNZONE} -N unixtime ${DLV} -o $* -d ${SDIR} -f ${SDIR}/$@ -k ${KDIR}/K$*.ksk ${TDIR}/$*.tmp ${KDIR}/K$*.curr

vpath %.signed ${SDIR}
vpath %.key ${KDIR}
vpath %.tmp ${TDIR}

${SDIR}:
	@if [ ! -d "${SDIR}" ]; then mkdir -m 700 ${SDIR}; fi

${KDIR}:
	@if [ ! -d "${KDIR}" ]; then mkdir -m 700 ${KDIR}; fi

${TDIR}:
	@if [ ! -d "${TDIR}" ]; then mkdir -m 700 ${TDIR}; fi

