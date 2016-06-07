# Copyright David Xu, 2016
#
# Permission is hereby granted, free of charge, to any person obtaining a copy,
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
MAKEFLAGS += --no-builtin-rules # --warn-undefined-variables
.SUFFIXES:

# Uncomment to use the system installation of TeX Live to build xelatex.fmt.
# USE_SYSTEM_TL = 1

# Contains native builds of tools used later when compiling to JavaScript
NATIVE_BUILD_DIR = build-native/
EMSCRIPTEN_BUILD_DIR = build-js/
SOURCES_DIR = build-sources/

VERBOSE_LOG = $(abspath make.log)
$(info Standard output from configure and recursive make calls will be sent to $(VERBOSE_LOG).)

# We separately define the sizes and alignments of integer types. Otherwise,
# when setting EMCONFIGURE_JS=2, configure silently passes with an *empty*
# result. This happens because configure writes integer sizes to a file, but
# Emscripten does not come with persistent filesystem support by default. This
# is the simplest way to pass these configure checks. We need EMCONFIGURE_JS=2
# in some places to pass other configure checks that look for symbol
# definitions in Emscripten-compiled libraries.
JS_CONFIG_SITE = config.site
JS_CONFIG_SITE_ABS = $(realpath $(JS_CONFIG_SITE))
ifeq ($(JS_CONFIG_SITE_ABS),)
$(error Cannot find JS_CONFIG_SITE: $(JS_CONFIG_SITE))
endif

XETEX_JS = xetex.js
XELATEX_JS = xelatex.js
XETEX_BUILD_DIR = $(EMSCRIPTEN_BUILD_DIR)build-xetex/
XETEX_BC = $(XETEX_BUILD_DIR)texk/web2c/xetex

XETEX_ARCHIVE = xetex-0.9999.3.tar.bz2
XETEX_SOURCE_DIR = $(SOURCES_DIR)xetex-0.9999.3/
XETEX_ARCHIVE_URL = 'http://downloads.sourceforge.net/project/xetex/source/xetex-0.9999.3.tar.bz2?r=https%3A%2F%2Fsourceforge.net%2Fprojects%2Fxetex%2F&ts=1464938493&use_mirror=netassist'

FONTCONFIG_ARCHIVE = fontconfig-2.11.95.tar.gz
FONTCONFIG_SOURCE_DIR = $(SOURCES_DIR)fontconfig-2.11.95/
FONTCONFIG_BUILD_DIR = $(EMSCRIPTEN_BUILD_DIR)build-fontconfig/
FONTCONFIG_ARCHIVE_URL = https://www.freedesktop.org/software/fontconfig/release/$(FONTCONFIG_ARCHIVE)

EXPAT_ARCHIVE = expat-2.1.1.tar.bz2
EXPAT_SOURCE_DIR = $(SOURCES_DIR)expat-2.1.1/
EXPAT_BUILD_DIR = $(EMSCRIPTEN_BUILD_DIR)build-expat/
EXPAT_ARCHIVE_URL = 'http://downloads.sourceforge.net/project/expat/expat/2.1.1/expat-2.1.1.tar.bz2?r=https%3A%2F%2Fsourceforge.net%2Fprojects%2Fexpat%2F%3Fsource%3Dtyp_redirect&ts=1464668346&use_mirror=tenet'

LATEX_BASE_ARCHIVE = base.zip
LATEX_BASE_SOURCE_DIR = base/
LATEX_BASE_ARCHIVE_URL = http://mirrors.ctan.org/macros/latex/base.zip

INSTALL_TL_UNX_ARCHIVE = install-tl-unx.tar.gz
INSTALL_TL_UNX_ARCHIVE_URL = http://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz

# The Emscripten site recommends that we generate .so files over .a files...
LIB_FREETYPE = $(XETEX_BUILD_DIR)libs/freetype2/ft-build/.libs/libfreetype.a
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
# FIXME: These flags don't seem to disable multithreading.
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
	--with-freetype2-libdir=$(abspath $(XETEX_BUILD_DIR)libs/freetype2/)		\
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
all: $(XETEX_JS) $(XELATEX_JS) xetex.worker.js xelatex.fmt texlive.lst

.PHONY: texlive-manifest
texlive-manifest: texlive.lst

