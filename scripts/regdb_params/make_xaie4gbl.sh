#!/bin/bash

# Check if required arguments are provided
if [ $# -lt 3 ]; then
    echo "Usage: $0 <ME_ROOT> <make_headers_path> <version>"
    echo "Example: $0 /path/to/me_root /path/to/make_headers.sh r0p0"
    exit 1
fi

# Set ME_ROOT, make_headers_path, and version from command line arguments
export ME_ROOT=$1
make_headers_path=$2
version=$3

if [ -z "$ME_ROOT" ]; then 
  echo "\$ME_ROOT not set."
  exit 1
fi

if [ -z "$make_headers_path" ]; then 
  echo "Path to make_headers.sh not set."
  exit 1
fi

if [ -z "$version" ]; then 
  echo "Version not set."
  exit 1
fi

# Ensure make_headers_path points to the actual make_headers.sh file
if [ -d "$make_headers_path" ]; then
    make_headers_path="$make_headers_path/make_headers.sh"
fi

if [ ! -f "$make_headers_path" ]; then
    echo "make_headers.sh not found at $make_headers_path"
    exit 1
fi

echo "ME_ROOT set to: $ME_ROOT"
echo "make_headers.sh path set to: $make_headers_path"
echo "Version set to: $version"

if [ ! -f "$ME_ROOT/make_headers.sh" ]; then
  echo "Copying make_headers.sh to ME_ROOT"
  cp $make_headers_path $ME_ROOT/make_headers.sh
else
  echo "make_headers.sh already exists in ME_ROOT, skipping copy"
fi

echo "Generating the headers files from regDB"
chmod +x $ME_ROOT/make_headers.sh
echo "Executing make_headers.sh..."
echo "Changing directory to: $ME_ROOT"
cd $ME_ROOT && echo "Current directory: $(pwd)" && ./make_headers.sh && echo "Changing back to previous directory" && cd - && echo "Current directory: $(pwd)"
echo "make_headers.sh execution completed"

rm -rf $ME_ROOT/all_headers.h
rm -rf $ME_ROOT/newfilewithoutcomments.h
rm -rf $ME_ROOT/xaie4gbl_params.h
rm -rf $ME_ROOT/xaie4gbltemp_params.h
rm -rf $ME_ROOT/regdb_*.h

sed -i 's/AIE4_/XAIE4GBL_/g' $ME_ROOT/*.h
cat $ME_ROOT/*.h > $ME_ROOT/all_headers.h

grep -v '^--' $ME_ROOT/all_headers.h > $ME_ROOT/newfilewithoutcomments.h
grep -v '^//' $ME_ROOT/newfilewithoutcomments.h > $ME_ROOT/xaie4gbltemp_params.h
sed '1,8d' $ME_ROOT/xaie4gbltemp_params.h > $ME_ROOT/xaie4gbl_params.h
sed -i 's/__/_/g' $ME_ROOT/xaie4gbl_params.h

sed -i '1i \ /*This file contains the macro definitions for the AIE4 registers, generated from regdb headers.
'  $ME_ROOT/xaie4gbl_params.h

sed -i '2i \ MODIFICATION HISTORY:
'  $ME_ROOT/xaie4gbl_params.h

sed -i '3i \ Ver   Who\t\t Date        Changes
'  $ME_ROOT/xaie4gbl_params.h

sed -i '4i \ '$version'   prathap   '$(date +%d/%m/%Y)'  Initial creation
'  $ME_ROOT/xaie4gbl_params.h

sed -i '5i \ ******************************************************************************/
'  $ME_ROOT/xaie4gbl_params.h

# Copy the final xaie4gbl_params.h to the script execution directory
cp $ME_ROOT/xaie4gbl_params.h $(pwd)

echo "Copied xaie4gbl_params.h to $(pwd)"

echo "Generated the xaie4gbl_params.h"