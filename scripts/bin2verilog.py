#!/usr/bin/env python3
"""
Convert binary file to a Verilog boot ROM lookup module
Usage: python bin2verilog.py <input.bin> [output.v] [module_name]
"""

import sys
import math

def bin2verilog(input_file, output_file, module_name="bootrom_mem"):
    """
    Convert binary file to a Verilog boot ROM lookup module.
    
    Args:
        input_file: Path to input binary file
        output_file: Path to output .v file
        module_name: Name of the Verilog module (default: bootrom_mem)
    """
    with open(input_file, "rb") as f:
        bindata = f.read()
    
    # Pad to 4-byte alignment if needed
    padding_needed = (4 - (len(bindata) % 4)) % 4
    if padding_needed:
        bindata += b'\x00' * padding_needed
        print(f"Padded {padding_needed} bytes to align to 4-byte boundary")
    
    # Convert to 32-bit words
    num_words = len(bindata) // 4
    words = []
    for i in range(num_words):
        word_bytes = bindata[i*4 : i*4+4]
        # Little-endian: byte0 is LSB
        word = (word_bytes[3] << 24) | (word_bytes[2] << 16) | (word_bytes[1] << 8) | word_bytes[0]
        words.append(word)
    
    # Match the requested ROM lookup style while still supporting arbitrary image sizes.
    case_addr_width = max(12, max(1, (num_words - 1).bit_length()))
    case_addr_msb = case_addr_width - 1
    case_hex_digits = math.ceil(case_addr_width / 4)
    boot_done_addr = max(0, num_words - 1)

    with open(output_file, "w") as f:
        # Write module header
        f.write("// Bootrom memory lookup module\n")
        f.write(f"// Generated from: {input_file}\n")
        f.write(f"// Size: {len(bindata)} bytes ({num_words} words)\n")
        f.write(f"// Addressing mode: word address on addr[{case_addr_msb}:0]\n\n")

        f.write(f"module {module_name} (\n")
        f.write("    input  wire        clk,\n")
        f.write("    input  wire        rst_n,\n")
        f.write("    input  wire [31:0] addr,\n")
        f.write("    input  wire        ce,\n")
        f.write("    output wire [31:0] dataout\n")
        f.write(");\n\n")

        f.write("    //----------------------------------//\n")
        f.write("    // Intermediate internal signals\n")
        f.write("    //----------------------------------//\n")
        f.write("    reg boot_done_reg;\n")
        f.write("    reg [31:0] dout;\n\n")

        f.write("    /*\n")
        f.write("     * Sticky status register update.\n")
        f.write("     * Clears boot_done_reg on reset and sets it when the completion\n")
        f.write("     * address is observed during an enabled access.\n")
        f.write("     */\n")
        f.write("    always @(posedge clk or negedge rst_n)\n")
        f.write("    begin\n")
        f.write("        if (!rst_n)\n")
        f.write("            boot_done_reg <= 1'b0;\n")
        f.write(f"        else if (ce && (addr == 32'h{boot_done_addr:08X}))\n")
        f.write("            boot_done_reg <= 1'b1;\n")
        f.write("    end\n\n")

        f.write("    /*\n")
        f.write("     * Boot ROM lookup logic.\n")
        f.write("     * When ce is asserted, returns the instruction mapped to the\n")
        f.write("     * generated word-address slice below.\n")
        f.write("     * When ce is deasserted, returns a NOP value.\n")
        f.write("     */\n")
        f.write("    always @(*)\n")
        f.write("    begin\n")
        f.write("        if (ce)\n")
        f.write(f"            case (addr[{case_addr_msb}:0])\n")

        for i, word in enumerate(words):
            f.write(f"                {case_addr_width}'h{i:0{case_hex_digits}x}: dout = 32'h{word:08x};\n")

        f.write("                default: dout = 32'h00000013; // RISC-V NOP\n")
        f.write("            endcase\n")
        f.write("        else\n")
        f.write("            dout = 32'h00000013; // Default to NOP when disabled\n")
        f.write("    end\n\n")

        f.write("    // Output mapping from internal ROM data register.\n")
        f.write("    assign dataout = dout;\n\n")
        f.write("endmodule\n")
    
    print(f"Converted {input_file} to {output_file}")
    print(f"Module name: {module_name}")
    print(f"Memory size: {num_words} words ({len(bindata)} bytes)")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python bin2verilog.py <input.bin> [output.v] [module_name]", file=sys.stderr)
        print("\nExamples:", file=sys.stderr)
        print("  python bin2verilog.py bootrom.bin                    # output: bootrom.v, module: bootrom_mem", file=sys.stderr)
        print("  python bin2verilog.py bootrom.bin bootrom_init.v     # custom output name", file=sys.stderr)
        print("  python bin2verilog.py bootrom.bin bootrom.v my_rom   # custom module name", file=sys.stderr)
        sys.exit(1)
    
    input_file = sys.argv[1]
    
    # Default output filename: replace extension with .v
    if len(sys.argv) > 2:
        output_file = sys.argv[2]
    else:
        output_file = input_file.rsplit('.', 1)[0] + '.v'
    
    # Module name
    if len(sys.argv) > 3:
        module_name = sys.argv[3]
    else:
        module_name = "bootrom_mem"
    
    bin2verilog(input_file, output_file, module_name)
