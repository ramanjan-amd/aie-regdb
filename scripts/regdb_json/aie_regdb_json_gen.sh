#!/bin/bash

if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <input_directory_for_RegDB> <RegDB_version>"
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

echo "Looking for .ods files in: $INPUT_DIR"
if ls $INPUT_DIR/*.ods 1> /dev/null 2>&1; then
    echo "Found .ods files:"
    ls -la $INPUT_DIR/*.ods
else
    echo "No .ods files found in $INPUT_DIR"
    exit 1
fi

echo ""
echo "Processing .ods files..."

for ods_file in $INPUT_DIR/*.ods; do
    base_name=$(basename "$ods_file" .ods)
    if [ -f "$INPUT_DIR/${base_name}.h" ]; then
        xregdb.py "$ods_file" -regview_json "$OUTPUT_DIR/${base_name}.json"
    fi
done

echo ""
echo "Generated JSON files:"
if ls $OUTPUT_DIR/*.json 1> /dev/null 2>&1; then
    ls -la $OUTPUT_DIR/*.json
else
    echo "No JSON files were generated!"
    exit 1
fi

# Generate dynamic configuration
TEMP_CONFIG="temp_post_process_config_me.json"
cat > $TEMP_CONFIG << EOF
{
    "core_tile": {
        "input": {
            "$OUTPUT_DIR/me_core_module.json": "ME_CORE_MODULE",
            "$OUTPUT_DIR/me_memory_module.json": "ME_MEMORY_MODULE"
        },
        "output": {
            "$OUTPUT_DIR/me_core.json": "ME_ME_TILE"
        }
    },
    "shim_tile": {
        "input": {
            "$OUTPUT_DIR/me_noc_module.json": "ME_NOC_MODULE",
            "$OUTPUT_DIR/me_pl_module.json": "ME_PL_MODULE"
        },
        "output": {
            "$OUTPUT_DIR/me_shim.json": "ME_SHIM_TILE"
        }
    },
    "npi": {
        "input": {
            "$OUTPUT_DIR/me_npi_regdb.json": "ME_NPI"
        },
        "output": {
            "$OUTPUT_DIR/me_npi.json": "ME_NPI"
        }
    },
    "final_regdb": {
        "input": {
            "$OUTPUT_DIR/me_core.json": "ME_ME_TILE",
            "$OUTPUT_DIR/me_shim.json": "ME_SHIM_TILE",
            "$OUTPUT_DIR/me_npi.json": "ME_NPI"
        },
        "output": {
            "$OUTPUT_DIR/me_regdb.json": "ME_REGDB"
        }
    }
}
EOF

./post_process_regdb_json.py $TEMP_CONFIG me_regdb.json ME $REGDB_VERSION

# Check if post_process_regdb_json.py executed successfully
if [ $? -eq 0 ]; then
    echo "RegDB processing completed successfully. Cleaning up temporary files..."
    # Clean up temporary config and intermediate files
    rm -f $TEMP_CONFIG
    rm -rf "$OUTPUT_DIR"
    rm -f xregdb_log.html
    echo "Cleanup completed."
else
    echo "Error: RegDB processing failed. Temporary files preserved for debugging."
    echo "Temporary config: $TEMP_CONFIG"
    echo "Output directory: $OUTPUT_DIR"
    exit 1
fi