//============================================================================
// Name        : mwisd_fp.cpp
// Author      : Appliomics, LLC
// Version     : 3.1.4
// Copyright   : Copyright 2010-2013 Stipple, Inc.
// Description : Implements Marr Wavelet (image sequence discriminating)
//               fingerprinting for images; for use in the Stipple platform.
//============================================================================

#define cimg_display 0

#include "mwisd_fp.h"
#include "popcounts.h"
#include "CImg.h"
#include <math.h>

#ifdef DEBUG
#include <iostream.h>
#endif

using namespace cimg_library;

#define cimg_display 0

int mwisd_fp::compute_image_hash(const char *filename, uint16_t* &hash, \
        int hash_size_in_bytes, int wavelet_scale_base, \
        int wavelet_scale_exponent) {
    // Recommended:  wavelet_scale_base=2, wavelet_scale_exponent=1

    // Input sanity check.
    if( filename == NULL || wavelet_scale_exponent < 0 ) {
        // Invalid method call parameters.
        return -1;
    }

    int original_width, original_height;
    // Load original image into CImg structure.
    CImg<uint8_t> original_image(filename);

    original_width = original_image.width();
    original_height = original_image.height();

    if( not ((original_width > 0) && \
            (original_height > 0) && \
            (original_image.depth() == 1)) ) {
        // Input image is in an incompatible format.
        return 0;
    }

    CImg<uint8_t> grayscale_image;

    int resize_dim;

    if( original_width >= 512 && original_height >= 512 ) {
        resize_dim = 512;
    } else if( original_width >= 256 && original_height >= 256 ) {
        resize_dim = 256;
    } else if( original_width >= 128 && original_height >= 128) {
        resize_dim = 128;
    } else if( original_width >= 64 && original_height >= 64) {
        resize_dim = 64;
    } else {
        resize_dim = 32;
    }
    
    // Resize to a standardized dimension, convert to grayscale, and blur.
    if( original_image.spectrum() == 3 ) {
        grayscale_image = (CImg<uint8_t>)original_image.get_norm(0).quantize(255).normalize(0,255).resize(resize_dim, resize_dim, 1, 1, 5).blur(1.0).blur(1.0).blur(1.0);
    } else if( original_image.spectrum() == 1 ) {
        grayscale_image = original_image.get_resize(resize_dim, resize_dim, 1, 1, 5).blur(1.0).blur(1.0).blur(1.0);
    } else if ( original_image.spectrum() == 4 ) {
        // Handle PNG with alpha channel
        // http://sourceforge.net/p/cimg/discussion/334630/thread/6a560357/
        CImg<uint8_t>
          luminance = original_image.get_channels(0,2).RGBtoYCbCr().channel(0),
          alpha = original_image.get_channel(3);
          
        grayscale_image = (luminance, alpha) > 'c';
        grayscale_image.resize(resize_dim, resize_dim, 1, 1, 5).blur(1.0).blur(1.0).blur(1.0);
    }
#ifdef DEBUG
    grayscale_image.save_png("temp.gray.png");
#endif

    // Define the correlation mask for performing a Marr wavelet transformation.
    int sigma = mwisd_fp::fast_pow(wavelet_scale_base, wavelet_scale_exponent);
    float inv_sigma = 1.0 / (float)sigma;
    float x, y, r2;
    CImg<float> mask(8*sigma+1, 8*sigma+1, 1, 1, 0);
    cimg_forXY(mask, X, Y) {
        x = inv_sigma * (float)(X - 4*sigma);
        y = inv_sigma * (float)(Y - 4*sigma);
        r2 = x*x + y*y;
        mask.atXY(X,Y) = (2.0 - r2) * std::exp(-0.5 * r2);
    }

    // Perform wavelet decomposition (multiply LoG matrix against image matrix).
    CImg<float> filtered_image = grayscale_image.get_correlate(mask);
#ifdef DEBUG
    filtered_image.save_png("temp.filt.png");
#endif

    // Downscale the filtered image (as it contains inherently sparse info).
    CImg<float> heat_map(32, 32, 1, 1, 0);
    
    int crop_offset = filtered_image.height() / 32;
    float sum;
    
    for( int row=0; row < 32; row++ ) {
        for( int col=0; col < 32; col++ ) {
            sum = filtered_image.get_crop(crop_offset*row, crop_offset*col, crop_offset*row+(crop_offset - 1), crop_offset*col+(crop_offset - 1)).sum();
            heat_map(row, col) = sum;
        }
    }

#ifdef DEBUG
    heat_map.save_png("temp.heat.png");
#endif

    // Convert heat_map into an image hash (fingerprint).
    uint16_t hash_short = 0;
    int index = 0;
    // TODO does cimg_4x4 work here?
    for( int row=0; row < 32; row += 4 ) {
        CImg<float> four_by_four;
        float average_in_four_by_four;
        for( int col=0; col < 32; col += 4 ) {
            four_by_four = heat_map.get_crop(row, col, row+3, col+3).unroll('x');
            average_in_four_by_four = four_by_four.mean();
            cimg_forX(four_by_four, X) {
                hash_short = hash_short << 1;
                if( four_by_four(X) > average_in_four_by_four ) {
                    hash_short |= 0x01;
                }
            }
            hash[index] = hash_short;
            index++;
        }
    }


    // Success.
    return 1;
}


