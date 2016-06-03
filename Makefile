# Copyright David Xu, 2016
MAKEFLAGS += --no-builtin-rules # --warn-undefined-variables
.SUFFIXES:

VERBOSE_LOG = make.log
$(info Standard output from configure and recursive make calls will be sent to $(VERBOSE_LOG).)

JS_CONFIG_SITE = config.site
JS_CONFIG_SITE_ABS = $(realpath $(JS_CONFIG_SITE))
ifeq ($(JS_CONFIG_SITE_ABS),)
$(error Cannot find JS_CONFIG_SITE: $(JS_CONFIG_SITE))
endif

XETEX_ARCHIVE = xetex-0.9999.3.tar.bz2
XETEX_SOURCE_DIR = xetex-0.9999.3/
XETEX_ARCHIVE_URL = 'http://downloads.sourceforge.net/project/xetex/source/xetex-0.9999.3.tar.bz2?r=https%3A%2F%2Fsourceforge.net%2Fprojects%2Fxetex%2F&ts=1464938493&use_mirror=netassist'

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
XETEX_BC = $(JS_DIR)texk/web2c/xetex

# The Emscripten site recommends that we generate .so files over .a files...
LIB_FREETYPE = $(JS_DIR)libs/freetype2/ft-build/.libs/libfreetype.a
LIB_EXPAT = $(EXPAT_BUILD_DIR).libs/libexpat.a
# Using libfontconfig.a mysteriously fails with:
# ```AssertionError: Failed to run LLVM optimizations:```
LIB_FONTCONFIG = $(FONTCONFIG_BUILD_DIR)src/.libs/libfontconfig.so

# Copied from xetex/build.sh.
#
# We use xetex's own freetype2 configuration. In order to do that, we build
# libs/freetype2 first before building the rest of the tree. We also explicitly
# hack in the dependency on libexpat.
#
# Pass --disable-threads to propagate down to the ICU library.
# Pass --disable-multithreaded to propagate down the poppler library.
XETEX_CONF =										\
	--enable-compiler-warnings=yes							\
	--disable-all-pkgs								\
	--enable-xetex									\
	--enable-xdvipdfmx								\
	--disable-ptex									\
	--disable-native-texlive-build							\
	--disable-largefile								\
	--disable-ipc									\
	--disable-threads								\
	--disable-multithreaded								\
	--enable-silent-rules								\
	--enable-dump-share								\
	--with-fontconfig-includes=$(abspath $(FONTCONFIG_SOURCE_DIR))			\
	--with-fontconfig-libdir='$(abspath $(dir $(LIB_FONTCONFIG)))			\
		-L$(abspath $(dir $(LIB_EXPAT))) -lfontconfig -lexpat'			\
	--with-freetype2-includes=$(abspath						\
		$(XETEX_SOURCE_DIR)source/libs/freetype2/freetype-2.4.11/include/)	\
	--with-freetype2-libdir=$(abspath $(JS_DIR)libs/freetype2/)			\
	--without-system-ptexenc							\
	--without-system-kpathsea							\
	--without-mf-x-toolkit --without-x

# Apparently *just* --enable-web2c doesn't work and breaks the xetex build in a
# cryptic way "Cannot find install.texi"
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
all: xetex.js

.PHONY: clean-js
clean-js:
	rm -rf $(EXPAT_SOURCE_DIR) $(EXPAT_BUILD_DIR)
	rm -rf $(FONTCONFIG_SOURCE_DIR) $(EXPAT_BUILD_DIR)
	rm -rf xetex-configured.stamp xetex-toplevel.stamp $(JS_DIR)
	rm $(VERBOSE_LOG)

.PHONY: clean
clean: clean-js
	rm -rf native.stamp $(NATIVE_DIR) $(XETEX_SOURCE_DIR)

.PHONY: distclean
distclean: clean
	rm -f $(EXPAT_ARCHIVE) $(FONTCONFIG_ARCHIVE)
	rm -f $(XETEX_ARCHIVE)

$(XETEX_ARCHIVE):
	curl -L $(XETEX_ARCHIVE_URL) -o $@

.SECONDARY: $(XETEX_SOURCE_DIR)build.sh
$(XETEX_SOURCE_DIR)build.sh: $(XETEX_ARCHIVE)
	tar xf $<
	test -s $@ && touch $@

