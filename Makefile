# libdvdnav Makefile

include config.mak

.SUFFIXES: .so

AR=ar
LD=ld
RANLIB=ranlib

VPATH+= $(SRC_PATH_BARE)/src
SRCS = dvdnav.c highlight.c navigation.c read_cache.c remap.c searching.c settings.c

VPATH+= $(SRC_PATH_BARE)/src/vm
SRCS+= decoder.c vm.c vmcmd.c

HEADERS = src/dvd_types.h src/dvdnav.h src/dvdnav_events.h

CFLAGS += $(USEDEBUG) -Wall -funsigned-char
CFLAGS += -I$(CURDIR) -I$(SRC_PATH)/src -I$(SRC_PATH)/src/vm
CFLAGS += -DDVDNAV_COMPILE -D_FILE_OFFSET_BITS=64 -D_LARGEFILE64_SOURCE
CFLAGS += -DHAVE_CONFIG_H -DHAVE_DLFCN_H

L=libdvdnav
MINI_L=libdvdnavmini
ifeq ($(DVDREAD),internal)
DVDREAD_L=libdvdread
DVDREAD_LIB = $(DVDREAD_L).a
DVDREAD_SHLIB = $(DVDREAD_L).so
VPATH+= $(SRC_PATH_BARE)/src/libdvdread
DVDREAD_HEADERS = src/libdvdread/dvd_reader.h \
	src/libdvdread/ifo_print.h \
	src/libdvdread/ifo_read.h \
	src/libdvdread/ifo_types.h \
	src/libdvdread/nav_print.h \
	src/libdvdread/nav_read.h \
	src/libdvdread/dvd_udf.h \
	src/libdvdread/nav_types.h \
	src/libdvdread/bitreader.h
DVDREAD_SRCS = dvd_input.c dvd_reader.c dvd_udf.c ifo_print.c ifo_read.c \
	md5.c nav_print.c nav_read.c bitreader.c
CFLAGS += -I$(SRC_PATH)/src/libdvdread
else
CFLAGS += -I$(DVDREAD_DIR)
endif

LIB = $(L).a
SHLIB = $(L).so
MINI_SHLIB = $(MINI_L).so

.OBJDIR=        obj
DEPFLAG = -M

OBJS = $(patsubst %.c,%.o, $(SRCS))
DVDREAD_OBJS = $(patsubst %.c,%.o, $(DVDREAD_SRCS))
SHOBJS = $(patsubst %.c,%.so, $(SRCS))
DVDREAD_SHOBJS = $(patsubst %.c,%.so, $(DVDREAD_SRCS))
DEPS= ${OBJS:%.o=%.d}
DVDREAD_DEPS= ${DVDREAD_OBJS:%.o=%.d}

BUILDDEPS = Makefile config.mak

ifeq ($(BUILD_SHARED),yes)
all:	$(SHLIB) $(MINI_SHLIB) $(DVDREAD_SHLIB) dvdnav-config dvdread-config
install: $(SHLIB) $(DVDREAD_SHLIB) install-shared install-dvdnav-config install-dvdread-config
endif

ifeq ($(BUILD_STATIC),yes)
all:	$(LIB) $(DVDREAD_LIB) dvdnav-config dvdread-config
install: $(LIB) $(DVDREAD_LIB) install-static install-dvdnav-config install-dvdread-config
endif

install: install-headers

# Let version.sh create version.h

SVN_ENTRIES = $(SRC_PATH_BARE)/.svn/entries
ifeq ($(wildcard $(SVN_ENTRIES)),$(SVN_ENTRIES))
version.h: $(SVN_ENTRIES)
endif

version.h:
	sh $(SRC_PATH)/version.sh $(SRC_PATH) "$(SHLIB_VERSION)"
	
$(SRCS) $(DVDREAD_SRCS): version.h


# General targets

$(.OBJDIR):
	mkdir $(.OBJDIR)

