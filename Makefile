APRON_INST := $(HOME)/code/git/apron-dist/install/lib
export LD_LIBRARY_PATH := $(APRON_INST)

NCPU := $(shell grep -c processor /proc/cpuinfo)

MAIN = mainClang

TARGETS =					\
	clangaml.dylib				\
	consumer/processor.native		\
	consumer/mainClang.native		\
	consumer/memcad/main/batch.native	\
	consumer/memcad/main/main.native	\
	#

ALL_FILES := $(shell find */ -type f -not -wholename "_build/*" \
	                        -and -not -wholename "ocaml-4.01.0/*" \
	                        -and -not -wholename "big-tests/*" \
				) myocamlbuild.ml Makefile


$(MAIN).native: $(ALL_FILES)
	ocamlbuild -j $(NCPU) $(TARGETS)
	@touch $@

clean:
	ocamlbuild -clean

wc:
	@find */					\
	  -not -wholename "_build/*"		-and	\
	  -not -wholename "plugin/testsuite/*"	-and	\
	  -not -wholename "consumer/memcad/*"	-and	\
	  -type f					\
	  | sort | xargs wc -l


install: $(MAIN).native
	ocamlfind install clang META		\
		_build/clangaml.dylib		\
		_build/clang/*.cm[iox]		\
		_build/clang/*.o		\
		_build/clang/clang/*.mli	\
		_build/clang/clang/ast.ml	\
		_build/util.cm[iox]		\
		_build/util.o

uninstall:
	ocamlfind remove clang

reinstall:
	@$(MAKE) uninstall
	@$(MAKE) install


CPP_FILES := $(shell find */ -type f -wholename "*.cpp" \
	                       -or -wholename "*.h")

cpp_etags: $(CPP_FILES)
	etags -o cpp_etags $(CPP_FILES)

####################################################################
## Testing
####################################################################

ALDOR_PATH = ../github/_build/src/lang/aldor

CPPFLAGS =				\
	-D_GNU_SOURCE			\
	-D_ANALYSING			\
	-DTEST_ALL			\
	-DSTO_USE_MALLOC		\
	-I$(ALDOR_PATH)/compiler	\
	-I$(ALDOR_PATH)/compiler/java

CCFLAGS =				\
	$(CPPFLAGS)			\
	-Wall				\
	-Wextra				\
	-Wfatal-errors			\
	-Wno-unused-function		\
	-Wno-unused-parameter		\
	-Wno-sign-compare		\
	-Wno-missing-field-initializers	\
	#

#CCFLAGS +=				\
	-ansi				\
	-pedantic			\
	#

CLANGFLAGS =				\
	$(CCFLAGS)			\
	-fcolor-diagnostics		\
	-Wno-typedef-redefinition	\
	#

GCCFLAGS =				\
	$(CCFLAGS)			\
	-Wsuggest-attribute=pure	\
	-Wsuggest-attribute=const	\
	-Wsuggest-attribute=noreturn	\
	-Wsuggest-attribute=format	\
	-Wno-empty-body			\
	-Wno-unused-but-set-variable	\
	#

#CLANGFLAGS +=				\
	-Wconversion			\
	-Wno-sign-conversion

check: $(MAIN).native
	#./processor.native -w $(CLANGFLAGS) -include "memcad.h" test.cc -std=c++11
	./processor.native -w $(CLANGFLAGS) -include "memcad.h" test.c

%.test: % $(MAIN).native
	./processor.native -w $(CLANGFLAGS) -include "memcad.h" $<

define testsuite
TESTSUITE.$1 = $2
check-$1: $(MAIN).native
#	./processor.native -w $(CLANGFLAGS) -include "memcad.h" $$(TESTSUITE.$1)
	@echo "make: *** check-$1 target currently not supported; use 'make check-$1-separate'"

check-$1-separate: $$(TESTSUITE.$1:=.test)
endef

BROKEN =					\
	consumer/memcad/bench/atomic-02.c	\
	consumer/memcad/bench/c-micro-10.c	\
	consumer/memcad/bench/typ-03.c

