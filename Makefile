# Copyright David Xu, 2016
MAKEFLAGS += --no-builtin-rules # --warn-undefined-variables
.SUFFIXES:

XETEX_ARCHIVE = xetex-0.9999.3.tar.bz2
ifeq ($(realpath $(XETEX_ARCHIVE)),)
$(error XeTeX archive does not exist: $(XETEX_ARCHIVE))
endif

XETEX_SOURCE_DIR = xetex-0.9999.3/

FONTCONFIG_ARCHIVE = fontconfig-2.11.95.tar.gz
FONTCONFIG_SOURCE_DIR = fontconfig-2.11.95/
FONTCONFIG_BUILD_DIR = build-fontconfig/
FONTCONFIG_ARCHIVE_URL = https://www.freedesktop.org/software/fontconfig/release/$(FONTCONFIG_ARCHIVE)

EXPAT_ARCHIVE = expat-2.1.1.tar.bz2
EXPAT_SOURCE_DIR = expat-2.1.1/
EXPAT_BUILD_DIR = build-expat/
EXPAT_ARCHIVE_URL = 'http://downloads.sourceforge.net/project/expat/expat/2.1.1/expat-2.1.1.tar.bz2?r=https%3A%2F%2Fsourceforge.net%2Fprojects%2Fexpat%2F%3Fsource%3Dtyp_redirect&ts=1464668346&use_mirror=tenet'

# Contains native web2c tools used to later compile into JavaScript
NATIVE_DIR = build-native/
JS_DIR = build-js/
XETEX_JS = $(JS_DIR)texk/web2c/xetex

LIB_FREETYPE = $(JS_DIR)libs/freetype2/ft-build/.libs/libfreetype.a
LIB_FONTCONFIG = $(FONTCONFIG_BUILD_DIR)src/.libs/libfontconfig.a

XETEX_CONF =								\
	--enable-compiler-warnings=yes					\
	--disable-all-pkgs						\
	--enable-xetex							\
	--enable-xdvipdfmx						\
	--disable-ptex							\
	--disable-shared						\
	--disable-largefile						\
	--disable-ipc							\
	--enable-silent-rules						\
	--enable-dump-share						\
	--with-fontconfig-includes=$(abspath $(FONTCONFIG_SOURCE_DIR))	\
	--with-fontconfig-libdir=$(abspath $(dir $(LIB_FONTCONFIG)))	\
	--without-system-ptexenc					\
	--without-system-kpathsea					\
	--without-mf-x-toolkit --without-x

# apparently *just* --enable-web2c doesn't work and breaks the xetex build in a cryptic way "Cannot find install.texi"
NATIVE_TOOLS_CONF =				\
	--enable-compiler-warnings=yes		\
	--disable-all-pkgs			\
	--enable-xetex				\
	--disable-ptex				\
	--disable-shared			\
	--disable-largefile			\
	--disable-ipc				\
	--enable-silent-rules			\
	--enable-dump-share			\
	--without-system-ptexenc		\
	--without-system-kpathsea		\
	--without-mf-x-toolkit --without-x

ifdef USE_SYSTEM_LIBS
system_libs_opts =				\
	--with-system-poppler			\
	--with-system-freetype2			\
	--with-system-libpng			\
	--with-system-teckit			\
	--with-system-zlib			\
	--with-system-icu			\
	--with-system-graphite2			\
	--with-system-harfbuzz
NATIVE_TOOLS_CONF += $(system_libs_opts)
XETEX_CONF += $(system_libs_opts)
else
without_system_libs_opts =			\
	--enable-cxx-runtime-hack		\
	--without-system-poppler		\
	--without-system-freetype2		\
	--without-system-libpng			\
	--without-system-teckit			\
	--without-system-zlib			\
	--without-system-icu			\
	--without-system-graphite2		\
	--without-system-harfbuzz
NATIVE_TOOLS_CONF += $(without_system_libs_opts)
XETEX_CONF += $(without_system_libs_opts)
endif


.PHONY: all
all: $(XETEX_JS)