${LIB}: version.h $(.OBJDIR) $(OBJS) $(BUILDDEPS)
	cd $(.OBJDIR) && $(AR) rc $@ $(OBJS)
	cd $(.OBJDIR) && $(RANLIB) $@
ifeq ($(DVDREAD),internal)
${DVDREAD_LIB}: version.h $(.OBJDIR) $(DVDREAD_OBJS) $(BUILDDEPS)
	cd $(.OBJDIR) && $(AR) rc $@ $(DVDREAD_OBJS)
	cd $(.OBJDIR) && $(RANLIB) $@
endif

ifeq ($(DVDREAD),internal)
${SHLIB}: version.h $(.OBJDIR) $(SHOBJS) $(BUILDDEPS) $(DVDREAD_SHLIB)
	cd $(.OBJDIR) && $(CC) $(SHLDFLAGS) -L. -Wl,-soname=$(SHLIB).$(SHLIB_MAJOR) -o $@ $(SHOBJS) -ldvdread $(THREADLIB)
else
${SHLIB}: version.h $(.OBJDIR) $(SHOBJS) $(BUILDDEPS)
	cd $(.OBJDIR) && $(CC) $(SHLDFLAGS) -Wl,-soname=$(SHLIB).$(SHLIB_MAJOR) -o $@ $(SHOBJS) -ldvdread $(THREADLIB)
endif
${MINI_SHLIB}: version.h $(.OBJDIR) $(SHOBJS) $(BUILDDEPS)
	cd $(.OBJDIR) && $(CC) $(SHLDFLAGS) -Wl,-soname=$(MINI_SHLIB).$(SHLIB_MAJOR) -o $@ $(SHOBJS) $(THREADLIB)
ifeq ($(DVDREAD),internal)
${DVDREAD_SHLIB}: version.h $(.OBJDIR) $(DVDREAD_SHOBJS) $(BUILDDEPS)
	cd $(.OBJDIR) && $(CC) $(SHLDFLAGS) -ldl -Wl,-soname=$(DVDREAD_SHLIB).$(SHLIB_MAJOR) -o $@ $(DVDREAD_SHOBJS)
endif

.c.so:	$(BUILDDEPS)
	cd $(.OBJDIR) && $(CC) -fPIC -DPIC -MD $(CFLAGS) -c -o $@ $<

.c.o:	$(BUILDDEPS)
	cd $(.OBJDIR) && $(CC) -MD $(CFLAGS) -c -o $@ $<


# Install targets

install-headers:
	install -d $(DESTDIR)$(incdir)
	install -m 644 $(HEADERS) $(DESTDIR)$(incdir)
ifeq ($(DVDREAD),internal)
	install -d $(DESTDIR)$(dvdread_incdir)
	install -m 644 $(DVDREAD_HEADERS) $(DESTDIR)$(dvdread_incdir)
endif

install-shared: $(SHLIB)
	install -d $(DESTDIR)$(shlibdir)

	install $(INSTALLSTRIP) -m 755 $(.OBJDIR)/$(SHLIB) \
		$(DESTDIR)$(shlibdir)/$(SHLIB).$(SHLIB_VERSION)
	install $(INSTALLSTRIP) -m 755 $(.OBJDIR)/$(MINI_SHLIB) \
		$(DESTDIR)$(shlibdir)/$(MINI_SHLIB).$(SHLIB_VERSION)

	cd $(DESTDIR)$(shlibdir) && \
		ln -sf $(SHLIB).$(SHLIB_VERSION) $(SHLIB).$(SHLIB_MAJOR)
	cd $(DESTDIR)$(shlibdir) && \
		ln -sf $(MINI_SHLIB).$(SHLIB_VERSION) $(MINI_SHLIB).$(SHLIB_MAJOR)
	cd $(DESTDIR)$(shlibdir) && \
		ln -sf $(SHLIB).$(SHLIB_MAJOR) $(SHLIB)
	cd $(DESTDIR)$(shlibdir) && \
		ln -sf $(MINI_SHLIB).$(SHLIB_MAJOR) $(MINI_SHLIB)