$(eval $(call testsuite,testsuite,$(shell find plugin/testsuite -name "*.[ci]")))
$(eval $(call testsuite,memcad,$(filter-out $(BROKEN),$(wildcard consumer/memcad/bench/*.c))))


####################################################################
## Analyse the Aldor compiler sources
####################################################################

ALDOR_SRC =		\
	java/genjava.c	\
	java/javacode.c	\
	java/javaobj.c	\
	abcheck.c	\
	ablogic.c	\
	abnorm.c	\
	abpretty.c	\
	absub.c		\
	absyn.c		\
	abuse.c		\
	archive.c	\
	axlcomp.c	\
	axlobs.c	\
	axlparse.c	\
	bigint.c	\
	bigint_t.c	\
	bitv.c		\
	bitv_t.c	\
	bloop.c		\
	btree.c		\
	btree_t.c	\
	buffer.c	\
	buffer_t.c	\
	ccode.c		\
	ccode_t.c	\
	ccomp.c		\
	cfgfile.c	\
	cmdline.c	\
	compcfg.c	\
	compopt.c	\
	comsg.c		\
	comsgdb.c	\
	cport.c		\
	cport_t.c	\
	debug.c		\
	depdag.c	\
	dflow.c		\
	dnf.c		\
	dnf_t.c		\
	doc.c		\
	dword.c		\
	emit.c		\
	errorset.c	\
	fbox.c		\
	file.c		\
	file_t.c	\
	fint.c		\
	fintphase.c	\
	flatten.c	\
	float_t.c	\
	flog.c		\
	fluid.c		\
	fluid_t.c	\
	fname.c		\
	fname_t.c	\
	foam.c		\
	foamopt.c	\
	foamsig.c	\
	foam_c.c	\
	foam_cfp.c	\
	foam_i.c	\
	forg.c		\
	format.c	\
	format_t.c	\
	formatters.c	\
	fortran.c	\
	freevar.c	\
	ftype.c		\
	genc.c		\
	gencpp.c	\
	genfoam.c	\
	genlisp.c	\
	gf_add.c	\
	gf_excpt.c	\
	gf_fortran.c	\
	gf_gener.c	\
	gf_implicit.c	\
	gf_imps.c	\
	gf_java.c	\
	gf_prog.c	\
	gf_reference.c	\
	gf_rtime.c	\
	gf_seq.c	\
	gf_syme.c	\
	include.c	\
	inlutil.c	\
	int.c		\
	intset.c	\
	lib.c		\
	linear.c	\
	link_t.c	\
	list.c		\
	list_t.c	\
	loops.c		\
	macex.c		\
	msg.c		\
	msg_t.c		\
	of_argsub.c	\
	of_cfold.c	\
	of_comex.c	\
	of_cprop.c	\
	of_deada.c	\
	of_deadv.c	\
	of_emerg.c	\
	of_env.c	\
	of_hfold.c	\
	of_inlin.c	\
	of_jflow.c	\
	of_killp.c	\
	of_loops.c	\
	of_peep.c	\
	of_retyp2.c	\
	of_rrfmt.c	\
	of_util.c	\
	opsys.c		\
	opsys_t.c	\
	optfoam.c	\
	opttools.c	\
	ostream.c	\
	output.c	\
	parseby.c	\
	path.c		\
	phase.c		\
	priq.c		\
	priq_t.c	\
	scan.c		\
	scobind.c	\
	sefo.c		\
	sexpr.c		\
	simpl.c		\
	spesym.c	\
	srcline.c	\
	srcpos.c	\
	stab.c		\
	stdc.c		\
	store.c		\
	store1_t.c	\
	store2_t.c	\
	store3_t.c	\
	strops.c	\
	strops_t.c	\
	symbol.c	\
	symbol_t.c	\
	symcoinfo.c	\
	syme.c		\
	syscmd.c	\
	table.c		\
	table_t.c	\
	tconst.c	\
	termtype.c	\
	terror.c	\
	test.c		\
	textansi.c	\
	textcolour.c	\
	texthp.c	\
	tfcond.c	\
	tform.c		\
	tfsat.c		\
	timer.c		\
	tinfer.c	\
	ti_bup.c	\
	ti_decl.c	\
	ti_sef.c	\
	ti_tdn.c	\
	ti_top.c	\
	token.c		\
	tposs.c		\
	tqual.c		\
	usedef.c	\
	util.c		\
	util_t.c	\
	version.c	\
	xfloat.c	\
	xfloat_t.c
ALDOR_SRC := $(addprefix $(ALDOR_PATH)/compiler/,$(ALDOR_SRC))
ALDOR_SRC += $(ALDOR_PATH)/tools/frontend/main.c
$(eval $(call testsuite,aldor,$(ALDOR_SRC)))


ANALYSIS_FLAGS =		\
	-w -fsyntax-only	\
	-Xclang -analyze	\
	-Xclang -analyzer-checker=core.NullDereference

prtp: $(MAIN).native
	cd consumer/memcad && \
	  $(realpath batch.native)	\
	    -in-file rt.txt		\
	    -pure-regtest		\
	    -very-silent		\
	    -analyzer $(realpath $(MAIN).native)

analyze-self: $(MAIN).native
	./processor.native $(shell llvm-config-3.4 --cxxflags) -fexceptions -std=c++11 -w -I_build/plugin/c++ -Itools/bridgen/c++ plugin/c++/OCamlVisitor/Expr.cpp

analyze-whopr: aldor.c processor.native
	./processor.native -w $(CLANGFLAGS) aldor.c

analyze-whopr-clang: aldor.c
	clang $(CLANGFLAGS) $(ANALYSIS_FLAGS) $< 2>&1 | tee analysis.log

compile-whopr-clang: aldor.c
	clang $(CLANGFLAGS) -fsyntax-only $<

compile-whopr-gcc: aldor.c
	gcc $(GCCFLAGS) -fsyntax-only $<

compile-whopr-fcc: aldor.c
	../github/_install/bin/fcc1 -cflags "$(GCCFLAGS)" $<

preprocess-whopr-clang: aldor.c
	clang $(CPPFLAGS) -E $< -o aldor.i

preprocess-whopr-gcc: aldor.c
	gcc $(CPPFLAGS) -E $< -o aldor.i

aldor.c: $(ALDOR_SRC)
	:> $@
	for f in $^; do				\
		echo "#line 1 \"$$f\"" >> $@;	\
		cat $$f >> $@;			\
	done