.PHONY: confirm-clean
confirm-clean:
	@while :; do							\
		read -p 'Really clean (yes/no)? ' choice;		\
		case "$$choice" in					\
	  		yes|ye|y|YES|YE|Y) exit;;			\
	  		n|N|no|NO) exit -1;;				\
	  		* ) echo -n 'Please enter either yes or no. ';;	\
		esac;							\
	done
	@while :; do							\
		read -p 'Are you absolutely sure (yes/no)? ' choice;	\
		case "$$choice" in					\
	  		yes|ye|y|YES|YE|Y) exit;;			\
	  		n|N|no|NO) exit -1;;				\
	  		* ) echo -n 'Please enter either yes or no. ';;	\
		esac;							\
	done

.PHONY: clean-js
clean-js: confirm-clean
	rm -rf $(EMSCRIPTEN_BUILD_DIR)
	rm -rf build-js-xetex-configured.stamp build-js-xetex-toplevel.stamp
	rm -f xetex.bc $(XETEX_JS) $(XETEX_JS).mem $(XELATEX_JS) $(XELATEX_JS).mem xetex.worker.js xetex.worker.js.mem
	rm -f $(VERBOSE_LOG)

.PHONY: clean
clean: clean-js
	rm -rf $(LATEX_BASE_SOURCE_DIR)
	rm -rf texlive/ install-tl* texlive-basic.profile texlive-basic.stamp texlive-full.profile texlive-full.stamp
	rm -rf xetex/
	rm -rf $(NATIVE_BUILD_DIR) $(SOURCES_DIR)

.PHONY: distclean
distclean: clean
	rm -f $(LATEX_BASE_ARCHIVE)
	rm -f $(INSTALL_TL_UNX_ARCHIVE)
	rm -f $(EXPAT_ARCHIVE) $(FONTCONFIG_ARCHIVE)
	rm -f $(XETEX_ARCHIVE)

$(SOURCES_DIR):
	mkdir -p $@

$(XETEX_ARCHIVE):
	curl -L $(XETEX_ARCHIVE_URL) -o $@

$(XETEX_SOURCE_DIR)build.sh: $(XETEX_ARCHIVE)
	tar xf $< -C $(SOURCES_DIR)
	test -s $@ && touch $@

$(EXPAT_ARCHIVE):
	curl -L $(EXPAT_ARCHIVE_URL) -o $@

$(EXPAT_SOURCE_DIR)configure: $(EXPAT_ARCHIVE) | $(SOURCES_DIR)
	tar xf $< -C $(SOURCES_DIR)
	test -s $@ && touch $@

$(LIB_EXPAT): $(EXPAT_SOURCE_DIR)configure
	mkdir -p $(EXPAT_BUILD_DIR)
	cd $(EXPAT_BUILD_DIR) && emconfigure $$OLDPWD/$(EXPAT_SOURCE_DIR)configure CFLAGS=-Wno-error=implicit-function-declaration >> $(VERBOSE_LOG)
	emmake $(MAKE) -C $(EXPAT_BUILD_DIR) >> $(VERBOSE_LOG)
	test -s $@ && touch $@

$(FONTCONFIG_ARCHIVE):
	curl -L $(FONTCONFIG_ARCHIVE_URL) -o $@

$(FONTCONFIG_SOURCE_DIR)configure: $(FONTCONFIG_ARCHIVE) | $(SOURCES_DIR)
	tar xf $< -C $(SOURCES_DIR)
	cd $(SOURCES_DIR) && patch -p0 < $$OLDPWD/fontconfig-fcstat.c.patch
	test -s $@ && touch $@

# Use XeTeX's version of libfreetype that we compiled to JS. We need
# EMCONFIGURE_JS=2 to pass a configure check for fontconfig libraries because we
# specified the JavaScript version of fontconfig in the top-most configuration.
$(LIB_FONTCONFIG): $(FONTCONFIG_SOURCE_DIR)configure $(LIB_EXPAT) $(LIB_FREETYPE)
	mkdir -p $(FONTCONFIG_BUILD_DIR)
	cd $(FONTCONFIG_BUILD_DIR) && EMCONFIGURE_JS=2 CONFIG_SITE=$(JS_CONFIG_SITE_ABS) emconfigure $$OLDPWD/$(FONTCONFIG_SOURCE_DIR)configure --disable-static FREETYPE_CFLAGS="-I$$OLDPWD/$(XETEX_BUILD_DIR)libs/freetype2/ -I$$OLDPWD/$(XETEX_BUILD_DIR)libs/freetype2/freetype2/" FREETYPE_LIBS=$$OLDPWD/$(LIB_FREETYPE) CFLAGS=-I$$OLDPWD/$(EXPAT_SOURCE_DIR)lib/ LDFLAGS=-L$$OLDPWD/$(EXPAT_BUILD_DIR).libs/ >> $(VERBOSE_LOG)
	emmake $(MAKE) -C $(FONTCONFIG_BUILD_DIR) >> $(VERBOSE_LOG)
	test -s $@ && touch $@

