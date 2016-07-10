//============================================================================
// Name        : histogroup.cpp
// Author      : Appliomics, LLC
// Version     : 3.0.0
// Copyright   : Copyright 2011 Appliomics, LLC - All Rights Reserved
// Description : Implements multi-band histogram hashing for images for the
//               purpose of fuzzy matching of images into groups.
//============================================================================

#include "histogroup.h"
#include "CImg.h"
#include <math.h>

using namespace cimg_library;


int histogroup::compute_image_hash(const char *filename, float* &hash, \
        int hash_size_in_bytes, int bins_per_dimension) {
    // Input sanity check.
    if( filename == NULL ) {
        fprintf(stderr, "compute_image_hash() : Must supply filename != NULL.\n");
        return -1;
    }
    if( bins_per_dimension < 2 ) {
        fprintf(stderr, "compute_image_hash() : Must request 2 or more bins per dim!\n");
        return -2;
    }

    // Load original image into CImg structure.
    CImg<float> original_image(filename);
    if( not ((original_image.width() > 0) && \
            (original_image.height() > 0) && \
            (original_image.depth() == 1)) ) {
        // Input image is in an incompatible format.
        fprintf(stderr, "compute_image_hash() : Loaded image depth (or width/height) inappropriate for 3D histogram!\n");
        return -3;
    }
    if( original_image.spectrum() != 3 ) {
        fprintf(stderr, "compute_image_hash() : Loaded image spectrum != 3, so inappropriate for 3D histogram!\n");
        return -4;
    }

    // Standardize the contrast in the image by normalizing it.  TODO: Good idea?  Use observed max/min?
    //original_image.normalize(0.0, 255.0);

    // Compute 3D histogram (one dim for each layer, assumes 3 layers).
    float min_value = 0.0, max_value = 0.0;
    max_value = original_image.max();
    // Attempt to determine bitdepth of pixels (8, 16, 24, or 32-bit).
    if( max_value > 255.1 ) {
        if( max_value > 65535.1 ) {
            if( max_value > 1677215.1 ) {
                max_value = 4294967295.0;
            } else {
                max_value = 16777215.0;
            }
        } else {
            max_value = 65535.0;
        }
    } else {
        max_value = 255.0;
    }
    //printf("DBG: min, max= %f, %f\n", min_value, max_value);
    const float inv_range_values = 1.0 / (max_value - min_value);
    CImg<float> hist(bins_per_dimension, bins_per_dimension, bins_per_dimension, 1, 0);
    long count = 0;
#define NONZEROMINBINMAP(val) (val == max_value ? bins_per_dimension-1 : (int)((val - min_value) * bins_per_dimension * inv_range_values))
#define BINMAP(val) (val == max_value ? bins_per_dimension-1 : (int)(val * bins_per_dimension * inv_range_values))
    if( min_value < max_value ) cimg_forXY(original_image, x, y) {
        const float val0 = original_image(x, y, 0);
        const float val1 = original_image(x, y, 1);
        const float val2 = original_image(x, y, 2);
        ++hist[(BINMAP(val0)*bins_per_dimension + BINMAP(val1))*bins_per_dimension + BINMAP(val2)];
        ++count;
    } else {
        hist[0] = original_image.size();
    }
#ifdef DEBUG
    printf("DBG: count=%ld\n", count);
    hist.save_png("temp.hist.png");
#endif

    // Change representation of hist to simplify code in next steps.
    hist.unroll('x');

    // Compute sum for normalizing histogram during next step.
    float sum = 0.0;
    cimg_forX(hist, x) {
        sum += hist(x);
    }
    const float inv_sum = 1.0 / (sum + 0.0000000001);

    // Convert normalized 3D histogram into image hash (fingerprint).
    if( hash_size_in_bytes >= ((int)sizeof(float))*bins_per_dimension*bins_per_dimension*bins_per_dimension ) {
        cimg_forX(hist, x) {
            hash[x] = inv_sum * hist(x);
        }
    }
    return 1;
}


double histogroup::compare_chisquare(float *hash_1, float *hash_2,
        int bins_per_dimension) {
    float sum = 0.0;
    for( int i = 0; i < bins_per_dimension; i++ ) {
        for( int j = 0; j < bins_per_dimension; j++ ) {
            for( int k = 0; k < bins_per_dimension; k++ ) {
                const float a = hash_1[(i*bins_per_dimension + j)*bins_per_dimension + k];
                const float b = hash_2[(i*bins_per_dimension + j)*bins_per_dimension + k];
                sum += (a - b) * (a - b) / (a + b + 0.0000000001);
            }
        }
    }
    return sum;
}


int histogroup::read_hash_from_text(char *text, float* &hash, int hash_size_in_bytes) {

    // Read first block of hash data, accommodating irregular leading spaces.
    hash[0] = (float)atof(text);
    int shift = 0;
    while( (text[shift] == ' ') && (shift < 9) ) {
        ++shift;
    }
    while( (text[shift] != ' ') && (shift < 9) ) {
        ++shift;
    }

    // Read hash data (expected "%9.7f " repeated format for float blocks).
    char *cptr = text + shift;
    int index = 1, stop_index = hash_size_in_bytes/sizeof(float);
    while( (cptr != NULL) && (index < stop_index) ) {
        hash[index] = (float)atof(cptr);
        ++index;
        cptr = strchr(cptr+9, ' ');
    }

    // Basic validation.
    if( (cptr == NULL) && (index < stop_index) ) {
        puts("Warning: read_hash_from_text read shorter than expected hash text");
        return 0;
    }

    // Success.
    return 1;
}



// class histogroup::Fingerprint

histogroup::Fingerprint::Fingerprint(int hash_size_in_bins_per_dimension) {
	bins_per_band = hash_size_in_bins_per_dimension;
    size_in_bytes = bins_per_band * bins_per_band * bins_per_band * sizeof(float);
    contents = (float*)malloc(size_in_bytes);
}


histogroup::Fingerprint::~Fingerprint() {
    if(contents != NULL) {
        free(contents);
    }
}


std::vector<float> histogroup::Fingerprint::as_float_array() {
    std::vector<float> values (contents, contents+(size_in_bytes/sizeof(float)));
    return values;
}


void histogroup::Fingerprint::set_from_float_array(const std::vector<float>& values) {
    // Expects a bins_per_band**3 element vector, in the style created by ::as_float_array().
    size_t count = std::min((size_t)size_in_bytes/sizeof(float), values.size());
    std::copy (values.begin(), values.begin()+count, contents);
}


void histogroup::Fingerprint::compute_from_image_file(const char *filename) {
    int retval =
        compute_image_hash(filename, contents, size_in_bytes, bins_per_band);
    if( retval < 0 ) {
        throw CImgIOException("histogroup::compute_image_hash negative return value.\n");
    }
}


double histogroup::Fingerprint::compare(histogroup::Fingerprint *other) {
    double chisq_value = compare_chisquare(contents, other->contents, bins_per_band);
    return chisq_value;
}