int mwisd_fp::fast_pow(int base, int exponent) {
    int result = 1;
    while( exponent > 0 ) {
        if( exponent & 1 ) {
            result *= base;
        }
        exponent = exponent >> 1;
        base *= base;
    }

    return result;
}

// This uses fewer arithmetic operations than any other known  
// implementation on machines with fast multiplication.
// It uses 12 arithmetic operations, one of which is a multiply.
// See http://en.wikipedia.org/wiki/Hamming_weight for into.
// See http://dalkescientific.com/writings/diary/popcnt.cpp for benchmark program.
uint8_t mwisd_fp::fast_popcount_64(uint64_t x) {
  x -= (x >> 1) & m1;             //put count of each 2 bits into those 2 bits
  x = (x & m2) + ((x >> 2) & m2); //put count of each 4 bits into those 4 bits 
  x = (x + (x >> 4)) & m4;        //put count of each 8 bits into those 8 bits 
  return (x * h01)>>56;  //returns left 8 bits of x + (x<<8) + (x<<16) + (x<<24) + ... 
}

double mwisd_fp::hamming_distance(uint16_t *hash_1, uint16_t *hash_2, int hash_size_in_bytes) {

    // Validate inputs.
    if( (hash_1 == NULL) || (hash_2 == NULL) || (hash_size_in_bytes <= 0) ) {
        return -1.0;
    }

    // Compute hamming distance.
    uint16_t val;
    int distance = 0;
    for( int index=0; index < hash_size_in_bytes/2; index++ ) {
        val = hash_1[index] ^ hash_2[index];

        distance += wordbits[val];

        /*
        while( val ) {
            ++distance;
            val &= val - (uint16_t)1;
        }
        */
    }

    // Normalize the distance.
    double bits = (double)(8 * hash_size_in_bytes);
    double normalized_hamming_distance = (double)distance / bits;

    return normalized_hamming_distance;
}


int mwisd_fp::read_hash_from_text(char *text, uint16_t* &hash, int hash_size_in_bytes) {

    // Read first block of hash data, accommodating irregular leading spaces.
    hash[0] = (uint16_t)atoi(text);
    int shift = 0;
    while( (text[shift] == ' ') && (shift < 6) ) {
        ++shift;
    }
    while( (text[shift] != ' ') && (shift < 6) ) {
        ++shift;
    }

    // Read hash data (expected "%5u " repeated format for 16-bit blocks).
    char *cptr = text + shift;
    int index = 1, stop_index = hash_size_in_bytes/2;
    while( (cptr != NULL) && (index < stop_index) ) {
        hash[index] = (unsigned short)atoi(cptr);
        ++index;
        cptr = strchr(cptr+5, ' ');
    }

    // Basic validation.
    if( (cptr == NULL) && (index < stop_index) ) {
        puts("Warning: read_hash_from_text read shorter than expected hash text");
        return 0;
    }

    // Success.
    return 1;
}


