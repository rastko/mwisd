%module histogroup
%{
#include "histogroup.h"
#include "CImg.h"
%}

%include "std_vector.i"
namespace std {
  %template(Vectorf) vector<float>;
  %template(Vectori) vector<int>;
}

%exception compute_from_image_file {
  try {
    $action
  }
  catch(cimg_library::CImgIOException &cioe) {
    static VALUE cimgerror = rb_define_class("HistogroupError", rb_eStandardError);
    rb_raise(cimgerror, cioe.what());
  }
  catch(cimg_library::CImgInstanceException &cie) {
    static VALUE cimgerror = rb_define_class("HistogroupError", rb_eStandardError);
    rb_raise(cimgerror, cie.what());
  }
  catch(cimg_library::CImgException &ce) {
    static VALUE cimgerror = rb_define_class("HistogroupError", rb_eStandardError);
    rb_raise(cimgerror, ce.what());
  }
}

%include "histogroup.h"
