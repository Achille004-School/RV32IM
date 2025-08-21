import sys
import os
from pathlib import Path


def read_binary_file(input_file: str) -> bytes:
    """Read binary data from input file."""
    try:
        with open(input_file, 'rb') as f:
            binary_data = f.read()
        
        if not binary_data:
            print(f"Warning: Input file '{input_file}' is empty")
            return b''
        
        return binary_data
        
    except FileNotFoundError:
        print(f"Error: Input file '{input_file}' not found")
        sys.exit(1)
    except PermissionError:
        print(f"Error: Permission denied accessing file '{input_file}'")
        sys.exit(1)
    except Exception as e:
        print(f"Error reading file '{input_file}': {e}")
        sys.exit(1)


def write_memory_file(binary_data: bytes, input_file: str) -> None:
    """Write binary data to memory file in hexadecimal format."""
    try:
        with open('instructions.mem', 'w') as f:
            f.write("// Instruction memory initialization file\n")
            f.write(f"// Generated from: {os.path.basename(input_file)}\n")
            f.write("// Format: hexadecimal bytes\n")
            f.write(f"// File size: {len(binary_data)} bytes\n")
            f.write("\n")
            
            # Convert binary data to hexadecimal (4 bytes per line for instructions)
            for i in range(0, len(binary_data), 4):
                chunk = binary_data[i:i + 4]
                # Reverse byte order for little-endian to big-endian conversion
                hex_bytes = [f"{byte:02X}" for byte in reversed(chunk)]
                hex_line = "".join(hex_bytes)
                f.write(hex_line)
                if i + 4 < len(binary_data):
                    f.write("\n")
                else:
                    f.write("\n")
        
        print(f"Successfully created 'instructions.mem' with {len(binary_data)} bytes")
        
    except PermissionError:
        print("Error: Permission denied writing to 'instructions.mem'")
        sys.exit(1)
    except Exception as e:
        print(f"Error writing memory file: {e}")
        sys.exit(1)


def bin_to_mem(input_file: str) -> None:
    """Convert binary file to memory initialization format."""
    # Read binary data
    binary_data = read_binary_file(input_file)
    
    if not binary_data:
        return
    
    # Write memory file
    write_memory_file(binary_data, input_file)


def main() -> None:
    """Main function to handle command line arguments and convert binary to memory file."""
    if len(sys.argv) != 2:
        print("Usage: python create_instructions.py <binary_file>")
        print("Example: python create_instructions.py example.bin")
        sys.exit(1)
    
    input_file = sys.argv[1]
    
    # Validate input file extension
    if not input_file.lower().endswith('.bin'):
        print("Warning: Input file doesn't have .bin extension")
    
    # Check if input file exists
    if not Path(input_file).exists():
        print(f"Error: Binary file '{input_file}' not found")
        sys.exit(1)
    
    # Convert the file
    print(f"Converting '{input_file}' to memory format...")
    bin_to_mem(input_file)


if __name__ == "__main__":
    main()