void mwisd_fp::convert_to_mirror_flip(uint16_t* &hash, int hash_size_in_bytes) {
    // Converts existing hash to represent the mirror (horizontal flip) of
    // the image data without needing the original image or its mirror.

    // Reorder the four-by-four hash blocks to mirror order.
    uint16_t *u16ptr = hash;
    uint16_t swap_value;
    int blocks_per_axis = (int)(sqrt(hash_size_in_bytes / 2) + 0.001);
    for( int column = 0; column < blocks_per_axis / 2; column++ ) {
        for( int row = 0; row < blocks_per_axis; row++ ) {
            swap_value = *(u16ptr + blocks_per_axis*column + row);
            *(u16ptr + blocks_per_axis*column + row) = \
                *(u16ptr + blocks_per_axis*(blocks_per_axis-column-1) + row);
            *(u16ptr + blocks_per_axis*(blocks_per_axis-column-1) + row) = \
                swap_value;
        }
    }

    // Reverse the bits in each byte (uses 32-bit operations per byte).
    uint8_t *u8ptr = (uint8_t*)hash;
    for( int index = 0; index < hash_size_in_bytes; index++ ) {
        uint32_t w = *(u8ptr+index);
        *(u8ptr+index) = ( ((w * 0x0802LU & 0x22110LU) | \
                            (w * 0x8020LU & 0x88440LU)) \
                         * 0x10101LU) >> 16;
    }

    // Swap nibbles in each byte, operating on 32 bits at a time for speed.
    uint32_t *u32ptr = (uint32_t*)hash;
    for( int index = 0; index < hash_size_in_bytes/4; index++ ) {
        uint32_t w = *(u32ptr+index);
        *(u32ptr+index) = ((w >> 4) & 0x0F0F0F0FU) | ((w & 0x0F0F0F0FU) << 4);
    }
}


// class mwisd_fp::Fingerprint

mwisd_fp::Fingerprint::Fingerprint(int hash_size_in_bytes) {
    size_in_bytes = hash_size_in_bytes;
    contents = (uint16_t*)malloc(hash_size_in_bytes*sizeof(uint8_t));
}


mwisd_fp::Fingerprint::~Fingerprint() {
    if(contents != NULL) {
        free(contents);
    }
}


char* mwisd_fp::Fingerprint::as_char_array() {
    char *duplicate = (char*)malloc((1+size_in_bytes)*sizeof(uint8_t));
    memcpy(duplicate, contents, size_in_bytes);
    duplicate[size_in_bytes] = '\0';
    return duplicate;  // Expects Ruby will free char array.
}


void mwisd_fp::Fingerprint::set_from_char_array(const char* buf) {
    // Note:  Unreliable to use.  Likely to be deprecated.
    for(int index=0; index < size_in_bytes/(int)sizeof(uint16_t); index++) {
        uint16_t low = (unsigned char)buf[2*index];
        uint16_t high = (unsigned char)buf[2*index+1];
        contents[index] = (high << 8) + low;
    }
}


std::vector<int> mwisd_fp::Fingerprint::as_int_array() {
    // For 128-byte (64 element) contents, produces 64 element vector.
    std::vector<int> values (contents, contents+(size_in_bytes/sizeof(uint16_t)));
    return values;
}


void mwisd_fp::Fingerprint::set_from_int_array(const std::vector<int>& values) {
    // Expects a 64 element vector, in the style created by ::as_int_array().
    size_t count = std::min((size_t)size_in_bytes/sizeof(uint16_t), values.size());
    std::copy (values.begin(), values.begin()+count, contents);
}


void mwisd_fp::Fingerprint::compute_from_image_file(const char *filename, \
        int wavelet_scale_base, int wavelet_scale_exponent) {
    // Recommended:  wavelet_scale_base=2, wavelet_scale_exponent=1
    compute_image_hash(filename, contents, size_in_bytes, wavelet_scale_base, \
            wavelet_scale_exponent);
}


double mwisd_fp::Fingerprint::compare(mwisd_fp::Fingerprint *other) {
    double distance = hamming_distance(contents, other->contents, size_in_bytes);

    return (1.0 - distance);
}

uint8_t mwisd_fp::Fingerprint::compare_compressed_hash(uint64_t other_hash) {
  uint64_t hash_xor = compressed_hash() ^ other_hash;

  return mwisd_fp::fast_popcount_64(hash_xor);
}

uint64_t mwisd_fp::Fingerprint::compressed_hash() {
   uint16_t average;
   uint32_t sum = 0;
   uint64_t hash = 0;
   const uint16_t fp_member_count = size_in_bytes / sizeof(uint16_t);
   uint16_t i;

   if(contents == NULL) {
     return NULL;
   }

   // Determine average value of fingerprint contents
   for(i = 0; i < fp_member_count; ++i) {
     sum += contents[i];
   }

   average = sum / fp_member_count;

   // Set hash bits based on whether corresponding fingerprint member is above or below the average
   for(i = 0; i < fp_member_count; ++i) {
     hash |= (uint64_t)(contents[i] <= average ? 0 : 1) << ((fp_member_count - 1) - i);
   }

   return hash;
}

void mwisd_fp::Fingerprint::transform_to_mirror() {
    mwisd_fp::convert_to_mirror_flip(contents, size_in_bytes);
}
