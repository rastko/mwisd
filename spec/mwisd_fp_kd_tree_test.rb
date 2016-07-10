#!/usr/bin/env ruby
#============================================================================
# Name        : mwisd_fp_kd_tree_test.rb
# Author      : Appliomics, LLC
# Version     : 1.2.0
# Copyright   : Copyright 2011 Appliomics, LLC - All Rights Reserved
# Description : Implements kd-Tree construction O(N log N) to support very
#               fast lookup O(log N) of fingerprints against a pool of
#               existing fingerprints.
#============================================================================

require 'yaml'
require 'rubygems'
require 'parallel'
require 'mwisd_fp'


def bifurcate_fingerprints(fingerprints_as_int_arrays, fingerprint_not_in_array)
  # Sanity-check input.
  raise ArgumentError, 'fingerprints_as_int_arrays is empty' unless \
    fingerprints_as_int_arrays.length > 0
  # Compare fingerprint_not_in_array to each in the fingerprints_as_int_arrays.
  fp1 = Mwisd_fp::Fingerprint.new
  fp1.set_from_int_array(fingerprint_not_in_array)
  fp2 = Mwisd_fp::Fingerprint.new
  scores = fingerprints_as_int_arrays.map do |fp2_int_array|
    fp2.set_from_int_array(fp2_int_array)
    fp1.compare(fp2)
  end

  # Determine the median "score" (similarity) amongst all those comparisons.
  # TODO: Eval whether can skip sort and just use 0.5 as "median".
  median = scores.sort[scores.length / 2]

  # Divide the fingerprints_as_int_arrays into 2 groups: above/below the median.
  lesserthan_group = []
  greaterthanorequal_group = []
  fingerprints_as_int_arrays.each_index do |fp_index|
    if scores[fp_index] < median then
      lesserthan_group << fp_index
    else
      greaterthanorequal_group << fp_index
    end
  end

  # Return a Hash containing the median value and the bifurcated sets' indices.
  { :midpoint => median,
    :lesser_set => lesserthan_group,
    :greater_set => greaterthanorequal_group }
end


def fuzzy_bifurcate_fingerprints(fingerprints_as_int_arrays, fingerprint_not_in_array, epsilon)
  # Sanity-check input.
  raise ArgumentError, 'fingerprints_as_int_arrays is empty' unless \
    fingerprints_as_int_arrays.length > 0
  # Compare fingerprint_not_in_array to each in the fingerprints_as_int_arrays.
  fp1 = Mwisd_fp::Fingerprint.new
  fp1.set_from_int_array(fingerprint_not_in_array)
  fp2 = Mwisd_fp::Fingerprint.new
  scores = fingerprints_as_int_arrays.map do |fp2_int_array|
    fp2.set_from_int_array(fp2_int_array)
    fp1.compare(fp2)
  end

  # Determine the median "score" (similarity) amongst all those comparisons.
  # TODO: Eval whether can skip sort and just use 0.5 as "median".
  median = scores.sort[scores.length / 2]

  # Divide the fingerprints_as_int_arrays into 2 groups: above/below the median,
  # allowing for the region around the median bounded by the value of epsilon.
  lesserthan_group = []
  greaterthanorequal_group = []
  fingerprints_as_int_arrays.each_index do |fp_index|
    if scores[fp_index] <= (median + epsilon) then
      lesserthan_group << fp_index
    end
    if scores[fp_index] >= (median - epsilon) then
      greaterthanorequal_group << fp_index
    end
  end

  # Return a Hash containing the median value and the bifurcated sets' indices.
  { :midpoint => median,
    :lesser_set => lesserthan_group,
    :greater_set => greaterthanorequal_group }
end


def fingerprint_all_images_in_directories(array_of_directory_names)
  # Process all files in each specified directory.
  fp = Mwisd_fp::Fingerprint.new
  collection = []
  array_of_directory_names.each do |directory_name|
    puts "Processing: #{directory_name}"

    # Generate a fingerprint for each of the files.
    files = Dir.entries(directory_name).delete_if do |filename|
      filename !~ /\.(?:jpe?g|gif|png|tiff)\z/i
    end
    files.sort!  # Merely to help the human monitor progress from stdout.
    collection << Parallel.map(files) do |filename|
      puts "Found #{filename}"
      begin
        fp.compute_from_image_file(File.join(directory_name, filename), 2, 1)
      rescue Exception => e
        puts "Exception caught: [#{e}]"
        next
      end

      [filename, fp.as_int_array]
    end

    # Remove a level of nesting from the appending of an array from map,
    # and compact out any nils due to errors in processing.
    collection = collection.first.compact
    puts "Collection size: #{collection.length}"
  end

  { :filenames => collection.map(&:first), :fingerprints_as_ints => collection.map(&:last) }