.PHONY: clean
clean:
	rm -rf $(FREETYPE2_SOURCE_DIR) $(FONTCONFIG_DIR)
	rm -rf $(NATIVE_DIR) $(JS_DIR) $(XETEX_SOURCE_DIR) xetex.toplevel

.PHONY: distclean
distclean: clean
	rm -f $(FREETYPE2_ARCHIVE) $(FONTCONFIG_ARCHIVE)
	rm -f $(XETEX_ARCHIVE)

$(EXPAT_ARCHIVE):
	curl -L $(EXPAT_ARCHIVE_URL) -o $@

$(EXPAT_SOURCE_DIR)configure: $(EXPAT_ARCHIVE)
	tar xf $<
	touch $@

$(EXPAT_BUILD_DIR).libs/libexpat.a: $(EXPAT_SOURCE_DIR)configure
	mkdir -p $(EXPAT_BUILD_DIR)
	cd $(EXPAT_BUILD_DIR) && emconfigure $$OLDPWD/$(EXPAT_SOURCE_DIR)configure CFLAGS=-Wno-error=implicit-function-declaration
	emmake $(MAKE) -C $(EXPAT_BUILD_DIR)
	touch $@

$(FONTCONFIG_ARCHIVE):
	curl -L $(FONTCONFIG_ARCHIVE_URL) -o $@

$(FONTCONFIG_SOURCE_DIR)configure: $(FONTCONFIG_ARCHIVE)
	tar xf $<
	patch -p0 < fontconfig-fcstat.c.patch
	patch -p0 < fontconfig-fcint.h.patch
	touch $@

# Use XeTeX's version of libfreetype
$(LIB_FONTCONFIG): $(EXPAT_BUILD_DIR).libs/libexpat.a $(LIB_FREETYPE)
	mkdir -p $(FONTCONFIG_BUILD_DIR)
	cd $(FONTCONFIG_BUILD_DIR) && emconfigure $$OLDPWD/$(FONTCONFIG_SOURCE_DIR)configure --enable-static FREETYPE_CFLAGS="-I$$OLDPWD/$(JS_DIR)libs/freetype2/ -I$$OLDPWD/$(JS_DIR)libs/freetype2/freetype2/" FREETYPE_LIBS=$$OLDPWD/$(LIB_FREETYPE) CFLAGS="-DSIZEOF_VOID_P=4 -I$$OLDPWD/$(EXPAT_SOURCE_DIR)lib/" LDFLAGS=-L$$OLDPWD/$(EXPAT_BUILD_DIR).libs/
	emmake $(MAKE) -C $(FONTCONFIG_BUILD_DIR)
	touch $@

$(XETEX_SOURCE_DIR)build.sh: $(XETEX_ARCHIVE)
	tar xf $<
	patch -p0 < xetex-freetype2-builds-unix-configure.patch
	touch $@

# Unfortunately, web2c is not packaged as standalone anymore, so we need
# reconfigure for the native platform.
$(NATIVE_DIR): $(XETEX_SOURCE_DIR)build.sh
	mkdir -p $@

.PHONY: native
native: $(NATIVE_WEB2C) $(NATIVE_WEB2C_WEB2C)


NATIVE_WEB2C = $(addprefix $(NATIVE_DIR)texk/web2c/, ctangle otangle tangle tangleboot tie)
NATIVE_WEB2C_WEB2C = $(addprefix $(NATIVE_DIR)texk/web2c/web2c/, fixwrites makecpool splitup web2c)
NATIVE_WEB2C_TOOLS = $(NATIVE_WEB2C) $(NATIVE_WEB2C_WEB2C)
NATIVE_ICU_TOOLS = $(addprefix $(NATIVE_DIR)libs/icu/icu-build/bin/, icupkg pkgdata)
NATIVE_TOOLS = $(NATIVE_WEB2C_TOOLS) $(NATIVE_DIR)libs/freetype2/ft-build/apinames

$(NATIVE_TOOLS): native.stamp

