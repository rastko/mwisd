//============================================================================
// Name        : mwisd_fp.h
// Author      : Stipple, Inc., Appliomics, LLC
// Version     : 3.0.3
// Copyright   : Copyright 2012, Stipple, Inc.
// Description : Implements Marr Wavelet (image sequence discriminating)
//               fingerprinting for images; for use in the Stipple platform.
//============================================================================

#ifndef MWISD_FP_H_
#define MWISD_FP_H_

#include <stdint.h>
#include <vector>

// CImg-related settings
#define cimg_debug 0
#define cimg_display 0
#define cimg_verbosity 1
// Reminder:  libjpeg, libpng, libtiff are not installed by default on OS X
#define cimg_use_jpeg
#define cimg_use_png
#define cimg_use_tiff

#ifdef UNUSED_SWIG
// Tell SWIG to treat uint16_t* as a special case.
%typemap(in) uint16_t* {
  int size = RARRAY($input)->len;
  int i;
  $1 = (int *) malloc(size * sizeof(uint16_t));
  VALUE *ptr = RARRAY($input)->ptr;
  for( i=0; i < size; i++, ptr++ )
    $1[i]= (uint16_t)NUM2INT(*ptr);
}

// Clean up the int* array created before the function call.
%typemap(freearg) uint16_t* {
 free((uint16_t*) $1);
}
#endif


// Definition of mwisd_fp::namespace
namespace mwisd_fp {

const int default_hash_size_in_bytes = 128;


int compute_image_hash(const char *filename, uint16_t* &hash, \
        int hash_size_in_bytes, int wavelet_scale_base, \
        int wavelet_scale_exponent);
int fast_pow(int base, int exponent);
uint8_t fast_popcount_64(uint64_t val);
double hamming_distance(uint16_t *hash_1, uint16_t *hash_2, \
        int hash_size_in_bytes);
int read_hash_from_text(char *text, uint16_t* &hash, int hash_size_in_bytes );
void convert_to_mirror_flip(uint16_t* &hash, int hash_size_in_bytes);


class Fingerprint {
public:
    uint16_t* contents;
    int size_in_bytes;

    Fingerprint(int hash_size_in_bytes=default_hash_size_in_bytes);
    ~Fingerprint();

    char* as_char_array();
    void set_from_char_array(const char* buf);

    std::vector<int> as_int_array();
    void set_from_int_array(const std::vector<int>& values);


    void compute_from_image_file(const char *filename, int wavelet_scale_base, \
            int wavelet_scale_exponent);
    double compare(Fingerprint *other);
    uint8_t compare_compressed_hash(uint64_t other_hash);

    uint64_t compressed_hash();

    void transform_to_mirror();
};
}

#endif /* MWISD_FP_H_ */
