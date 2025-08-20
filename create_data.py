import re
import struct
import sys
import os
from pathlib import Path


def parse_number(value_str: str) -> int:
    """Parse a number string that can be in decimal, hex, or binary format."""
    value_str = value_str.strip()
    
    if value_str.startswith('0x') or value_str.startswith('0X'):
        return int(value_str, 16)
    elif value_str.startswith('0b') or value_str.startswith('0B'):
        return int(value_str, 2)
    else:
        return int(value_str)


def extract_data_section(input_file: str) -> bytes:
    """Extract data from the .data section of a RISC-V assembly file."""
    try:
        with open(input_file, 'r') as f:
            content = f.read()
    except FileNotFoundError:
        print(f"Error: Input file '{input_file}' not found")
        sys.exit(1)
    except PermissionError:
        print(f"Error: Permission denied accessing file '{input_file}'")
        sys.exit(1)
    except Exception as e:
        print(f"Error reading file '{input_file}': {e}")
        sys.exit(1)
    
    # Find the .data section
    data_section_match = re.search(r'\.data\s*\n(.*)', content, re.DOTALL | re.IGNORECASE)
    if not data_section_match:
        print("No .data section found in the assembly file")
        return b''
    
    data_section = data_section_match.group(1)
    
    # Split into lines and process
    lines = data_section.split('\n')
    binary_data = bytearray()
    
    for line in lines:
        line = line.strip()
        
        # Skip empty lines and comments
        if not line or line.startswith('#') or line.startswith('//'):
            continue
        
        # Remove inline comments
        if '#' in line:
            line = line[:line.index('#')].strip()
        if '//' in line:
            line = line[:line.index('//')].strip()
        
        # Skip labels and other directives that aren't data
        if line.endswith(':') or line.startswith('.') and not any(directive in line.lower() for directive in ['.word', '.half', '.byte']):
            continue
        
        # Process .word directive (32-bit values)
        word_match = re.match(r'\.word\s+(.+)', line, re.IGNORECASE)
        if word_match:
            values = word_match.group(1).split(',')
            for value in values:
                value = value.strip()
                try:
                    num = parse_number(value)
                    # Convert to 32-bit signed integer and pack as little-endian
                    if num > 0x7FFFFFFF:
                        num = num - 0x100000000  # Convert to signed
                    binary_data.extend(struct.pack('<i', num))
                except ValueError as e:
                    print(f"Warning: Could not parse .word value '{value}': {e}")
            continue
        
        # Process .half directive (16-bit values)
        half_match = re.match(r'\.half\s+(.+)', line, re.IGNORECASE)
        if half_match:
            values = half_match.group(1).split(',')
            for value in values:
                value = value.strip()
                try:
                    num = parse_number(value)
                    # Convert to 16-bit signed integer and pack as little-endian
                    if num > 0x7FFF:
                        num = num - 0x10000  # Convert to signed
                    binary_data.extend(struct.pack('<h', num))
                except ValueError as e:
                    print(f"Warning: Could not parse .half value '{value}': {e}")
            continue
        
        # Process .byte directive (8-bit values)
        byte_match = re.match(r'\.byte\s+(.+)', line, re.IGNORECASE)
        if byte_match:
            values = byte_match.group(1).split(',')
            for value in values:
                value = value.strip()
                try:
                    num = parse_number(value)
                    # Convert to 8-bit signed integer and pack
                    if num > 0x7F:
                        num = num - 0x100  # Convert to signed
                    binary_data.extend(struct.pack('b', num))
                except ValueError as e:
                    print(f"Warning: Could not parse .byte value '{value}': {e}")
            continue
    
    return bytes(binary_data)


def write_memory_file(binary_data: bytes, input_file: str) -> None:
    """Write binary data to memory file in hexadecimal format."""
    try:
        with open('data.mem', 'w') as f:
            f.write("// Data memory initialization file\n")
            f.write(f"// Generated from: {os.path.basename(input_file)}\n")
            f.write("// Format: hexadecimal bytes\n")
            f.write(f"// File size: {len(binary_data)} bytes\n")
            f.write("\n")
            
            # Write hex bytes in groups of 16 per line
            for i in range(0, len(binary_data), 16):
                chunk = binary_data[i:i + 16]
                hex_bytes = [f"{byte:02X}" for byte in chunk]
                hex_line = " ".join(hex_bytes)
                f.write(hex_line)
                if i + 16 < len(binary_data):
                    f.write("\n")
                else:
                    f.write("\n")
        
        print(f"Successfully created 'data.mem' with {len(binary_data)} bytes")
        
    except PermissionError:
        print("Error: Permission denied writing to 'data.mem'")
        sys.exit(1)
    except Exception as e:
        print(f"Error writing memory file: {e}")
        sys.exit(1)


def main() -> None:
    """Main function to extract data and create memory file."""
    if len(sys.argv) != 2:
        print("Usage: python create_data.py <assembly_file>")
        print("Example: python create_data.py example.s")
        sys.exit(1)
    
    input_file = sys.argv[1]
    
    # Validate input file extension
    if not input_file.lower().endswith('.s'):
        print("Warning: Input file doesn't have .s extension")
    
    # Check if assembly file exists
    if not Path(input_file).exists():
        print(f"Error: Assembly file '{input_file}' not found")
        sys.exit(1)
    
    # Extract data from assembly file
    print(f"Extracting data from '{input_file}'...")
    binary_data = extract_data_section(input_file)
    
    if not binary_data:
        print("No data found to extract")
        sys.exit(1)
    
    # Write memory file
    write_memory_file(binary_data, input_file)
    
    # Display the binary data in hex format for verification
    print("Data extracted (little-endian format):")
    for i in range(0, len(binary_data), 16):
        hex_bytes = ' '.join(f'{b:02x}' for b in binary_data[i:i+16])
        print(f"  {i:04x}: {hex_bytes}")


if __name__ == "__main__":
    main()