#!/bin/bash

if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <input_directory> <regdb_version>"
    exit 1
fi

# clean up modules from pandora
source /tools/pandora64/etc/modules/INIT/bash
module purge
unset MODULEPATH

#Load Reg DB
source /tools/local/bin/modinit.sh
module use /tools/gvt/common/modulefiles/
module load xregdb

INPUT_DIR=$1
REGDB_VERSION=$2
OUTPUT_DIR="out"

if [ -d "$OUTPUT_DIR" ]; then
    rm -rf "$OUTPUT_DIR"
fi
mkdir -p "$OUTPUT_DIR"

for ods_file in $INPUT_DIR/*.ods; do
    base_name=$(basename "$ods_file" .ods)
    if [ -f "$INPUT_DIR/${base_name}.h" ]; then
        xregdb.py "$ods_file" -regview_json "$OUTPUT_DIR/${base_name}.json"
    fi
done

#xregdb.py  $INPUT_DIR/aie4_uc_module.ods -regview_json $OUTPUT_DIR/aie4_uc_module_b.json -base_addr 0x40000

#sed -i 's/AIE4_UC_MODULE/AIE4_UC_MODULE_A/' $OUTPUT_DIR/aie4_uc_module_a.json
#sed -i 's/AIE4_UC_MODULE/AIE4_UC_MODULE_B/' $OUTPUT_DIR/aie4_uc_module_b.json

./post_process_regdb_json.py post_process_input_aie4.json aie4_regdb_$REGDB_VERSION.json

