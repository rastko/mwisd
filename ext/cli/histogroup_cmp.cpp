//============================================================================
// Name        : histogroup_cmp.cpp
// Author      : Appliomics, LLC
// Version     : 3.0.0
// Copyright   : Copyright 2011 Appliomics, LLC - All Rights Reserved
// Description : Implements multi-band histogram hashing for images for the
//               purpose of fuzzy matching of images into groups.
//============================================================================

#include <cstdio>
#include <cstdlib>
#include "histogroup.h"

using namespace histogroup;

//TODO: Account for asymmetrically scaled image in stipple

int main(int argc, char** argv) {
    // Basic validation of command-line invocation arguments.
    if( argc < 3 ) {
        puts("Insufficient input arguments!\n");
        puts("Usage:\n  histogroup_cmp [option] [image_file || fingerprint] [image_file || fingerprint]");
        puts("     option:");
        puts("         -ivi     Compare image v. image  (default mode)");
        puts("         -ivf     Compare image v. fingerprint");
        puts("         -fvi     Compare fingerprint v. image");
        puts("         -fvf     Compare fingerprint v. fingerprint");
        puts("                  (Fingerprint is supplied as text block of unsigned shorts.)\n");
        return EXIT_FAILURE;
    }

    // Process command-line option (if one was specified).
    bool need_to_compute_fingerprint_1=true, need_to_compute_fingerprint_2=true;
    int shift = 1;
    if( argv[1][0] == '-' && argv[1][2] == 'v' ) {
        if( argv[1][1] == 'i') {
            need_to_compute_fingerprint_1 = true;
        } else if( argv[1][1] == 'f' ) {
            need_to_compute_fingerprint_1 = false;
        } else {
            printf("Error:  option \'%s\' not recognized.", argv[1]);
            return EXIT_FAILURE;
        }

        if( argv[1][3] == 'i') {
            need_to_compute_fingerprint_2 = true;
        } else if( argv[1][3] == 'f' ) {
            need_to_compute_fingerprint_2 = false;
        } else {
            printf("Error:  option \'%s\' not recognized.", argv[1]);
            return EXIT_FAILURE;
        }

        shift = 0;
    }

    // Allocate memory for fingerprints.
    int hash_size_in_bytes = default_hash_size_in_bytes;
    float* fingerprint_1 = (float*)malloc(hash_size_in_bytes*sizeof(uint8_t));
    float* fingerprint_2 = (float*)malloc(hash_size_in_bytes*sizeof(uint8_t));

    // Get fingerprint for first input.
    if( need_to_compute_fingerprint_1 ) {
        if( compute_image_hash(argv[2-shift], fingerprint_1, hash_size_in_bytes, 4) < 1 ) {
            printf("Error:  compute_image_hash on \'%s\' failed.\n", argv[2-shift]);
            return EXIT_FAILURE;
        }
    } else {
        if( read_hash_from_text(argv[2-shift], fingerprint_1, hash_size_in_bytes ) < 1 ) {
            printf("Error:  read_hash_from_text on \'%s\' failed.\n", argv[2-shift]);
            return EXIT_FAILURE;
        }
    }

    // Get fingerprint for second input.
    if( need_to_compute_fingerprint_2 ) {
        if( compute_image_hash(argv[3-shift], fingerprint_2, hash_size_in_bytes, 4) < 1 ) {
            printf("Error:  compute_image_hash on \'%s\' failed.\n", argv[3-shift]);
            return EXIT_FAILURE;
        }
    } else {
        if( read_hash_from_text(argv[3-shift], fingerprint_2, hash_size_in_bytes ) < 1 ) {
            printf("Error:  read_hash_from_text on \'%s\' failed.\n", argv[3-shift]);
            return EXIT_FAILURE;
        }
    }

    // Compare fingerprints.
    double similarity = compare_chisquare(fingerprint_1, fingerprint_2, 4);
    printf("%1.5f\n", similarity);

    return EXIT_SUCCESS;
}
