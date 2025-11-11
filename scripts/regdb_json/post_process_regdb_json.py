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

    # Sort the combined registers by address numerically
    sorted_registers = {}
    address_list = [(int(addr, 16), addr, reg) for addr, reg in combined_module['registers'].items()]
    address_list.sort(key=lambda x: x[0])  # Sort by numerical address value
    
    for _, addr_str, register in address_list:
        sorted_registers[addr_str] = register
    
    combined_module['registers'] = sorted_registers
    modules[combined_name] = combined_module
    print(f"Combined module '{combined_name}' created with {len(combined_module['registers'])} registers.")  # Debug log

def combine_final_regdb(input_files, output_file, device_generation=None, regdb_version=None):
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

            # Extract the node content from the 'modules' key and sort registers by address
            module_data = data['modules'][node_name]
            if 'registers' in module_data:
                # Sort registers by address numerically
                registers = module_data['registers']
                address_list = [(int(addr, 16), addr, reg) for addr, reg in registers.items()]
                address_list.sort(key=lambda x: x[0])  # Sort by numerical address value
                
                sorted_registers = {}
                for _, addr_str, register in address_list:
                    sorted_registers[addr_str] = register
                
                module_data['registers'] = sorted_registers
            
            combined_data[node_name] = module_data

    # Write the combined output to the specified file with modules wrapper
    final_output = {}
    
    # Add device generation and RegDB version if provided
    if device_generation:
        final_output["Device Generation"] = device_generation
    if regdb_version:
        final_output["RegDB Version"] = regdb_version
    
    # Add the modules data
    final_output["modules"] = combined_data
    
    with open(output_file, 'w') as file:
        json.dump(final_output, file, indent=4)

def process_input_description(input_description_file, final_output_file=None, device_generation=None, regdb_version=None):
    with open(input_description_file, 'r') as file:
        input_description = json.load(file)

    for tile_type, tile_data in input_description.items():
        print(f"Processing tile type: {tile_type}")  # Debug log

        if tile_type == "final_regdb":
            input_files = tile_data['input']
            # Use the provided final_output_file if given, otherwise use the default from JSON
            if final_output_file:
                output_file = final_output_file
            else:
                output_file, _ = list(tile_data['output'].items())[0]
            combine_final_regdb(input_files, output_file, device_generation, regdb_version)
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

                # Sort registers in each module by address before combining
                module_data = data['modules'][module_name]
                if 'registers' in module_data:
                    registers = module_data['registers']
                    address_list = [(int(addr, 16), addr, reg) for addr, reg in registers.items()]
                    address_list.sort(key=lambda x: x[0])  # Sort by numerical address value
                    
                    sorted_registers = {}
                    for _, addr_str, register in address_list:
                        sorted_registers[addr_str] = register
                    
                    module_data['registers'] = sorted_registers

                modules[module_name] = module_data

        combine_modules(modules, list(input_files.values()), combined_name)

        # Write the combined output to the specified file
        with open(output_file, 'w') as file:
            json.dump({'modules': modules}, file, indent=4)
        print(f"Output written to {output_file}")  # Debug log

if __name__ == "__main__":
    if len(sys.argv) < 2 or len(sys.argv) > 5:
        print("Usage:")
        print("  python post_process_regdb_json.py <post_process_input.json> [output_filename] [device_generation] [regdb_version]")
        print("  If output_filename is provided, it will be used for the final regdb output.")
        print("  If device_generation is provided, it will be added to the final output (e.g., AIE4, AIE2PS, AIE2P).")
        print("  If regdb_version is provided, it will be added to the final output (e.g., r0p48, r1p4).")
        sys.exit(1)

    input_description_file = sys.argv[1]
    final_output_file = sys.argv[2] if len(sys.argv) >= 3 else None
    device_generation = sys.argv[3] if len(sys.argv) >= 4 else None
    regdb_version = sys.argv[4] if len(sys.argv) >= 5 else None
    
    # Print processing details
    print("=== RegDB JSON Post-Processing Started ===")
    print(f"Configuration file: {input_description_file}")
    if final_output_file:
        print(f"Final output file: {final_output_file}")
    else:
        print("Final output file: Will use default from configuration")
    if device_generation:
        print(f"Device Generation: {device_generation}")
    if regdb_version:
        print(f"RegDB Version: {regdb_version}")
    print("=" * 45)
    
    process_input_description(input_description_file, final_output_file, device_generation, regdb_version)
    
    print("=" * 45)
    print("=== RegDB JSON Post-Processing Completed ===")
    if final_output_file:
        print(f"Final RegDB file generated: {final_output_file}")
    print("=" * 47)