end


def report_pairwise_compare_all_fingerprints(filenames_and_fingerprints)
  filenames = filenames_and_fingerprints[:filenames]
  fingerprints_as_ints = filenames_and_fingerprints[:fingerprints_as_ints]
  fp1 = Mwisd_fp::Fingerprint.new
  fp2 = Mwisd_fp::Fingerprint.new
  fingerprints_as_ints.each_index do |fp1_index|
    fp1.set_from_int_array(fingerprints_as_ints[fp1_index])
    fingerprints_as_ints[fp1_index+1, fingerprints_as_ints.length-fp1_index].each_index do |fp2_index|
      fp2.set_from_int_array(fingerprints_as_ints[fp2_index+fp1_index+1])
      similarity = fp1.compare(fp2)
      puts "#{filenames[fp1_index]} v. #{filenames[fp2_index+fp1_index+1]} : #{similarity}"
    end
  end
end


def deduplicate_filenames(filenames_and_fingerprints)
  # The dependency on filenames being unique keys in this example script is
  # not a good general solution, but it hopefully keeps the example simpler
  # to understand.  An alternative to skipping files with matching names
  # could be to uniquify the names, e.g. "file.txt" becomes "file.txt_".
  filenames = filenames_and_fingerprints[:filenames]
  fingerprints_as_ints = filenames_and_fingerprints[:fingerprints_as_ints]
  indexes_of_dupes = []
  filenames.each_index do |fn1_index|
    filename1 = filenames[fn1_index]
    filenames[fn1_index+1, filenames.length-fn1_index].each_index do |fn2_index|
      filename2 = filenames[fn2_index+fn1_index+1]
      if filename1 == filename2 then
        puts "Skipping non-uniquely named #{filename2}"
        indexes_of_dupes << (fn2_index + fn1_index + 1)
      end
    end
  end

  indexes_of_dupes.sort!.reverse!.each do |index|
    filenames.delete_at(index)
    fingerprints_as_ints.delete_at(index)
  end
  { :filenames => filenames, :fingerprints_as_ints => fingerprints_as_ints }
end


def deduplicate_fingerprints(filenames_and_fingerprints)
  # It is expected that in production use, this example script's design of
  # holding all fingerprints and filenames in memory like this would become
  # problematic and so will need to be adapted to efficiently run against
  # the datastore where the fingerprints and filenames are housed.
  filenames = filenames_and_fingerprints[:filenames]
  fingerprints_as_ints = filenames_and_fingerprints[:fingerprints_as_ints]
  fp1 = Mwisd_fp::Fingerprint.new
  fp2 = Mwisd_fp::Fingerprint.new
  indexes_of_dupes = []
  fingerprints_as_ints.each_index do |fp1_index|  # Could do this safely with Parallel
    fp1.set_from_int_array(fingerprints_as_ints[fp1_index])
    fingerprints_as_ints[fp1_index+1, fingerprints_as_ints.length-fp1_index].each_index do |fp2_index|
      fp2.set_from_int_array(fingerprints_as_ints[fp2_index+fp1_index+1])
      similarity = fp1.compare(fp2)
      if similarity > 0.999999999 then
        puts "Skipping #{filenames[fp1_index]} as a duplicate of #{filenames[fp2_index+fp1_index+1]}"
        if not (indexes_of_dupes.include? fp1_index) then  # Wasteful; should break to avoid instead.
          indexes_of_dupes << (fp1_index)
        end
      end
    end
  end

  indexes_of_dupes.sort!.reverse!.each do |index|
    filenames.delete_at(index)
    fingerprints_as_ints.delete_at(index)
  end
  { :filenames => filenames, :fingerprints_as_ints => fingerprints_as_ints }
end


def report_max_min_pairwise_compare_all_fingerprints(filenames_and_fingerprints)
  filenames = filenames_and_fingerprints[:filenames]
  fingerprints_as_ints = filenames_and_fingerprints[:fingerprints_as_ints]
  fp1 = Mwisd_fp::Fingerprint.new
  fp2 = Mwisd_fp::Fingerprint.new
  fingerprints_as_ints.each_index do |fp1_index|
    fp1_int_array = fingerprints_as_ints[fp1_index]
    fp1.set_from_int_array(fp1_int_array)
    max = 0.0
    min = 1.0
    fingerprints_as_ints.each do |fp2_int_array|
      fp2.set_from_int_array(fp2_int_array)
      similarity = fp1.compare(fp2)
      if similarity > max then
        if similarity < 1.0 then
          max = similarity
        else
          if fp1_int_array != fp2_int_array then
            max = similarity
          end
        end
      end
      if similarity < min then
        min = similarity
      end
    end
    puts "#{filenames[fp1_index]} max/min inter-similarity: #{max} #{min}"
  end
