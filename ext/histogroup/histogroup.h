//============================================================================
// Name        : histogroup.h
// Author      : Appliomics, LLC
// Version     : 3.0.0
// Copyright   : Copyright 2011 Appliomics, LLC - All Rights Reserved
// Description : Implements multi-band histogram hashing for images for the
//               purpose of fuzzy matching of images into groups.
//============================================================================

#ifndef HISTOGROUP_H_
#define HISTOGROUP_H_

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


// Definition of histogroup::namespace
namespace histogroup {

const int default_hash_size_in_bins = 4;
const int default_hash_size_in_bytes = 4*4*4*sizeof(float);


int compute_image_hash(const char *filename, float* &hash, \
        int hash_size_in_bins, int bins_per_dimension);
double compare_chisquare(float *hash_1, float *hash_2, \
        int hash_size_in_bins);
int read_hash_from_text(char *text, float* &hash, int hash_size_in_bins);


class Fingerprint {
public:
    float* contents;
    int bins_per_band;
private:
    int size_in_bytes;

public:
    Fingerprint(int hash_size_in_bins_per_dimension=default_hash_size_in_bins);
    ~Fingerprint();

    std::vector<float> as_float_array();
    void set_from_float_array(const std::vector<float>& values);

    void compute_from_image_file(const char *filename);
    double compare(Fingerprint *other);
};
}

#endif /* HISTOGROUP_H_ */
