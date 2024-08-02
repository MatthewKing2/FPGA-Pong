
//------------------------------------------------------------------------------
// Module: BlockRam
// Description: A parameterizable block RAM module for FPGA designs. This module 
//              implements a read/write memory with configurable address bus size,
//              number of elements, and element size. It supports initialization 
//              from a file and handles read and write operations based on control signals.
// Parameters:
//  - INIT_FILE: File name for initializing the memory contents (in binary format).
//  - AddrBusSize: Width of the address bus in bits, determines the number of addressable
//                  elements (2^AddrBusSize).
//  - NumElements: Total number of memory elements (must be less than or equal to 2^AddrBusSize).
//  - ElementSize: Size of each memory element in bits.
// Inputs:
//  - i_CLK: System clock signal.
//  - i_write_en: Write enable signal, activates memory write operations.
//  - i_read_en: Read enable signal, activates memory read operations.
//  - i_write_addr: Address for writing data to memory.
//  - i_read_addr: Address for reading data from memory.
//  - i_write_data: Data to be written into memory.
// Outputs:
//  - o_read_data: Data read from memory.
//------------------------------------------------------------------------------

module BlockRam #( 
    parameter       INIT_FILE   = "",   // Default to NULL (initalizes no values into memory)
    parameter       AddrBusSize = 9,    
    parameter       NumElements = 512,  
    parameter       ElementSize = 8)(   
    input   wire                            i_CLK,
    // Enable Singals
    input   wire                            i_write_en,
    input   wire                            i_read_en,
    // Addresses
    input   wire    [AddrBusSize-1: 0]      i_write_addr,
    input   wire    [AddrBusSize-1: 0]      i_read_addr,
    // Data
    input   wire    [ElementSize-1: 0]      i_write_data,
    output  reg     [ElementSize-1: 0]      o_read_data);

    //------------------------------------------------------------------------------
    // Memory Declaration
    // Description: Declares the block RAM memory array with the specified size and 
    //              element width. The synthesizer assumes the use of block RAM based 
    //              on this declaration. The array is defined with a size of NumElements
    //              and each element is ElementSize bits wide.
    // Note: This delcaration notation does not use 2^AddrBusSize to determine the
    //       number of elements. You must specific the exact number of elements.
    //------------------------------------------------------------------------------
    reg [ElementSize-1: 0] memory [NumElements];

    //------------------------------------------------------------------------------
    // Read/Write Operations
    // Description: Handles memory read and write operations on the rising edge of the
    //              clock signal. If the write enable signal (i_write_en) is asserted, 
    //              data is written to the specified address (i_write_addr). If the read 
    //              enable signal (i_read_en) is asserted, data is read from the specified 
    //              address (i_read_addr) and provided on the output (o_read_data).
    //------------------------------------------------------------------------------
    always @(posedge i_CLK) begin
        if(i_write_en) begin 
            memory[i_write_addr] <= i_write_data;
        end
        if(i_read_en) begin 
            o_read_data <= memory[i_read_addr];
        end
    end

    //------------------------------------------------------------------------------
    // Memory Initialization
    // Description: Initializes the memory contents from a file specified by INIT_FILE.
    //              This block uses the $readmemb system function to load binary data into 
    //              the memory. Initialization is only performed if INIT_FILE is specified.
    // Note: This is a rare case where inital blocks work in synthesizable verilog.
    //------------------------------------------------------------------------------
    initial if (INIT_FILE) begin
        $readmemb(INIT_FILE, memory);
    end

endmodule