.INTERMEDIATE: native.stamp
native.stamp: $(NATIVE_DIR)
	@echo '>>>' Building native XeTeX distribution for compilation tools...)
	mkdir -p $(NATIVE_DIR)
	cd $(NATIVE_DIR) && $$OLDPWD/$(XETEX_SOURCE_DIR)source/configure $(NATIVE_TOOLS_CONF)
	$(MAKE) -C $(NATIVE_DIR)
	$(MAKE) -C $(NATIVE_DIR)libs/freetype2/
	$(MAKE) -C $(sort $(dir $(NATIVE_WEB2C))) $(notdir $(NATIVE_WEB2C))
	$(MAKE) -C $(sort $(dir $(NATIVE_WEB2C_WEB2C))) $(notdir $(NATIVE_WEB2C_WEB2C))
	$(MAKE) -C $(NATIVE_DIR)libs/
	$(MAKE) -C $(NATIVE_DIR)libs/icu/
	$(MAKE) -C $(NATIVE_DIR)libs/icu/icu-build/
	touch $@

$(LIB_FREETYPE): xetex.toplevel
	echo '>>>' Making top-level xetex build directory...
	$(MAKE) -C $(JS_DIR)libs
#	$(MAKE) -C $(JS_DIR)libs/freetype2/

.INTERMEDIATE: xetex.toplevel
xetex.toplevel: $(NATIVE_TOOLS)
	mkdir -p $(JS_DIR)
# We need EMCONFIGURE_JS=2 to pass a configure check for fontconfig libraries
# because we specified JavaScript version of fontconfig in the top-most
# configuration. We need -Wno-error=implicit-function-declaration to get past a
# (v)snprintf configure check in kpathsea. We define SIZEOF_LONG and SIZEOF_INT
# because configure gives an *empty* result when using EMCONFIGURE_JS=2 for some
# reason.
	cd $(JS_DIR) && EMCONFIGURE_JS=2 emconfigure $$OLDPWD/$(XETEX_SOURCE_DIR)source/configure $(XETEX_CONF) CFLAGS='-Wno-error=implicit-function-declaration -DSIZEOF_LONG=4 -DSIZEOF_INT=4'
	if EMCONFIGURE_JS=2 emmake $(MAKE) -C $(JS_DIR); then \
		echo '>>>' Made top-level succesfully.; \
	else \
		echo '>>>' First top-level make attempt failed. && \
		echo '>>>' Replacing freetype2 apinames binary from $(NATIVE_DIR)... && \
		cp --preserve=mode $(NATIVE_DIR)libs/freetype2/ft-build/apinames $(JS_DIR)libs/freetype2/ft-build/apinames && \
		echo '>>>' Restarting top-level make... && \
		EMCONFIGURE_JS=2 emmake $(MAKE) -C $(JS_DIR); \
	fi
	touch $@

# "Inject" native tools used in the compilation
$(XETEX_JS): xetex.toplevel $(NATIVE_TOOLS)
	@echo '>>>' Building XeTeX with Emscripten...
	@echo '>>>' Compiling XeTeX...
	if EMCONFIGURE_JS=2 emmake $(MAKE) -k -C $(JS_DIR)texk/web2c/ $(addprefix -o , $(NATIVE_WEB2C_TOOLS:$(NATIVE_DIR)texk/web2c/%=%)) xetex; then \
		echo '>>>' Done!; \
	else \
		echo '>>>' First XeTeX make attempt failed. && \
		echo '>>>' Replacing icu binaries from $(NATIVE_DIR)... && \
		cp --preserve=mode $(NATIVE_ICU_TOOLS) $(JS_DIR)libs/icu/icu-build/bin/ && \
		echo '>>>' Replacing web2c binaries from $(NATIVE_DIR)... && \
		cp --preserve=mode $(NATIVE_WEB2C) $(JS_DIR)texk/web2c/ && \
		cp --preserve=mode $(NATIVE_WEB2C_WEB2C) $(JS_DIR)texk/web2c/web2c/ && \
		echo '>>>' Restarting XeTeX make... && \
		EMCONFIGURE_JS=2 emmake $(MAKE) -k -C $(JS_DIR)texk/web2c/ $(addprefix -o , $(NATIVE_WEB2C_TOOLS:$(NATIVE_DIR)texk/web2c/%=%)) xetex; \
	fi