ifeq ($(DVDREAD),internal)
	install $(INSTALLSTRIP) -m 755 $(.OBJDIR)/$(DVDREAD_SHLIB) \
		$(DESTDIR)$(shlibdir)/$(DVDREAD_SHLIB).$(SHLIB_VERSION)
	cd $(DESTDIR)$(shlibdir) && \
		ln -sf $(DVDREAD_SHLIB).$(SHLIB_VERSION) $(DVDREAD_SHLIB).$(SHLIB_MAJOR)
	cd $(DESTDIR)$(shlibdir) && \
		ln -sf $(DVDREAD_SHLIB).$(SHLIB_MAJOR) $(DVDREAD_SHLIB)
endif

install-static: $(LIB)
	install -d $(DESTDIR)$(libdir)

	install $(INSTALLSTRIP) -m 755 $(.OBJDIR)/$(LIB) $(DESTDIR)$(libdir)/$(LIB)
ifeq ($(DVDREAD),internal)
	install $(INSTALLSTRIP) -m 755 $(.OBJDIR)/$(DVDREAD_LIB) $(DESTDIR)$(libdir)/$(DVDREAD_LIB)
endif


# Clean targets

clean:
	rm -rf  *~ $(.OBJDIR) version.h


distclean: clean
	find . -name "*~" | xargs rm -rf
	rm -rf config.mak

dvdnav-config: $(.OBJDIR)
	@echo '#!/bin/sh' > $(.OBJDIR)/dvdnav-config
	@echo 'prefix='$(PREFIX) >> $(.OBJDIR)/dvdnav-config
	@echo 'libdir='$(shlibdir) >> $(.OBJDIR)/dvdnav-config
	@echo 'version='$(SHLIB_VERSION) >> $(.OBJDIR)/dvdnav-config
	@echo 'dvdread='$(DVDREAD) >> $(.OBJDIR)/dvdnav-config
	@echo 'dvdreaddir='$(DVDREAD_DIR) >> $(.OBJDIR)/dvdnav-config
	@echo 'threadlib='$(THREADLIB) >> $(.OBJDIR)/dvdnav-config
	@echo >> $(.OBJDIR)/dvdnav-config
	cat $(SRC_PATH_BARE)/misc/dvdnav-config2.sh >> $(.OBJDIR)/dvdnav-config
	chmod 0755 $(.OBJDIR)/dvdnav-config

install-dvdnav-config: dvdnav-config
	install -d $(DESTDIR)$(PREFIX)/bin
	install -m 0755 $(.OBJDIR)/dvdnav-config $(DESTDIR)$(PREFIX)/bin/dvdnav-config

dvdread-config: $(.OBJDIR)
	@echo '#!/bin/sh' > $(.OBJDIR)/dvdread-config
	@echo 'prefix='$(PREFIX) >> $(.OBJDIR)/dvdread-config
	@echo 'libdir='$(shlibdir) >> $(.OBJDIR)/dvdread-config
	@echo 'version='$(SHLIB_VERSION) >> $(.OBJDIR)/dvdread-config
	@echo >> $(.OBJDIR)/dvdread-config
	cat $(SRC_PATH_BARE)/misc/dvdread-config.sh >> $(.OBJDIR)/dvdread-config
	chmod 0755 $(.OBJDIR)/dvdread-config

install-dvdread-config: dvdread-config
	install -d $(DESTDIR)$(PREFIX)/bin
	install -m 0755 $(.OBJDIR)/dvdread-config $(DESTDIR)$(PREFIX)/bin/dvdread-config

vpath %.so ${.OBJDIR}
vpath %.o ${.OBJDIR}
vpath ${LIB} ${.OBJDIR}

# include dependency files if they exist
$(addprefix ${.OBJDIR}/, ${DEPS}): ;
-include $(addprefix ${.OBJDIR}/, ${DEPS})