end


def construct_kd_tree(filenames_and_fingerprints, depth=0)
  # Build kd-tree starting (unintelligently) with the first input image.
  filenames = filenames_and_fingerprints[:filenames]
  collection = filenames_and_fingerprints[:fingerprints_as_ints]
  #puts "DBG #{depth}: filenames.length=#{filenames.length}"
  #puts "DBG #{depth}: #{filenames}"
  layer = bifurcate_fingerprints(collection - [collection[0]], collection[0])
  group_ge = {
    :filenames => layer[:greater_set].map {|index| filenames[index+1]},
    :fingerprints_as_ints =>
      layer[:greater_set].map {|index| collection[index+1]}
  }
  group_lt = {
    :filenames => layer[:lesser_set].map {|index| filenames[index+1]},
    :fingerprints_as_ints =>
      layer[:lesser_set].map {|index| collection[index+1]}
  }
  kd_tree = { filenames[0] => { :midpoint => layer[:midpoint],
                                :next_greater => group_ge[:filenames][0],
                                :next_lesser => group_lt[:filenames][0] } }
  if group_ge[:filenames].length > 1 then
    kd_tree.merge!(construct_kd_tree(group_ge, depth+1))
  end
  if group_lt[:filenames].length > 1 then
    kd_tree.merge!(construct_kd_tree(group_lt, depth+1))
  end
  if depth == 0 then
    kd_tree.merge!({ 0 => filenames[0] })
  end
  kd_tree
end


def construct_fkd_tree(filenames_and_fingerprints, epsilon=0.07, depth=0)
  # Build fuzzy kd-tree starting (unintelligently) with the first input image.
  filenames = filenames_and_fingerprints[:filenames]
  collection = filenames_and_fingerprints[:fingerprints_as_ints]
  #puts "DBG #{depth}: filenames.length=#{filenames.length}"
  #puts "DBG #{depth}: #{filenames}"
  layer = fuzzy_bifurcate_fingerprints(collection - [collection[0]], collection[0], epsilon)
  group_ge = {
    :filenames => layer[:greater_set].map {|index| filenames[index+1]},
    :fingerprints_as_ints =>
      layer[:greater_set].map {|index| collection[index+1]}
  }
  group_lt = {
    :filenames => layer[:lesser_set].map {|index| filenames[index+1]},
    :fingerprints_as_ints =>
      layer[:lesser_set].map {|index| collection[index+1]}
  }
  kd_tree = { filenames[0] => { :midpoint => layer[:midpoint],
                                :next_greater => group_ge[:filenames][0],
                                :next_lesser => group_lt[:filenames][0] } }
  if group_ge[:filenames].length > 1 then
    kd_tree.merge!(construct_fkd_tree(group_ge, epsilon, depth+1))
  end
  if group_lt[:filenames].length > 1 then
    kd_tree.merge!(construct_fkd_tree(group_lt, epsilon, depth+1))
  end
  if depth == 0 then
    kd_tree.merge!({ 0 => filenames[0] })
  end
  kd_tree
end


