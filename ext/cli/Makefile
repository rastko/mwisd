CXXFLAGS =	-O2 -g -Wall -fmessage-length=0 -fPIC

MW_OBJS =	mwisd_fp_gen.o mwisd_fp_cmp.o mwisd_fp.o mwisd_fp_wrap.o \
		mwisd_fp.so mwisd_fp.bundle

HG_OBJS =	histogroup_gen.o histogroup_cmp.o histogroup.o histogroup_wrap.o \
		histogroup.so histogroup.bundle

INCLUDES =	-I../mwisd_fp -I../histogroup \
		-I../../extern/ -I/opt/local/include \
		-I/usr/X11/include -I/usr/local/include

LIBS =		-L../mwisd_fp -L../histogroup \
		-L/opt/local/lib -L/usr/X11/lib -L/usr/local/lib \
		-lm -lpthread -ltiff -ljpeg -lpng

MW_EXECS =	mwisd_fp_gen mwisd_fp_cmp
MW_TARGETS =	$(MW_EXECS) mwisd_fp_wrap.cxx

HG_EXECS =	histogroup_gen histogroup_cmp
HG_TARGETS =	$(HG_EXECS) histogroup_wrap.cxx

VPATH =	%.cpp ../mwisd_fp ../histogroup
#VPATH =	%.cpp ../histogroup

# Ensure that SWIG v2.0.x is being used.
SWIGCMD = `sh -c 'for swigcmd in swig /opt/local/bin/swig swig2.0 ; do if [ x"\`$$swigcmd -version | grep Version | sed "s/SWIG Version //" | sed "s/\.[0-9]*$$//"\`" = x"2.0" ] ; then echo "$$swigcmd" ; break ; fi ; done'`


all:	$(MW_TARGETS) $(HG_TARGETS)
.SUFFIXES: .cpp .o .cxx .i
.PHONY:	mwisd_fp histogroup

mwisd_fp:	$(MW_TARGETS)

histogroup:	$(HG_TARGETS)



mwisd_fp_gen:	mwisd_fp_gen.o mwisd_fp.o
	$(CXX) -o mwisd_fp_gen mwisd_fp_gen.o mwisd_fp.o $(LIBS)

mwisd_fp_cmp:	mwisd_fp_cmp.o mwisd_fp.o
	$(CXX) -o mwisd_fp_cmp mwisd_fp_cmp.o mwisd_fp.o $(LIBS)

mwisd_fp_wrap.cxx:
	@echo "Using $(SWIGCMD) to generate mwisd_fp_wrap.cxx..."
	cd ../mwisd_fp; $(SWIGCMD) -c++ -ruby mwisd_fp.i

histogroup_gen:	histogroup_gen.o histogroup.o
	$(CXX) -o histogroup_gen histogroup_gen.o histogroup.o $(LIBS)

histogroup_cmp:	histogroup_cmp.o histogroup.o
	$(CXX) -o histogroup_cmp histogroup_cmp.o histogroup.o $(LIBS)

histogroup_wrap.cxx:
	@echo "Using $(SWIGCMD) to generate histogroup_wrap.cxx..."
	cd ../histogroup; $(SWIGCMD) -c++ -ruby histogroup.i

install:	all
	cp $(MW_TARGETS) ../../bin
	cp $(HG_TARGETS) ../../bin

clean:
	rm -f $(MW_OBJS) $(HG_OBJS) $(MW_EXECS) $(HG_EXECS)

cleanall:	clean
	rm -f ../mwisd_fp/mwisd_fp_wrap.cxx mwisd_fp.bundle mwisd_fp.so
	rm -f ../histogroup/histogroup_wrap.cxx histogroup.bundle histogroup.so


.cpp.o:
	$(CXX) $(CXXFLAGS) $(INCLUDES) -c $<

.i.cxx:
	$(SWIGCMD) -c++ -ruby $<
