//============================================================================
// Name        : mwisd_fp_gen.cpp
// Author      : Appliomics, LLC
// Version     : 3.0.0
// Copyright   : Copyright 2011, 2010 Appliomics, LLC - All Rights Reserved
// Description : Generates Marr Wavelet (image sequence discriminating)
//               fingerprints; for use in the Stipple platform.
//============================================================================

#include <cstdio>
#include <cstdlib>
#include "mwisd_fp.h"

using namespace mwisd_fp;

int main(int argc, char** argv) {

    if( argc < 2 ) {
        puts("No input arguments!");
        puts("Expected:  \"mwisd_fp_gen image_file\"");
        return EXIT_FAILURE;
    }

    int hash_size_in_bytes = default_hash_size_in_bytes;
    uint16_t* image_hash = (uint16_t*)malloc(hash_size_in_bytes*sizeof(uint8_t));

    int ret = compute_image_hash(argv[1], image_hash, hash_size_in_bytes, 2, 1);

    if( ret < 1 ) {
        printf("Error: compute_image_hash returned %d\n", ret);
        return EXIT_FAILURE;
    } else {
        //printf("mwisd hash: ");
        for( int index=0; index < hash_size_in_bytes/2; index++ ) {
            printf("%5u ", image_hash[index]);
        }
        printf("\n");
    }

    if( image_hash != NULL ) free(image_hash);
    return EXIT_SUCCESS;
}