def search_for_matching_image(query_fp, fingerprints_db, kd_tree, matching_cutoff_score=0.93, next_node=nil, depth=0)
  fp = Mwisd_fp::Fingerprint.new
  if depth == 0 then
    next_node = kd_tree[0]
  end
  if next_node == nil then
    # No more branches in this direction (prior node had 1 branch, not 2).
    return { :finding => "no_match", :depth => depth-1, :matching_fp_id => nil }
  end
  fp.set_from_int_array(fingerprints_db[next_node])
  score = query_fp.compare(fp)
  epsilon = (1.0 - matching_cutoff_score) * 0.10
  result = {}
  if score > matching_cutoff_score then
    # Exact match found.
    return { :finding => "match", :depth => depth, :matching_fp_id => next_node }
  else
    if kd_tree[next_node] == nil then
      # Final leaf (no more branches off this one).
      return { :finding => "no_match", :depth => depth, :matching_fp_id => nil }
    else
      if score < kd_tree[next_node][:midpoint] then
        result = search_for_matching_image(query_fp, fingerprints_db, kd_tree,
                   matching_cutoff_score, kd_tree[next_node][:next_lesser],
                   depth+1)
        # Untested fix for fuzzy matches just barely being on the wrong side
        # of a midpoint and the search taking the wrong branch.  This should
        # preserve the scaling of the search at O(log N).  Questions remain
        # on the optimal setting for epsilon and the statistical bounds on how
        # frequently this condition can occur -- if too often, then alternate
        # solutions may be faster.
        if result[:finding] == "no_match" then
          if (score + epsilon) >= kd_tree[next_node][:midpoint] then
            result = search_for_matching_image(query_fp, fingerprints_db, kd_tree,
                       matching_cutoff_score, kd_tree[next_node][:next_greater],
                       depth+1)
            puts "DBG trigger epsilon +"
          end
        end
      else
        result = search_for_matching_image(query_fp, fingerprints_db, kd_tree,
                   matching_cutoff_score, kd_tree[next_node][:next_greater],
                   depth+1)
        # Second half of untested fix with mirror code from a few lines above.
        if result[:finding] == "no_match" then
          if (score - epsilon) <= kd_tree[next_node][:midpoint] then
            result = search_for_matching_image(query_fp, fingerprints_db, kd_tree,
                       matching_cutoff_score, kd_tree[next_node][:next_lesser],
                       depth+1)
            puts "DBG trigger epsilon -"
          end
        end
      end
    end
  end
  result
end


if ARGV.empty?
  filenames_and_fingerprints = YAML.load_file(File.expand_path('fixtures/filenames_and_fingerprints.yml', File.dirname(__FILE__)))
else
  # Compute fingerprints on all the files in the specified directories.
  filenames_and_fingerprints = fingerprint_all_images_in_directories(ARGV)
#  File.open(File.expand_path('fixtures/filenames_and_fingerprints.yml', File.dirname(__FILE__)), 'w') { |f| YAML.dump(filenames_and_fingerprints, f) }
end

# Compute and report all unique pairs of fingerprints (1/2 * N * (N-1)).
if filenames_and_fingerprints[:filenames].length <= 8 then
  report_pairwise_compare_all_fingerprints(filenames_and_fingerprints)
end

# Compute all pairs of fingerprints and report max/min info.
if filenames_and_fingerprints[:filenames].length <= 8 then
  report_max_min_pairwise_compare_all_fingerprints(filenames_and_fingerprints)
end

# De-duplicate the set of images (no fingerprint dupes and no filename dupes).
filenames_and_fingerprints = deduplicate_fingerprints(filenames_and_fingerprints)
if ARGV.length > 1 then
  # Only relevant if more than one directory of image files specified.
  filenames_and_fingerprints = deduplicate_filenames(filenames_and_fingerprints)
end

# Compute the kd-tree for subsequent fast searching.
kd_tree = construct_kd_tree(filenames_and_fingerprints)
puts "kd_tree.class: #{kd_tree.class}"
if filenames_and_fingerprints[:filenames].length <= 8 then
  puts "kd_tree: #{kd_tree}"
end

def run_searches(fingerprints_db, kd_tree, size)
  how_many = [fingerprints_db.keys.length, size].min
  fingerprints_db.keys[-how_many, how_many].each do |filename|
    fp = Mwisd_fp::Fingerprint.new
    fp.set_from_int_array(fingerprints_db[filename])
    result = search_for_matching_image(fp, fingerprints_db, kd_tree)
    puts "Search #{filename}: #{result[:finding]} #compares=#{result[:depth]}"
  end
end

fingerprints_db = Hash[filenames_and_fingerprints[:filenames].zip(filenames_and_fingerprints[:fingerprints_as_ints])]

# For each of (up to) the first 100 images, search for them in the kd-tree.
run_searches(fingerprints_db, kd_tree, 100)

# Manual check of what happens when searching for something not in tree.
fp = Mwisd_fp::Fingerprint.new
filename = File.expand_path('./fixtures/flag.jpg', File.dirname(__FILE__))
fp.compute_from_image_file(filename, 2, 1)
result = search_for_matching_image(fp, fingerprints_db, kd_tree)
puts "Manual search #{filename}: #{result[:finding]} #compares=#{result[:depth]}"
fp.transform_to_mirror  # Search again for mirror image
result = search_for_matching_image(fp, fingerprints_db, kd_tree)
puts "Manual mirror search #{filename}: #{result[:finding]} #compares=#{result[:depth]}"
