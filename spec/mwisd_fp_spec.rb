require 'mwisd_fp'

# NOTE: If you're not seeing changes make in the code reflected in these specs, run 'rake compile:mwisd_fp' and try again.

describe Mwisd_fp::Fingerprint do
  # Constant for re-use in multiple tests.
  A = [969, 22401, 56583, 25799, 38034, 17480, 60364, 40089, 41843, 13235, 14899, 14157, 15672, 28842, 26750, 5587, 18037, 22297, 64914, 31218, 26467, 3847, 15066, 46903, 22102, 54868, 4666, 764, 22875, 29673, 49945, 20196, 46002, 42727, 50373, 10093, 19667, 51888, 7610, 22810, 9011, 15129, 50924, 39571, 42914, 30800, 59168, 47788, 59558, 59616, 11946, 59493, 17749, 4055, 40694, 54170, 34952, 33116, 34945, 55115, 33685, 39323, 41691, 16262]

  before :each do
    @fixtures = File.expand_path("fixtures", File.dirname(__FILE__))
  end
  
  describe "#new" do
    it "returns new instance of Fingerprint of default bitsize" do
      fp = Mwisd_fp::Fingerprint.new
      fp.size_in_bytes.should == 128
      fp.class.should eq(Mwisd_fp::Fingerprint)
    end
    
    it "returns new instance of Fingerprint of requested bitsize" do
      fp = Mwisd_fp::Fingerprint.new(129)
      fp.size_in_bytes.should == 129
      fp.class.should eq(Mwisd_fp::Fingerprint)
    end
    
    it "raises an error if passed an non-integer argument (e.g. String, Arrays)" do
      lambda{ Mwisd_fp::Fingerprint.new("alpha") }.should raise_error
      lambda{ Mwisd_fp::Fingerprint.new(["alpha"]) }.should raise_error
      lambda{ Mwisd_fp::Fingerprint.new([10]) }.should raise_error
      lambda{ Mwisd_fp::Fingerprint.new([1, 0]) }.should raise_error
    end
  end

  describe "#set_from_int_array and #as_int_array" do
    it "initializes Fingerprint from an Array of int; describes Fingerprint as such" do
      fp = Mwisd_fp::Fingerprint.new
      fp.set_from_int_array(A)
      fp.as_int_array.should == A
    end
    
    it "initializes Fingerprint from an Array of int shorter than max size_in_bytes" do
      fp = Mwisd_fp::Fingerprint.new
      fp.set_from_int_array([1, 2, 3])
      fp.as_int_array.slice(0,3).should == [1, 2, 3]
    end
    
    it "initializes Fingerprint from an Array of int longer than max size_in_bytes" do
      fp = Mwisd_fp::Fingerprint.new(3)
      fp.set_from_int_array([1, 2, 3, 4, 5])
      fp.as_int_array.should == [1]
      fp = Mwisd_fp::Fingerprint.new(4)
      fp.set_from_int_array([1, 2, 3, 4, 5])
      fp.as_int_array.should == [1, 2]
    end
    
    it "(former-only) raises an error if passed a String instead of an Array" do
      fp = Mwisd_fp::Fingerprint.new
      lambda{ fp.set_from_int_array("blah") }.should raise_error
    end
    
    it "(former-only) raises an error if passed an Array of Strings (not ints)" do
      fp = Mwisd_fp::Fingerprint.new
      lambda{ fp.set_from_int_array(["blah"]) }.should raise_error
      lambda{ fp.set_from_int_array(["b", "l", "a", "h"]) }.should raise_error
    end
  end

  describe "#as_char_array" do
    it "describes Fingerprint as a string" do
      fp = Mwisd_fp::Fingerprint.new
      fp.set_from_int_array(A)
      fp.as_char_array.should == "\311\003\201W\a\335\307d\222\224HD\314\353\231\234s\243\26333:M78=\252p~h\323\025uF\031W\222\375\362ycg\a\017\332:7\267VVT\326:\022\374\002[Y\351s\031\303\344N\262\263\347\246\305\304m'\323L\260\312\272\035\032Y3#\031;\354\306\223\232\242\247Px \347\254\272\246\350\340\350\252.e\350UE\327\017\366\236\232\323\210\210\\\201\201\210K\327\225\203\233\231\333\242\206?"
    end
  end
      
  describe "#compare" do
    it "compares two instances of Fingerprint" do
      fp1 = Mwisd_fp::Fingerprint.new
      fp1.set_from_int_array(A)
      fp2 = Mwisd_fp::Fingerprint.new
      fp2.set_from_int_array(A)
      fp1.compare(fp2).should == 1.0
      fp2.compare(fp1).should == 1.0
      
      1.upto(10) do |i|
        fp1.compute_from_image_file("#{@fixtures}/large#{i}.jpg", 2, 1)
        fp2.compute_from_image_file("#{@fixtures}/small#{i}.jpg", 2, 1)
        fp1.compare(fp2).should > 0.90
      end
    end
    
    it "raises an error if passed an Array of ints instead of a Fingerprint" do
      fp = Mwisd_fp::Fingerprint.new
      lambda{ fp.compare([1, 2, 3, 4]) }.should raise_error
      lambda{ fp.compare(fp.as_int_array) }.should raise_error
    end
    
    it "raises an error if passed a String (filename) instead of a Fingerprint" do
      fp = Mwisd_fp::Fingerprint.new
      lambda{ fp.compare("README") }.should raise_error
    end
  end

  describe "#compute_from_image_file" do
    it "reads a specified file and computes its fingerprint" do
      fp1 = Mwisd_fp::Fingerprint.new
      fp1.compute_from_image_file("spec/fixtures/grandpa_0401.jpg", 2, 1)
      fp2 = Mwisd_fp::Fingerprint.new
      fp2.compute_from_image_file("spec/fixtures/grandpa_0401.jpg", 2, 1)
      fp2.compare(fp1).should == 1.0

      # Highly compressed jpg images sometimes get uncompressed differently
      # by different versions of the libjpeg library so we make an allowance
      # for that here but no such wrinkles should exist with the lossless
      # png formatted images.
      #fp2.set_from_int_array([905, 22401, 56582, 25799, 54418, 17608, 61388, 40083, 13171, 13235, 14899, 46861, 15672, 28842, 26750, 5587, 18037, 22297, 49123, 31734, 26467, 3855, 31450, 46903, 22102, 54868, 12346, 764, 22875, 29675, 49949, 28520, 15282, 42983, 50381, 10221, 19667, 51888, 7482, 22936, 13107, 15129, 50924, 37555, 41894, 30800, 61184, 47784, 59430, 59618, 61098, 57413, 17749, 20439, 40694, 54170, 34952, 49356, 34945, 55115, 35741, 39323, 41694, 49030])
      fp2.compute_from_image_file("#{@fixtures}/grandpa_0401a.jpg", 2, 1)
      fp1.compare(fp2).should > 0.93
      
      fp2.compute_from_image_file("spec/fixtures/grandpa_0402.png", 2, 1)
      fp2.as_int_array.should == [1902, 9230, 57465, 36375, 11823, 12962, 30310, 60648, 53725, 53725, 53725, 4601, 36056, 14455, 5171, 28921, 5011, 65484, 53145, 48539, 48080, 36627, 9206, 27848, 8738, 9130, 8956, 4565, 21605, 7695, 40839, 32859, 44170, 65083, 4531, 3062, 26464, 40532, 61616, 29954, 43691, 47750, 29038, 34071, 29817, 14145, 57616, 1646, 52428, 64580, 15027, 31897, 23957, 23863, 7923, 32410, 43962, 43946, 43690, 45972, 57702, 27174, 57999, 13026]
      fp2.compute_from_image_file("spec/fixtures/grandpa_0403.png", 2, 1)
      fp2.as_int_array.should == [255, 28750, 58912, 51347, 12563, 13107, 14182, 61132, 4509, 37137, 4371, 4479, 58952, 63872, 2231, 13073, 52974, 60620, 52360, 36040, 36232, 36403, 5118, 60620, 13107, 14183, 14320, 819, 15553, 191, 65152, 887, 13111, 62259, 32624, 239, 58976, 61132, 63232, 6143, 39321, 64904, 35020, 32819, 13119, 65288, 3952, 1647, 254, 61043, 13107, 30600, 39313, 13107, 3327, 29456, 6553, 4543, 35515, 62208, 36046, 52428, 52431, 65160]
    end
    
    it "raises an error if asked to read non-existent or non-image-data files" do
      fp = Mwisd_fp::Fingerprint.new
      lambda{ fp.compute_from_image_file("README", 2, 1) }.should raise_error
      lambda{ fp.compute_from_image_file("R", 2, 1) }.should raise_error
    end
    
    it "handles pngs with an alpha channel" do
      f = Mwisd_fp::Fingerprint.new
      lambda {
        f.compute_from_image_file("#{@fixtures}/unflattened.png", 2, 1)
      }.should_not raise_error
    end
  end

  describe "#transform_to_mirror" do
    it "transforms a fingerprint to represent the mirror of the original image" do
      fp = Mwisd_fp::Fingerprint.new
      fp.set_from_int_array(A)
      fp.transform_to_mirror
      fp.as_int_array.should == [4369, 6307, 4376, 48685, 7322, 39325, 21693, 53014, 29014, 29040, 18261, 29034, 10922, 4030, 38902, 48277, 19660, 52617, 13939, 38300, 24148, 57760, 32320, 54611, 56532, 22142, 12858, 20075, 9148, 13776, 35797, 43397, 42662, 46754, 33989, 1267, 43437, 60537, 15497, 10098, 9962, 44681, 64404, 59892, 28268, 3854, 50613, 57038, 23788, 52444, 50636, 52779, 52161, 57429, 25063, 35516, 3129, 44568, 47886, 25150, 37524, 8737, 32051, 37785]
    end
    
    it "performs an invertible transform (applied twice, get original)" do
      fp1 = Mwisd_fp::Fingerprint.new
      fp1.set_from_int_array(A)
      fp2 = Mwisd_fp::Fingerprint.new
      fp2.set_from_int_array(fp1.as_int_array)
      fp1.transform_to_mirror
      fp2.compare(fp1).should < (1.0 - 0.1)
      fp1.transform_to_mirror
      fp1.as_int_array.should == fp2.as_int_array
      fp2.compare(fp1).should == 1.0
      fp1.transform_to_mirror
      fp2.transform_to_mirror
      fp1.as_int_array.should == fp2.as_int_array
      fp2.compare(fp1).should == 1.0
    end
  end

  describe "#compressed_hash" do
    it "returns the compressed hash value of the fingerprint" do
      fp1 = Mwisd_fp::Fingerprint.new
      fp1.set_from_int_array(A)
      fp1.compressed_hash.should == 3134541911830549502
    end
  end

  describe "#compare_compressed_hash" do
    it "returns the difference between itself and the passed compressed hash value" do
      fp1 = Mwisd_fp::Fingerprint.new
      fp1.set_from_int_array(A)
      fp1.compare_compressed_hash(fp1.compressed_hash).should == 0
      fp1.compare_compressed_hash(1).should == 31
      fp1.compare_compressed_hash(982374290294).should == 23
      fp1.compare_compressed_hash(18182472).should == 26
    end
  end
end
