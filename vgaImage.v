
// Module draws an image (using Block RAM) at X,Y with H,W 

module vgaImage #(
    parameter           HEIGHT  = 20,
    parameter           WIDTH   = 20)(
    input   wire        i_CLK,
    input   wire        i_hSync,
    input   wire        i_vSync,
    input   wire [9:0]  i_display_x_pos,
    input   wire [9:0]  i_display_y_pos,
    input   wire [9:0]  i_rect_y_pos,       // My X
    input   wire [9:0]  i_rect_x_pos,       // My Y
    output  reg  [2:0]  o_red,       
    output  reg  [2:0]  o_green,     
    output  reg  [2:0]  o_blue,      
    output  reg         o_hSync,   
    output  reg         o_vSync);  


    // Parameters
    parameter       BusSize     = 9;    // Bits
    parameter       NumElements = 400; 
    parameter       DataSize    = 8;    // Bits

    // Local Regs / Wires
    reg                     r_read_en = 1'b1;
    reg  [BusSize-1: 0]     r_read_addr = 0; 
    wire [DataSize-1: 0]    w_read_data;

    // Init the Block Ram which contains the image
    BlockRam #(.INIT_FILE("skyFace.txt"), .AddrBusSize(BusSize), .NumElements(NumElements), .ElementSize(DataSize)) 
        bRam1 (
        .i_CLK(i_CLK),
        .i_write_en(0),
        .i_read_en(r_read_en),
        .i_write_addr(0),
        .i_read_addr(r_read_addr),  
        .i_write_data(0),  
        .o_read_data(w_read_data),  
    );

    // Main Logic 
    always @( posedge i_CLK ) begin
        // Draw balck outside of screen 
        if( i_display_x_pos >= 640 || i_display_y_pos >= 480 ) begin
            o_red   <= 0;
            o_green <= 0;
            o_blue  <= 0;
        end
        // Draw Pattern when one screen 
        else begin
            // If inside the rectangle, white
            if((i_rect_x_pos <= i_display_x_pos) && (i_display_x_pos < i_rect_x_pos + WIDTH) 
            && (i_rect_y_pos <= i_display_y_pos) && (i_display_y_pos < i_rect_y_pos + HEIGHT))
            begin
                // o_red   <= 3'b111;
                // o_green <= 3'b111;
                // o_blue  <= 3'b111;
                o_red[0]    <= 1'b0;    
                o_red[2:1]  <= w_read_data[7:6];
                o_green     <= w_read_data[5:3];
                o_blue      <= w_read_data[2:0];
                r_read_addr <= r_read_addr + 1;
            end
            // If outside the rectangle, black
            else begin
                // Reset the index into Image Memeory when My Y > Display Y
                if(i_rect_y_pos > i_display_y_pos)
                    r_read_addr <= 0;
                o_red   <= 0;
                o_green <= 0;
                o_blue  <= 0;
            end
        end
    end


    // Add 1 clk of delay to H,VSync to match RGB 
    always @(posedge i_CLK) begin 
        o_hSync <= i_hSync;
        o_vSync <= i_vSync;
    end

endmodule