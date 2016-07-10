require 'mkmf'

LIBDIR     = RbConfig::CONFIG['libdir']
INCLUDEDIR = RbConfig::CONFIG['includedir']

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

dir_config('mwisd_fp', HEADER_DIRS, LIB_DIRS)

have_header('ruby.h') || missing('ruby.h')

have_library('png', 'png_sig_cmp') || missing('libpng')

have_library('jpeg', 'jpeg_set_defaults') || missing('libjpeg')

have_library('tiff', 'TIFFSetDirectory') || missing('libtiff')

# For some reason, mkmf falls back to using gcc to link c++ binaries.
# Use a big hammer and force it to use g++ for everything.
#
# We set this via multiple methods to we can support more versions of Ruby.
link_command('g++')
$CXX = "g++"
RbConfig::MAKEFILE_CONFIG['CC'] = $CXX

# OSX *does* need to use gcc for linking.
if RUBY_PLATFORM !~ /darwin/
  RbConfig::MAKEFILE_CONFIG['LDSHARED'] = "#{$CXX} -shared"
end

if have_library('X11')
  RbConfig::MAKEFILE_CONFIG['LDSHARED'] << " -pthread -lX11"
  RbConfig::MAKEFILE_CONFIG['LDSHAREDXX'] << " -pthread -lX11"
end

# Why does this fail, even when explicitly giving the correct path?
# It's found just fine during compilation.
#unless find_header('CImg.h')
#  abort 'Unable to find the CImg.h header file'
#end

create_makefile('mwisd_fp/mwisd_fp')
