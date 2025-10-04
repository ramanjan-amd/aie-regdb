#!/usr/bin/python3

import json
import sys
import os

def combine_modules(modules, module_names, combined_name):
    combined_module = {
        'registers': {},
        'base_address': '0x00000000'
    }

    for module_name in module_names:
        if module_name not in modules:
            print(f"Warning: Module '{module_name}' not found in input data.")
            continue  # Skip missing modules

        module = modules[module_name]
        print(f"Combining module: {module_name}")  # Debug log

        for address, register in module.get('registers', {}).items():
            if address in combined_module['registers']:
                print(f"Warning: Address conflict at {address} for module {module_name}. Overwriting.")
            combined_module['registers'][address] = register

        # Update base_address if not default
        if module.get('base_address', '0x00000000') != '0x00000000':
            combined_module['base_address'] = module['base_address']

        # Remove the original module
        del modules[module_name]

    modules[combined_name] = combined_module
    print(f"Combined module '{combined_name}' created with {len(combined_module['registers'])} registers.")  # Debug log

def combine_final_regdb(input_files, output_file):
    combined_data = {}

    for input_file, node_name in input_files.items():
        if not os.path.exists(input_file):
            print(f"Error: Input file {input_file} does not exist.")
            sys.exit(1)

        with open(input_file, 'r') as file:
            data = json.load(file)
            if 'modules' not in data or node_name not in data['modules']:
                print(f"Error: Node '{node_name}' not found under 'modules' in {input_file}.")
                sys.exit(1)

            # Extract the node content from the 'modules' key
            combined_data[node_name] = data['modules'][node_name]

    # Write the combined output to the specified file
    with open(output_file, 'w') as file:
        json.dump(combined_data, file, indent=4)

def process_input_description(input_description_file, final_output_file):
    with open(input_description_file, 'r') as file:
        input_description = json.load(file)

    for tile_type, tile_data in input_description.items():
        print(f"Processing tile type: {tile_type}")  # Debug log

        if tile_type == "final_regdb":
            input_files = tile_data['input']
            # Use the provided final_output_file instead of the one in the JSON
            combine_final_regdb(input_files, final_output_file)
            continue

        input_files = tile_data['input']
        output_file, combined_name = list(tile_data['output'].items())[0]

        modules = {}
        for input_file, module_name in input_files.items():
            if not os.path.exists(input_file):
                print(f"Error: Input file {input_file} does not exist.")
                sys.exit(1)

            with open(input_file, 'r') as file:
                data = json.load(file)
                if 'modules' not in data:
                    print(f"Error: 'modules' key not found in {input_file}.")
                    sys.exit(1)

                if module_name not in data['modules']:
                    print(f"Warning: Module '{module_name}' not found in {input_file}. Skipping.")
                    continue

                modules[module_name] = data['modules'][module_name]

        combine_modules(modules, list(input_files.values()), combined_name)

        # Write the combined output to the specified file
        with open(output_file, 'w') as file:
            json.dump({'modules': modules}, file, indent=4)
        print(f"Output written to {output_file}")  # Debug log

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage:")
        print("  python post_process_regdb_json.py <post_process_input.json> <final_output.json>")
        sys.exit(1)

    input_description_file = sys.argv[1]
    final_output_file = sys.argv[2]
    process_input_description(input_description_file, final_output_file)
