
module BlockRam #( 
    parameter       INIT_FILE   = "",   // Default to NULL (no values into memory)
    parameter       AddrBusSize = 9,    // 9 bit bus size 
    parameter       NumElements = 512,  // 512 Elements (2^addrBusSize)
    parameter       ElementSize = 8)(   // Each element is 8 Bits
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


    // Create (Delcare) the memory
        // The synthesizer will assume that i mean to use block ram
        // reg [number of bits per element] name [number of elements]
        // Note: the last one is not 2^something, its just the value (stupid)
    reg [ElementSize-1: 0] memory [NumElements];

    // @ the CLK, read or write to memory
    always @(posedge i_CLK) begin

        if(i_write_en) begin 
            memory[i_write_addr] <= i_write_data;
        end

        if(i_read_en) begin 
            o_read_data <= memory[i_read_addr];
        end

    end

    // Init the memory
        // Uses the system function $readmemh
        // This is a rare case where inital blocks work in synthesizable verilog
    initial if (INIT_FILE) begin
        // $readmemh(INIT_FILE, memory);
        $readmemb(INIT_FILE, memory);
    end

endmodule