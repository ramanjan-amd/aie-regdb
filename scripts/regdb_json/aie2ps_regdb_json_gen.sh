#!/bin/bash
mkdir -p out_aie2ps
./bin/xregdb.py  aie2ps_r1p3_regdb/aie2ps_core_module.ods -regview_json out_aie2ps/aie2ps_core_module.json
./bin/xregdb.py  aie2ps_r1p3_regdb/aie2ps_memory_module.ods -regview_json out_aie2ps/aie2ps_memory_module.json
./bin/xregdb.py  aie2ps_r1p3_regdb/aie2ps_mem_tile_module.ods -regview_json out_aie2ps/aie2ps_mem_tile_module.json
./bin/xregdb.py  aie2ps_r1p3_regdb/aie2ps_noc_module.ods -regview_json out_aie2ps/aie2ps_noc_module.json
./bin/xregdb.py  aie2ps_r1p3_regdb/aie2ps_npi_regdb.ods -regview_json out_aie2ps/aie2ps_npi_regdb.json
./bin/xregdb.py  aie2ps_r1p3_regdb/aie2ps_pl_module.ods -regview_json out_aie2ps/aie2ps_pl_module.json
./bin/xregdb.py  aie2ps_r1p3_regdb/aie2ps_uc_module_core.ods -regview_json out_aie2ps/aie2ps_uc_module_core.json
./bin/xregdb.py  aie2ps_r1p3_regdb/aie2ps_uc_module.ods -regview_json out_aie2ps/aie2ps_uc_module.json

./post_process_regdb_json.py post_process_input_aie2ps.json

