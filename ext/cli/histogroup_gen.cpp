//============================================================================
// Name        : histogroup_gen.cpp
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

int main(int argc, char** argv) {

    if( argc < 2 ) {
        puts("No input arguments!");
        puts("Expected:  \"histogroup_gen image_file\"");
        return EXIT_FAILURE;
    }

    int hash_size_in_bytes = default_hash_size_in_bytes;
    float* image_hash = (float*)malloc(hash_size_in_bytes*sizeof(uint8_t));

    int ret = compute_image_hash(argv[1], image_hash, hash_size_in_bytes, 4);

    if( ret < 1 ) {
        printf("Error: compute_image_hash returned %d\n", ret);
        return EXIT_FAILURE;
    } else {
        for( int index=0; index < (hash_size_in_bytes/(int)sizeof(float)); index++ ) {
            printf("%9.7f ", image_hash[index]);
        }
        printf("\n");
    }

    if( image_hash != NULL ) free(image_hash);
    return EXIT_SUCCESS;
}
