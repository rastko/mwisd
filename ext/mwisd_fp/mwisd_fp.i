%module mwisd_fp
%{
#include "mwisd_fp.h"
#include "CImg.h"
%}

%include "stdint.i"
%include "std_vector.i"
namespace std {
  %template(Vectori) vector<int>;
}

%exception compute_from_image_file {
  try {
    $action
  }
  catch(cimg_library::CImgIOException &cioe) {
    static VALUE cimgerror = rb_define_class("Mwisd_fpError", rb_eStandardError);
    rb_raise(cimgerror, cioe.what());
  }
  catch(cimg_library::CImgInstanceException &cie) {
    static VALUE cimgerror = rb_define_class("Mwisd_fpError", rb_eStandardError);
    rb_raise(cimgerror, cie.what());
  }
  catch(cimg_library::CImgException &ce) {
    static VALUE cimgerror = rb_define_class("Mwisd_fpError", rb_eStandardError);
    rb_raise(cimgerror, ce.what());
  }
}

%include "mwisd_fp.h"