$(EXPAT_ARCHIVE):
	curl -L $(EXPAT_ARCHIVE_URL) -o $@

.SECONDARY: $(EXPAT_SOURCE_DIR)configure
$(EXPAT_SOURCE_DIR)configure: $(EXPAT_ARCHIVE)
	tar xf $<
	test -s $@ && touch $@

$(LIB_EXPAT): $(EXPAT_SOURCE_DIR)configure
	mkdir -p $(EXPAT_BUILD_DIR)
	cd $(EXPAT_BUILD_DIR) && emconfigure $$OLDPWD/$(EXPAT_SOURCE_DIR)configure CFLAGS=-Wno-error=implicit-function-declaration >> $(VERBOSE_LOG)
	emmake $(MAKE) -C $(EXPAT_BUILD_DIR) >> $(VERBOSE_LOG)
	test -s $@ && touch $@

$(FONTCONFIG_ARCHIVE):
	curl -L $(FONTCONFIG_ARCHIVE_URL) -o $@

.SECONDARY: $(FONTCONFIG_SOURCE_DIR)configure
$(FONTCONFIG_SOURCE_DIR)configure: $(FONTCONFIG_ARCHIVE)
	tar xf $<
	patch -p0 < fontconfig-fcstat.c.patch
	patch -p0 < fontconfig-fcint.h.patch
	test -s $@ && touch $@

# Use XeTeX's version of libfreetype
$(LIB_FONTCONFIG): $(FONTCONFIG_SOURCE_DIR)configure $(LIB_EXPAT) $(LIB_FREETYPE)
	mkdir -p $(FONTCONFIG_BUILD_DIR)
# Uses SIZEOF_VOID_P overriden in config.site
	cd $(FONTCONFIG_BUILD_DIR) && CONFIG_SITE=$(JS_CONFIG_SITE_ABS) emconfigure $$OLDPWD/$(FONTCONFIG_SOURCE_DIR)configure --disable-static FREETYPE_CFLAGS="-I$$OLDPWD/$(JS_DIR)libs/freetype2/ -I$$OLDPWD/$(JS_DIR)libs/freetype2/freetype2/" FREETYPE_LIBS=$$OLDPWD/$(LIB_FREETYPE) CFLAGS=-I$$OLDPWD/$(EXPAT_SOURCE_DIR)lib/ LDFLAGS=-L$$OLDPWD/$(EXPAT_BUILD_DIR).libs/ >> $(VERBOSE_LOG)
	emmake $(MAKE) -C $(FONTCONFIG_BUILD_DIR) >> $(VERBOSE_LOG)
	test -s $@ && touch $@

.SECONDARY: $(XETEX_SOURCE_DIR)build.sh
$(XETEX_SOURCE_DIR)build.sh: $(XETEX_ARCHIVE)
	tar xf $<
	patch -p0 < xetex-freetype2-builds-unix-configure.patch
	test -s $@ && touch $@

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
	@echo '>>>' Building native XeTeX distribution for compilation tools...
	mkdir -p $(NATIVE_DIR)
	cd $(NATIVE_DIR) && $$OLDPWD/$(XETEX_SOURCE_DIR)source/configure $(NATIVE_TOOLS_CONF)
	$(MAKE) -C $(NATIVE_DIR) >> $(VERBOSE_LOG)
	$(MAKE) -C $(NATIVE_DIR)libs/freetype2/ >> $(VERBOSE_LOG)
	$(MAKE) -C $(sort $(dir $(NATIVE_WEB2C))) $(notdir $(NATIVE_WEB2C)) >> $(VERBOSE_LOG)
	$(MAKE) -C $(sort $(dir $(NATIVE_WEB2C_WEB2C))) $(notdir $(NATIVE_WEB2C_WEB2C)) >> $(VERBOSE_LOG)
	$(MAKE) -C $(NATIVE_DIR)libs/ >> $(VERBOSE_LOG)
	$(MAKE) -C $(NATIVE_DIR)libs/icu/ >> $(VERBOSE_LOG)
	$(MAKE) -C $(NATIVE_DIR)libs/icu/icu-build/ >> $(VERBOSE_LOG)
	touch $@

