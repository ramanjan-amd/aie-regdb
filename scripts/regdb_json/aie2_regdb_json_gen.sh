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

for ods_file in $INPUT_DIR/*.ods; do
    base_name=$(basename "$ods_file" .ods)
    if [ -f "$INPUT_DIR/${base_name}.h" ]; then
        xregdb.py "$ods_file" -regview_json "$OUTPUT_DIR/${base_name}.json"
    fi
done

# Generate dynamic configuration
TEMP_CONFIG="temp_post_process_config_aie2p.json"
cat > $TEMP_CONFIG << EOF
{
    "core_tile": {
        "input": {
            "$OUTPUT_DIR/aie2p_core_module.json": "AIE2P_CORE_MODULE",
            "$OUTPUT_DIR/aie2p_memory_module.json": "AIE2P_MEMORY_MODULE"
        },
        "output": {
            "$OUTPUT_DIR/aie2p_core.json": "AIE2P_CORE_TILE"
        }
    },
    "mem_tile": {
        "input": {
            "$OUTPUT_DIR/aie2p_mem_tile_module.json": "AIE2P_MEM_TILE_MODULE"
        },
        "output": {
            "$OUTPUT_DIR/aie2p_mem.json": "AIE2P_MEM_TILE"
        }
    },
    "shim_tile": {
        "input": {
            "$OUTPUT_DIR/aie2p_noc_module.json": "AIE2P_NOC_MODULE",
            "$OUTPUT_DIR/aie2p_pl_module.json": "AIE2P_PL_MODULE"
        },
        "output": {
            "$OUTPUT_DIR/aie2p_shim.json": "AIE2P_SHIM_TILE"
        }
    },
    "final_regdb": {
        "input": {
            "$OUTPUT_DIR/aie2p_core.json": "AIE2P_CORE_TILE",
            "$OUTPUT_DIR/aie2p_mem.json": "AIE2P_MEM_TILE",
            "$OUTPUT_DIR/aie2p_shim.json": "AIE2P_SHIM_TILE"
        },
        "output": {
            "$OUTPUT_DIR/aie2p_regdb.json": "AIE2P_REGDB"
        }
    }
}
EOF

./post_process_regdb_json.py $TEMP_CONFIG aie2p_regdb.json AIE2P $REGDB_VERSION

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