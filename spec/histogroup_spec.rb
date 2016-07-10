# histogroup_spec.rb

require 'histogroup'

describe Histogroup::Fingerprint do
  B = [0.155793190002441, 0.00297799543477595, 0.00152363756205887, 0.0, 0.00691009126603603, 0.000161423406098038, 0.00360495108179748, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.71909917412449e-07, 0.0, 0.0164792854338884, 0.000140450400067493, 5.15729766448203e-07, 0.0, 0.0138886021450162, 0.00571548892185092, 0.00101650331635028, 3.26628833136056e-06, 0.000120508855616208, 5.86212809139397e-05, 0.0003106412186753, 6.87639658281114e-06, 0.0, 0.0, 7.32336266082712e-05, 2.23482902583783e-06, 0.171916797757149, 0.000105552688182797, 0.0, 0.0, 0.0107051739469171, 0.0381208509206772, 0.000212652565096505, 0.0, 0.000614577962551266, 0.0346831679344177, 0.027154890820384, 0.00897060334682465, 0.0, 0.0, 8.25167589937337e-05, 0.000449716346338391, 0.153405025601387, 0.000951865222305059, 0.0, 0.0, 8.50954093039036e-05, 0.00203180336393416, 8.35482205729932e-05, 0.0, 0.000314423232339323, 0.124773077666759, 0.0600300841033459, 0.00452656019479036, 3.43819834824899e-07, 0.00595392799004912, 0.0589379407465458, 0.0871021151542664]

  describe "#new" do
    it "returns new instance of Fingerprint of default bins_per_dimension size" do
      fp = Histogroup::Fingerprint.new
      #fp.size_in_bytes.should == 4*4*4*4
      fp.bins_per_band.should == 4
      fp.class.should eq(Histogroup::Fingerprint)
    end
    it "returns new instance of Fingerprint of requested bins_per_dimension size" do
      fp = Histogroup::Fingerprint.new(3)
      #fp.size_in_bytes.should == 3*3*3*4
      fp.bins_per_band.should == 3
      fp.class.should eq(Histogroup::Fingerprint)
    end
    it "raises an error if passed an non-integer argument (e.g. String, Arrays)" do
      lambda{ Histogroup::Fingerprint.new("alpha") }.should raise_error
      lambda{ Histogroup::Fingerprint.new(["alpha"]) }.should raise_error
      lambda{ Histogroup::Fingerprint.new([10]) }.should raise_error
      lambda{ Histogroup::Fingerprint.new([1, 0]) }.should raise_error
    end
  end

  describe "#set_from_float_array and #as_float_array" do
    it "initializes Fingerprint from an Array of float; describes Fingerprint as such" do
      fp = Histogroup::Fingerprint.new
      fp.set_from_float_array(B)
      (fp.as_float_array.zip(B).inject(0) {|sum, pair| sum + (pair[1]-pair[0]).abs}).should <= 1.0e-12
    end
    it "initializes Fingerprint from an Array of float shorter than max size_in_bytes" do
      fp = Histogroup::Fingerprint.new
      fp.set_from_float_array([1.0, 2.0, 3.0])
      fp.as_float_array.slice(0,3).should == [1, 2, 3]
    end
    it "initializes Fingerprint from an Array of float longer than max size_in_bytes" do
      fp = Histogroup::Fingerprint.new(1)
      fp.set_from_float_array([1.0, 2.0, 3.0, 4.0, 5.0])
      fp.as_float_array.should == [1]
      fp = Histogroup::Fingerprint.new(2)
      fp.set_from_float_array([1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0])
      fp.as_float_array.should == [1, 2, 3, 4, 5, 6, 7, 8]
    end
    it "(former-only) raises an error if passed a String instead of an Array" do
      fp = Histogroup::Fingerprint.new
      lambda{ fp.set_from_float_array("blah") }.should raise_error
    end
    it "(former-only) raises an error if passed an Array of Strings (not floats)" do
      fp = Histogroup::Fingerprint.new
      lambda{ fp.set_from_float_array(["blah"]) }.should raise_error
      lambda{ fp.set_from_float_array(["b", "l", "a", "h"]) }.should raise_error
    end
  end

  describe "#compare" do
    it "compares two instances of Fingerprint" do
      fp1 = Histogroup::Fingerprint.new
      fp1.set_from_float_array(B)
      fp2 = Histogroup::Fingerprint.new
      fp2.set_from_float_array(B)
      fp1.compare(fp2).should <= 1.0e-12
      fp2.compare(fp1).should <= 1.0e-12
    end
    it "raises an error if passed an Array of floats instead of a Fingerprint" do
      fp = Histogroup::Fingerprint.new
      lambda{ fp.compare([1.0, 2.0, 3.0, 4.0]) }.should raise_error
      lambda{ fp.compare(fp.as_float_array) }.should raise_error
    end
    it "raises an error if passed a String (filename) instead of a Fingerprint" do
      fp = Histogroup::Fingerprint.new
      lambda{ fp.compare("README") }.should raise_error
    end
  end

  describe "#compute_from_image_file" do
    it "reads a specified jpg image file and computes its fingerprint" do
      fp1 = Histogroup::Fingerprint.new
      fp1.compute_from_image_file("./spec/fixtures/grandpa_0401.jpg")
      fp2 = Histogroup::Fingerprint.new
      fp2.compute_from_image_file("./spec/fixtures/grandpa_0401a.jpg")
      fp1.compare(fp2).should < 0.00639
      fp1.compare(fp2).should > 0.00439
      (fp2.compare(fp1) - fp1.compare(fp2)).should < 1.0e-12
      #pending("spec/fixtures is the 'standard' place for those.")
    end
    it "reads a specified 8-bit png image file and computes its fingerprint" do
      fp1 = Histogroup::Fingerprint.new
      fp1.compute_from_image_file("./spec/fixtures/grandpa_0402.png")
      fp2 = Histogroup::Fingerprint.new
      fp2.compute_from_image_file("./spec/fixtures/grandpa_0401.jpg")
      fp1.compare(fp2).should < 0.05104
      fp1.compare(fp2).should > 0.04748
      (fp2.compare(fp1) - fp1.compare(fp2)).should < 1.0e-12
      fp2.compute_from_image_file("./spec/fixtures/grandpa_0403.png")
      # Precision can be much higher with lossless png than highly compressed
      # jpg's because differences in libjpeg versions on different platforms
      # (i.e. OS X vs. Linux) are not always consistent on highly compressed
      # jpg's.
      fp1.compare(fp2).should < 0.01060979535
      fp1.compare(fp2).should > 0.01060979533
      (fp2.compare(fp1) - fp1.compare(fp2)).should < 1.0e-12
    end
    it "reads a specified 16-bit png image file and computes its fingerprint" do
      fp1 = Histogroup::Fingerprint.new
      fp1.compute_from_image_file("./spec/fixtures/example1_16bit.png")
      fp2 = Histogroup::Fingerprint.new
      fp2.compute_from_image_file("./spec/fixtures/example2_16bit.png")
      fp1.compare(fp2).should < 1.4166667
      fp1.compare(fp2).should > 1.4166666
      (fp2.compare(fp1) - fp1.compare(fp2)).should < 1.0e-12
    end
    it "raises an error if asked to read non-existent or non-image-data files" do
      fp = Histogroup::Fingerprint.new
      lambda{ fp.compute_from_image_file("README") }.should raise_error
      lambda{ fp.compute_from_image_file("R") }.should raise_error
    end
    it "raises an error if asked to process a monochrome (b&w) image file" do
      fp = Histogroup::Fingerprint.new
      lambda{ fp.compute_from_image_file("./spec/fixtures/tumblr_lzzphbhRTU1qzf166o1_400.jpg") }.should raise_error
    end
    it "raises an error if asked to process an image file with insufficient color depth (8-bit .ico style)" do
      fp = Histogroup::Fingerprint.new
      lambda{ fp.compute_from_image_file("./spec/fixtures/avatar_3b51e9f07155_16.png") }.should raise_error
    end
  end

end
