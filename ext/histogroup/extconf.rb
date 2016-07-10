require 'mkmf'

LIBDIR     = Config::CONFIG['libdir']
INCLUDEDIR = Config::CONFIG['includedir']

HEADER_DIRS = [
  File.expand_path('../../extern', File.dirname(__FILE__)),
  '/opt/local/include', # macports
  '/usr/X11/include',   # homebrew
  INCLUDEDIR,           # ruby install
  '/usr/include',
  '/usr/local/include'
]

LIB_DIRS = [
  '/opt/local/lib', # macports
  '/usr/X11/lib',   # homebrew
  LIBDIR,           # ruby install
  '/usr/lib',
  '/usr/local/lib'
]

dir_config('histogroup', HEADER_DIRS, LIB_DIRS)

unless find_header('ruby.h')
  abort 'unable to find the ruby.h file to create the module.'
end

unless find_library('png', 'png_sig_cmp')
  abort "Unable to find libpng. Please install it."
end

unless find_library('jpeg', 'jpeg_set_defaults')
  abort "Unable to find libjpeg. Please install it."
end

unless find_library('tiff', 'TIFFSetDirectory')
  abort "Unable to find libtiff. Please install it."
end


# For some reason, mkmf falls back to using gcc to link c++ binaries.
# Use a big hammer and force it to use g++ for everything.
#
# We set this via multiple methods to we can support more versions of Ruby.
link_command('g++')
$CXX = "g++"
Config::MAKEFILE_CONFIG['CC'] = $CXX

# OSX *does* need to use gcc for linking.
if RUBY_PLATFORM !~ /darwin/
  Config::MAKEFILE_CONFIG['LDSHARED'] = "#{$CXX} -shared"
end

# Why does this fail, even when explicitly giving the correct path?
# It's found just fine during compilation.
#unless find_header('CImg.h')
#  abort 'Unable to find the CImg.h header file'
#end

create_makefile('histogroup/histogroup')