$(LIB_FREETYPE): xetex-configured.stamp
	echo '>>>' Building xetex libraries...
	if ! emmake $(MAKE) -C $(JS_DIR)libs >> $(VERBOSE_LOG); then \
		echo '>>>' First make attempt for xetex libraries failed. && \
		echo '>>>' Replacing freetype2 apinames binary from $(NATIVE_DIR)... && \
		cp --preserve=mode $(NATIVE_DIR)libs/freetype2/ft-build/apinames $(JS_DIR)libs/freetype2/ft-build/apinames && \
		emmake $(MAKE) -C $(JS_DIR)libs >> $(VERBOSE_LOG); \
	fi

# We need EMCONFIGURE_JS=2 to pass a configure check for fontconfig libraries
# because we specified JavaScript version of fontconfig in the top-most
# configuration. We need -Wno-error=implicit-function-declaration to get past a
# (v)snprintf configure check in kpathsea. We define ELIDE_CODE to avoid
# duplicate symbols in kpathsea's own version of getopts. We define SIZEOF_LONG
# and SIZEOF_INT in a config.site because configure gives an *empty* result.
# This happens because we did not especially compile and mount a filesystem, and
# it would be a hassle just for this configure check.

.SECONDARY: xetex-configured.stamp
xetex-configured.stamp:
	@echo '>>>' Configuring xetex...
	mkdir -p $(JS_DIR)
	cd $(JS_DIR) && CONFIG_SITE=$(JS_CONFIG_SITE_ABS) EMCONFIGURE_JS=2 emconfigure $$OLDPWD/$(XETEX_SOURCE_DIR)source/configure $(XETEX_CONF) CFLAGS='-Wno-error=implicit-function-declaration -DELIDE_CODE' >> $(VERBOSE_LOG)
	touch $@

.SECONDARY: xetex-toplevel.stamp
xetex-toplevel.stamp: xetex-configured.stamp $(LIB_FONTCONFIG) $(NATIVE_TOOLS)
	@echo '>>>' Building xetex top level...
	CONFIG_SITE=$(JS_CONFIG_SITE_ABS) EMCONFIGURE_JS=2 emmake $(MAKE) -C $(JS_DIR) >> $(VERBOSE_LOG)
	touch $@

# "Inject" native tools used in the compilation
$(XETEX_BC): xetex-toplevel.stamp $(NATIVE_TOOLS)
	@echo '>>>' Building xetex...
	if EMCONFIGURE_JS=2 emmake $(MAKE) -k -C $(JS_DIR)texk/web2c/ $(addprefix -o , $(NATIVE_WEB2C_TOOLS:$(NATIVE_DIR)texk/web2c/%=%)) xetex >> $(VERBOSE_LOG); then \
		echo '>>>' Done!; \
	else \
		echo '>>>' First xetex make attempt failed. && \
		echo '>>>' Replacing icu binaries from $(NATIVE_DIR)... && \
		cp --preserve=mode $(NATIVE_ICU_TOOLS) $(JS_DIR)libs/icu/icu-build/bin/ && \
		echo '>>>' Warning: Using stub data for libicudata.a because compilation of assembly section is not directly supported by emcc. && \
		cp $(JS_DIR)libs/icu/icu-build/stubdata/libicudata.a $(JS_DIR)libs/icu/icu-build/lib/libicudata.a && \
		echo '>>>' Replacing web2c binaries from $(NATIVE_DIR)... && \
		cp --preserve=mode $(NATIVE_WEB2C) $(JS_DIR)texk/web2c/ && \
		cp --preserve=mode $(NATIVE_WEB2C_WEB2C) $(JS_DIR)texk/web2c/web2c/ && \
		echo '>>>' Restarting XeTeX make... && \
		EMCONFIGURE_JS=2 emmake $(MAKE) -C $(JS_DIR)texk/web2c/ $(addprefix -o , $(NATIVE_WEB2C_TOOLS:$(NATIVE_DIR)texk/web2c/%=%)) xetex >> $(VERBOSE_LOG); \
	fi
	EMCONFIGURE_JS=2 emmake $(MAKE) -C $(JS_DIR)texk/web2c/ $(addprefix -o , $(NATIVE_WEB2C_TOOLS:$(NATIVE_DIR)texk/web2c/%=%)) xetex >> $(VERBOSE_LOG)

xetex.js: $(XETEX_BC)
	cp $< xetex.bc
	emcc -O2 xetex.bc -o $@