NATIVE_WEB2C = $(addprefix $(NATIVE_BUILD_DIR)texk/web2c/, ctangle otangle tangle tangleboot tie)
NATIVE_WEB2C_WEB2C = $(addprefix $(NATIVE_BUILD_DIR)texk/web2c/web2c/, fixwrites makecpool splitup web2c)
NATIVE_WEB2C_TOOLS = $(NATIVE_WEB2C) $(NATIVE_WEB2C_WEB2C)
NATIVE_ICU_TOOLS = $(addprefix $(NATIVE_BUILD_DIR)libs/icu/icu-build/bin/, icupkg pkgdata)
NATIVE_TOOLS = $(NATIVE_WEB2C_TOOLS) $(NATIVE_BUILD_DIR)libs/freetype2/ft-build/apinames
NATIVE_XETEX = $(NATIVE_BUILD_DIR)texk/web2c/xetex

.PHONY: native-tools
native-tools: $(NATIVE_TOOLS)

$(NATIVE_TOOLS): native-tools.stamp

.INTERMEDIATE: native-tools.stamp
native-tools.stamp: $(XETEX_SOURCE_DIR)build.sh
	@echo '>>>' Building native XeTeX distribution for compilation tools...
	mkdir -p $(NATIVE_BUILD_DIR)
	cd $(NATIVE_BUILD_DIR) && $$OLDPWD/$(XETEX_SOURCE_DIR)source/configure $(NATIVE_TOOLS_CONF)
	$(MAKE) -C $(NATIVE_BUILD_DIR) >> $(VERBOSE_LOG)
	$(MAKE) -C $(NATIVE_BUILD_DIR)libs/freetype2/ >> $(VERBOSE_LOG)
	$(MAKE) -C $(sort $(dir $(NATIVE_WEB2C))) $(notdir $(NATIVE_WEB2C)) >> $(VERBOSE_LOG)
	$(MAKE) -C $(sort $(dir $(NATIVE_WEB2C_WEB2C))) $(notdir $(NATIVE_WEB2C_WEB2C)) >> $(VERBOSE_LOG)
	$(MAKE) -C $(NATIVE_BUILD_DIR)libs/ >> $(VERBOSE_LOG)
	$(MAKE) -C $(NATIVE_BUILD_DIR)libs/icu/ >> $(VERBOSE_LOG)
	$(MAKE) -C $(NATIVE_BUILD_DIR)libs/icu/icu-build/ >> $(VERBOSE_LOG)

$(NATIVE_XETEX): native-tools.stamp
	$(MAKE) -C $(NATIVE_BUILD_DIR)texk/web2c/ xetex >> $(VERBOSE_LOG)

$(LIB_FREETYPE): build-js-xetex-configured.stamp $(NATIVE_BUILD_DIR)libs/freetype2/ft-build/apinames
	echo '>>>' Building xetex libraries...
	if ! emmake $(MAKE) -C $(XETEX_BUILD_DIR)libs >> $(VERBOSE_LOG); then \
		echo '>>>' First make attempt for xetex libraries failed. && \
		echo '>>>' Replacing freetype2 apinames binary from $(NATIVE_BUILD_DIR)... && \
		cp --preserve=mode $(NATIVE_BUILD_DIR)libs/freetype2/ft-build/apinames $(XETEX_BUILD_DIR)libs/freetype2/ft-build/apinames && \
		emmake $(MAKE) -C $(XETEX_BUILD_DIR)libs >> $(VERBOSE_LOG); \
	fi

# We need -Wno-error=implicit-function-declaration to get past a (v)snprintf
# configure check in kpathsea. We define ELIDE_CODE to avoid duplicate symbols
# in kpathsea's own version of getopts.
build-js-xetex-configured.stamp: $(XETEX_SOURCE_DIR)build.sh
	@echo '>>>' Configuring xetex...
	mkdir -p $(XETEX_BUILD_DIR)
	cd $(XETEX_BUILD_DIR) && CONFIG_SITE=$(JS_CONFIG_SITE_ABS) EMCONFIGURE_JS=2 emconfigure $$OLDPWD/$(XETEX_SOURCE_DIR)source/configure $(XETEX_CONF) CFLAGS='-Wno-error=implicit-function-declaration -DELIDE_CODE' >> $(VERBOSE_LOG)
	touch $@

