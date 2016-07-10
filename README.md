mwisd
=====

Named for the first method it implemented, mwisd provides image fingerprinting methods for the purposes of uniquely identifying an individual or a group of images.  mwisd functionality is accessible via Ruby, C++, and C APIs as well as a set of command-line utilities.  The meat of the code behind mwisd is primarily written in C++, with the important functions accessible as extern C.  The Ruby API is made possible by this C++ API (as it performs the necessary memory management tasks, unlike the C API) and [SWIG](http://www.swig.org/).

At present, two image fingerprinting methods are implemented:  mwisd_fp and histogroup.  mwisd_fp employs a Marr wavelet transform to compute a fingerprint (represented as a bitstring) which is designed to uniquely identify an image independent of many affine transformations (i.e. a downscaled version of the same image has the same fingerprint, or nearly so, as the original).  histogroup employs a 3D color histogram to compute a fingerprint which is designed to match an image to other similar images which might form a related group of images (i.e. one photo taken at a pod at a red carpet event will generally have a remarkably similar histogroup fingerprint to other photos of the same individuals/objects at the same pod).

The mwisd code depends upon [libpng](http://www.libpng.org/pub/png/libpng.html), [libjpeg](http://www.ijg.org/), [libtiff](http://www.libtiff.org/), and Ruby (1.9.x) libraries (so their supporting include files are needed as well) as external dependencies.  The project also depends upon but ships with a copy of the [CImg](http://cimg.sourceforge.net/) (CeCILL-C license, close equivalent to LGPL) library which is itself supplied as a single C++ header file (does not build to its own independent library, by design) in the extern/ subdirectory along with its license file.

The mwisd project uses Bundler to create and install its gem.  This top-level project produces two distinct libraries (one for mwisd_fp and one for histogroup) but both ship in a single gem.  By gemifying these libraries, we make it possible to build, cache, and automagically install them on Stipple's EngineYard instances via the same mechanism used for other Stipple codes.


Installation
------------

    $ bundle install


Usage: mwisd_fp
---------------

In Ruby, require the library and create an instance of its type of fingerprint:

    require 'mwisd_fp'
    fp1 = Mwisd_fp::Fingerprint.new
    fp1.class
    # => Mwisd_fp::Fingerprint

Compute the mwisd_fp fingerprint for an image; for Stipple's purposes, we consistently use a value of 2 for the wavelet_scale_base and a value of 1 for the wavelet_scale_exponent parameters:

    fp1.compute_from_image_file("./spec/fixtures/grandpa_0403.png", 2, 1)

Have a look at the fingerprint we just determined by viewing it as an Array of ints:

    fp1.as_int_array 
    # => [7786, 15374, 57585, 1591, 9859, 12834, 30314, 60648, 37273, 37277, 53525, 29177, 2268, 12631, 13331, 28916, 10922, 43725, 57243, 15515, 39920, 3859, 9206, 19656, 9902, 65450, 13436, 2928, 5477, 38159, 56982, 33115, 19485, 39731, 4515, 37558, 26209, 48724, 28848, 30374, 39321, 47142, 29542, 50525, 20729, 10192, 61440, 19048, 8243, 53060, 15282, 31798, 24021, 22835, 3827, 22170, 43690, 7099, 43690, 11156, 10086, 26158, 41703, 10980]

Compute the mwisd_fp fingerprint for a second image and compare the similarity of their fingerprints:

    fp2 = Mwisd_fp::Fingerprint.new
    fp2.compute_from_image_file("./spec/fixtures/grandpa_0402.png", 2, 1)
    fp1.compare fp2
    # => 0.763671875

Though those two images were part of a sequence of photos taken in fairly rapid succession, a score of < 0.8 conveys that they are very unlikely to be the same image.  Contrast this with two copies of the same image but scaled to different sizes:

    fp1.compute_from_image_file("./spec/fixtures/grandpa_0401.jpg", 2, 1)
    fp2.compute_from_image_file("./spec/fixtures/grandpa_0401a.jpg", 2, 1)
    fp1.compare fp2
    # => 0.9140625

While a score of 0.91 is not quite high enough to confidently declare that these two images are actually the same image, the probability is quite high.  Additional fuzzy matching algorithms are needed to conclusively identify these as a match or not.

Note that in the above, the instances of Mwisd_fp::Fingerprint could be reused to compute fingerprints of new images.  Further note that order does not matter when invoking #compare:

    fp1.compare fp2
    # => 0.9140625
    fp2.compare fp1
    # => 0.9140625

Such fingerprints can be stored as an Array of ints and later reused without needing to keep the source image file around for reference:

    MyFP = fp1.as_int_array 
    fp2.set_from_int_array MyFP
    fp1.compare fp2
    # => 1.0

Via the command-line, one can similarly compute fingerprints and compare them:

    $ ext/cli/mwisd_fp_gen ./spec/fixtures/grandpa_0403.png 
     7786 15374 57585  1591  9859 12834 30314 60648 37273 37277 53525 29177  2268 12631 13331 28916 10922 43725 57243 15515 39920  3859  9206 19656  9902 65450 13436  2928  5477 38159 56982 33115 19485 39731  4515 37558 26209 48724 28848 30374 39321 47142 29542 50525 20729 10192 61440 19048  8243 53060 15282 31798 24021 22835  3827 22170 43690  7099 43690 11156 10086 26158 41703 10980
    $ ext/cli/mwisd_fp_cmp ./spec/fixtures/grandpa_0403.png ./spec/fixtures/grandpa_0402.png 
    0.76367
    $ ext/cli/mwisd_fp_cmp -ivf ./spec/fixtures/grandpa_0402.png " 7786 15374 57585  1591  9859 12834 30314 60648 37273 37277 53525 29177  2268 12631 13331 28916 10922 43725 57243 15515 39920  3859  9206 19656  9902 65450 13436  2928  5477 38159 56982 33115 19485 39731  4515 37558 26209 48724 28848 30374 39321 47142 29542 50525 20729 10192 61440 19048  8243 53060 15282 31798 24021 22835  3827 22170 43690  7099 43690 11156 10086 26158 41703 10980"
    0.76367


Usage: histogroup
-----------------

In Ruby, require the library and create an instance of its type of fingerprint:

    require 'histogroup'
    fp3 = Histogroup::Fingerprint.new
    fp3.class
    # => Histogroup::Fingerprint

Compute the histogroup fingerprint for an image:

    fp3.compute_from_image_file("./spec/fixtures/grandpa_0403.png")

Have a look at the fingerprint we just determined by viewing it as an Array of floats (note that because of the nature of and meaning behind this kind of fingerprint, representation as an Array of ints does not make sense and is not available as a method):

    fp3.as_float_array 
    # => [0.24666666984558105, 0.004843750037252903, 0.0, 0.0, 0.001927083358168602, 0.002760416828095913, 5.208333459449932e-05, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.12463542073965073, 0.0016666667070239782, 0.0, 0.0, 0.10270833224058151, 0.16557292640209198, 0.00041666667675599456, 0.0, 0.0, 0.0002604166802484542, 0.00020833333837799728, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.00510416692122817, 0.06520833820104599, 0.00041666667675599456, 0.0, 0.0, 0.02848958410322666, 0.14802083373069763, 0.008854166604578495, 0.0, 0.0, 0.0011458334047347307, 0.01875000074505806, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.005833333358168602, 0.0003645833348855376, 0.0, 0.0, 0.0023958333767950535, 0.0636979192495346]

Compute the histogroup fingerprint for a second image and compare the similarity of their fingerprints while noting that the result from comparisons of histogroup fingerprints can range from 0 to infinite:

    fp4 = Histogroup::Fingerprint.new
    fp4.compute_from_image_file("./spec/fixtures/grandpa_0402.png")
    fp3.compare fp4
    # => 0.010609795339405537

Because those two images were part of a sequence of photos taken in fairly rapid succession, with the same scene / background / objects, this score of < 0.02 strongly suggests that they could be closely related images of the same scene and dominant objects.  Note that uniqueness is not guaranteed by the histogroup fingerprint so it is possible that two completely unrelated photos from different times and places could have surprisingly similar 3D color histograms.  If other information (i.e. meta data accompanying the images) is not available to pre-filter which images are likely to be part of a group of related images, then a much stronger criterion must be used for determining what images likely belong to a group.  Contrast this with the example of two copies of the same image scaled to different sizes:

    fp3.compute_from_image_file("./spec/fixtures/grandpa_0401.jpg")
    fp4.compute_from_image_file("./spec/fixtures/grandpa_0401a.jpg")
    fp3.compare fp4
    # => 0.004392701666802168

Note that in the above, the instances of Histogroup::Fingerprint could be reused to compute fingerprints of new images.  Further note that order does not matter when invoking #compare:

    fp3.compare fp4
    # => 0.004392701666802168
    fp4.compare fp3
    # => 0.004392701666802168

Such fingerprints can be stored as an Array of floats and later reused without needing to keep the source image file around for reference:

    MyFP2 = fp3.as_float_array 
    fp4.set_from_float_array MyFP2
    fp3.compare fp4
    # => 0.0

Via the command-line, one can similarly compute fingerprints and compare them:

    $ ext/cli/histogroup_gen  ./spec/fixtures/grandpa_0403.png
    0.2466667 0.0048438 0.0000000 0.0000000 0.0019271 0.0027604 0.0000521 0.0000000 0.0000000 0.0000000 0.0000000 0.0000000 0.0000000 0.0000000 0.0000000 0.0000000 0.1246354 0.0016667 0.0000000 0.0000000 0.1027083 0.1655729 0.0004167 0.0000000 0.0000000 0.0002604 0.0002083 0.0000000 0.0000000 0.0000000 0.0000000 0.0000000 0.0000000 0.0000000 0.0000000 0.0000000 0.0051042 0.0652083 0.0004167 0.0000000 0.0000000 0.0284896 0.1480208 0.0088542 0.0000000 0.0000000 0.0011458 0.0187500 0.0000000 0.0000000 0.0000000 0.0000000 0.0000000 0.0000000 0.0000000 0.0000000 0.0000000 0.0000000 0.0058333 0.0003646 0.0000000 0.0000000 0.0023958 0.0636979 
    $ ext/cli/histogroup_cmp ./spec/fixtures/grandpa_0403.png ./spec/fixtures/grandpa_0402.png
    0.01061
    $ ext/cli/histogroup_cmp -fvi "0.2466667 0.0048438 0.0000000 0.0000000 0.0019271 0.0027604 0.0000521 0.0000000 0.0000000 0.0000000 0.0000000 0.0000000 0.0000000 0.0000000 0.0000000 0.0000000 0.1246354 0.0016667 0.0000000 0.0000000 0.1027083 0.1655729 0.0004167 0.0000000 0.0000000 0.0002604 0.0002083 0.0000000 0.0000000 0.0000000 0.0000000 0.0000000 0.0000000 0.0000000 0.0000000 0.0000000 0.0051042 0.0652083 0.0004167 0.0000000 0.0000000 0.0284896 0.1480208 0.0088542 0.0000000 0.0000000 0.0011458 0.0187500 0.0000000 0.0000000 0.0000000 0.0000000 0.0000000 0.0000000 0.0000000 0.0000000 0.0000000 0.0000000 0.0058333 0.0003646 0.0000000 0.0000000 0.0023958 0.0636979" ./spec/fixtures/grandpa_0402.png
    0.01061


History
-------

+ v3.0:  Histogroup calculation subtly changed.  Although quite minor, all prior histogroup values should be recomputed and replaced to be safe.
+ v2.0:  Added histogroup fingerprint support.
+ v1.0:  Added mwisd fingerprint support.


Compile
-------

    $ rake compile

The above builds everything needed for the Ruby API but does not build the command-line tools.  To build the command-line tools or if 'make cleanall' is invoked or otherwise the mwisd_fp_wrap.cxx or histogroup_wrap.cxx files are destroyed, they must be regenerated using [SWIG](http://www.swig.org/) which is possible via:

    $ make
    $ rake compile

Note that accidentally destroying one of the \*_wrap.cpp files will not cause 'rake compile' to fail or complain but it *will* cause all RSpec tests to subsequently fail.


Tests
-----

Running the RSpec tests is straight-forward.  Tests for all types of fingerprints will be exercised as part of any invocation of the tests:

    $ rake
    (in ~/stipple/work/mwisd)
    ~/stipple/ruby/v1.9.3/bin/ruby -S rspec spec/histogroup_spec.rb spec/mwisd_fp_spec.rb
    ..............
    [CImg] *** CImgIOException *** [instance(0,0,0,0,(nil),non-shared)] CImg<float>::load() : Failed to open file 'README'.

    [CImg] *** CImgIOException *** [instance(0,0,0,0,(nil),non-shared)] CImg<float>::load() : Failed to open file 'R'.
    .compute_image_hash() : Loaded image spectrum != 3, so inappropriate for 3D histogram!

    [CImg] *** CImgIOException *** histogroup::compute_image_hash negative return value.

    .compute_image_hash() : Loaded image spectrum != 3, so inappropriate for 3D histogram!

    [CImg] *** CImgIOException *** histogroup::compute_image_hash negative return value.

    ..............
    [CImg] *** CImgIOException *** [instance(0,0,0,0,(nil),non-shared)] CImg<unsigned char>::load() : Failed to open file 'README'.

    [CImg] *** CImgIOException *** [instance(0,0,0,0,(nil),non-shared)] CImg<unsigned char>::load() : Failed to open file 'R'.
    ...

    Finished in 1.41 seconds
    33 examples, 0 failures