build-js-xetex-toplevel.stamp: build-js-xetex-configured.stamp $(LIB_FONTCONFIG)
	@echo '>>>' Building xetex top level...
	CONFIG_SITE=$(JS_CONFIG_SITE_ABS) EMCONFIGURE_JS=2 emmake $(MAKE) -C $(XETEX_BUILD_DIR) >> $(VERBOSE_LOG)
	touch $@

# "Inject" native tools used in the compilation
$(XETEX_BC): build-js-xetex-toplevel.stamp $(NATIVE_TOOLS)
	@echo '>>>' Building xetex...
	if EMCONFIGURE_JS=2 emmake $(MAKE) -k -C $(XETEX_BUILD_DIR)texk/web2c/ $(addprefix -o , $(NATIVE_WEB2C_TOOLS:$(NATIVE_BUILD_DIR)texk/web2c/%=%)) xetex >> $(VERBOSE_LOG); then \
		echo '>>>' Done!; \
	else \
		echo '>>>' First xetex make attempt failed. && \
		echo '>>>' Replacing icu binaries from $(NATIVE_BUILD_DIR)... && \
		cp --preserve=mode $(NATIVE_ICU_TOOLS) $(XETEX_BUILD_DIR)libs/icu/icu-build/bin/ && \
		echo '>>>' Warning: Using stub data for libicudata.a because compilation of assembly section is not directly supported by emcc. && \
		cp $(XETEX_BUILD_DIR)libs/icu/icu-build/stubdata/libicudata.a $(XETEX_BUILD_DIR)libs/icu/icu-build/lib/libicudata.a && \
		echo '>>>' Replacing web2c binaries from $(NATIVE_BUILD_DIR)... && \
		cp --preserve=mode $(NATIVE_WEB2C) $(XETEX_BUILD_DIR)texk/web2c/ && \
		cp --preserve=mode $(NATIVE_WEB2C_WEB2C) $(XETEX_BUILD_DIR)texk/web2c/web2c/ && \
		echo '>>>' Restarting XeTeX make... && \
		EMCONFIGURE_JS=2 emmake $(MAKE) -C $(XETEX_BUILD_DIR)texk/web2c/ $(addprefix -o , $(NATIVE_WEB2C_TOOLS:$(NATIVE_BUILD_DIR)texk/web2c/%=%)) xetex >> $(VERBOSE_LOG); \
	fi
	EMCONFIGURE_JS=2 emmake $(MAKE) -C $(XETEX_BUILD_DIR)texk/web2c/ $(addprefix -o , $(NATIVE_WEB2C_TOOLS:$(NATIVE_BUILD_DIR)texk/web2c/%=%)) xetex >> $(VERBOSE_LOG)

xetex.bc: $(XETEX_BC)
	cp $< $@

xetex.worker.js: xetex.bc xetex.pre.worker.js xetex.post.worker.js
#	emcc -O2 --closure 1 --pre-js xetex.pre.worker.js --post-js xetex.post.worker.js -s ASSERTIONS=2 -s INVOKE_RUN=0 -s TOTAL_MEMORY=536870912 xetex.bc -o $@
	emcc -g -O2 --pre-js xetex.pre.worker.js --post-js xetex.post.worker.js -s ASSERTIONS=2 -s EMULATE_FUNCTION_POINTER_CASTS=1 -s SAFE_HEAP=1 -s ALIASING_FUNCTION_POINTERS=0 -s INVOKE_RUN=0 -s TOTAL_MEMORY=536870912 xetex.bc -o $@

$(XETEX_JS): xetex.bc xetex.pre.js
	emcc -O2 --closure 1 -s TOTAL_MEMORY=536870912 xetex.bc -o $@

$(XELATEX_JS): $(XETEX_JS)
	cp $< $@

###############################################################################
# xelatex.fmt
###############################################################################
$(LATEX_BASE_ARCHIVE):
	curl -L $(LATEX_BASE_ARCHIVE_URL) -o $@

$(LATEX_BASE_SOURCE_DIR): $(LATEX_BASE_ARCHIVE)
	unzip -o $<
	test -d $@ && touch $@

# Remember that we need to set argv[0] to xelatex when we invoke xetex.
xelatex.fmt: $(LATEX_BASE_SOURCE_DIR)latex.fmt
	cp $< $@

ifdef USE_SYSTEM_TL

$(LATEX_BASE_SOURCE_DIR)latex.fmt: $(LATEX_BASE_SOURCE_DIR)
	TEXINPUTS=$(LATEX_BASE_SOURCE_DIR) xetex -ini -etex -output-directory=$(LATEX_BASE_SOURCE_DIR) unpack.ins
	TEXINPUTS=$(LATEX_BASE_SOURCE_DIR): xetex -ini -etex -output-directory=$(LATEX_BASE_SOURCE_DIR) latex.ltx

else

$(LATEX_BASE_SOURCE_DIR)latex.fmt: $(LATEX_BASE_SOURCE_DIR) $(NATIVE_XETEX) texlive-full.stamp
	TEXINPUTS=$(LATEX_BASE_SOURCE_DIR) $(NATIVE_XETEX) -ini -etex -output-directory=$(LATEX_BASE_SOURCE_DIR) unpack.ins
	TEXMF=texlive-full/texmf-dist//: TEXMFCNF=texlive-full/:texlive-full/texmf-dist/web2c/ TEXINPUTS=$(LATEX_BASE_SOURCE_DIR): $(NATIVE_XETEX) -ini -etex -output-directory=$(LATEX_BASE_SOURCE_DIR) latex.ltx

endif # USE_SYSTEM_TL


###############################################################################
# TeX Live
###############################################################################
$(INSTALL_TL_UNX_ARCHIVE):
	curl -L $(INSTALL_TL_UNX_ARCHIVE_URL) -o $@

# Create a manifest file for the texlive distribution. This manifest file is
# later consulted via XHR in the example to load the texlive tree for kpathsea.
# This part can be easily customized to your liking.
.DELETE_ON_ERROR: texlive.lst
texlive.lst: texlive-basic.stamp
	find texlive-basic -type d -exec echo -e {}/ \; > $@
	find texlive-basic/ -type f -exec echo {} \; >> $@

texlive-basic.stamp: $(INSTALL_TL_UNX_ARCHIVE)
	mkdir -p texlive-basic/
# prepare a profile to install texlive
	echo selected_scheme scheme-basic > texlive-basic.profile
	echo TEXDIR texlive-basic/ >> texlive-basic.profile
	echo TEXMFLOCAL texlive-basic/texmf-local >> texlive-basic.profile
	echo TEXMFSYSVAR texlive-basic/texmf-var >> texlive-basic.profile
	echo TEXMFSYSCONFIG texlive-basic/texmf-config >> texlive-basic.profile
	echo TEXMFVAR texlive-basic/texmf-var >> texlive-basic.profile
# Now install texlive locally. This is a kludge that will break if there are
# multiple install-tl-XXXFDATEXXX directories that were previously extracted.
	tar xf $(INSTALL_TL_UNX_ARCHIVE)
	install-tl-*/install-tl -profile texlive-basic.profile
# Clean out unneeded files
	rm -rf texlive-basic/bin/ texlive-basic/tlpkg/ texlive-basic/texmf-dist/doc/ texlive-basic/texmf-var/doc/ texlive-basic/readme-html.dir/ texlive-basic/readme-txt.dir/ texlive-basic/index.html texlive-basic/doc.html texlive-basic/install-tl.log
	find texlive-basic/ -executable -type f -exec rm {} +
	touch $@

texlive-full.stamp: $(INSTALL_TL_UNX_ARCHIVE)
	mkdir -p texlive-full/
# prepare a profile to install texlive
	echo selected_scheme scheme-full > texlive-full.profile
	echo TEXDIR `pwd`/texlive-full/ >> texlive-full.profile
	echo TEXMFLOCAL `pwd`/texlive-full/texmf-local >> texlive-full.profile
	echo TEXMFSYSVAR `pwd`/texlive-full/texmf-var >> texlive-full.profile
	echo TEXMFSYSCONFIG `pwd`/texlive-full/texmf-config >> texlive-full.profile
	echo TEXMFVAR `pwd`/texlive-full/texmf-var >> texlive-full.profile
# Now install texlive locally. This is a kludge that will break if there are
# multiple install-tl-XXXFDATEXXX directories that were previously extracted.
	tar xf $(INSTALL_TL_UNX_ARCHIVE)
	install-tl-*/install-tl -profile texlive-full.profile
# Clean out unneeded files
	rm -rf texlive-full/bin/ texlive-full/tlpkg/ texlive-full/texmf-dist/doc/ texlive-full/texmf-var/doc/ texlive-full/readme-html.dir/ texlive-full/readme-txt.dir/ texlive-full/index.html texlive-full/doc.html texlive-full/install-tl.log
	find texlive-full/ -executable -type f -exec rm {} +
	touch $@
