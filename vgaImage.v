
//------------------------------------------------------------------------------
// Module: vgaImage
// Description: Draws an image on the VGA display using Block RAM to store the image
//              data. The module reads pixel data from the Block RAM and outputs the
//              corresponding RGB color values based on the current display position.
//              The image is displayed at the specified input position with a given
//              width and height. The module also handles the synchronization singals
//              to ensure proper display timing.
// Parameters:
//  - HEIGHT: Height of the rectangle
//  - WIDTH: Width of the rectangle
// Inputs:
//  - i_CLK: System clock
//  - i_hSync: Horizontal sync signal from the VGA controller
//  - i_vSync: Vertical sync signal from the VGA controller
//  - i_display_x_pos: Current X position of the pixel being displayed
//  - i_display_y_pos: Current Y position of the pixel being displayed
//  - i_rect_x_pos: X position of the top-left corner of the image to be displayed
//  - i_rect_y_pos: Y position of the top-left corner of the image to be displayed
// Outputs:
//  - o_red: 3 bit Red color component for VGA output
//  - o_green: 3 bit Green color component for VGA output
//  - o_blue: 3 bit Blue color component for VGA output
//  - o_hSync: Horizontal sync output signal
//  - o_vSync: Vertical sync output signal
//------------------------------------------------------------------------------

module vgaImage #(
    parameter           HEIGHT  = 40,
    parameter           WIDTH   = 40)(
    input   wire        i_CLK,
    input   wire        i_hSync,
    input   wire        i_vSync,
    input   wire [9:0]  i_display_x_pos,
    input   wire [9:0]  i_display_y_pos,
    input   wire [9:0]  i_rect_y_pos,
    input   wire [9:0]  i_rect_x_pos,
    output  reg  [2:0]  o_red,       
    output  reg  [2:0]  o_green,     
    output  reg  [2:0]  o_blue,      
    output  reg         o_hSync,   
    output  reg         o_vSync);  

    //------------------------------------------------------------------------------
    // Parameters and Local Registers
    // Description: Defines parameters and registers used for image rendering.
    //              - `BusSize`: Number of bits for the address bus of the Block RAM.
    //              - `NumElements`: Total number of elements in the Block RAM.
    //              - `DataSize`: Number of bits per element in the Block RAM (i.e., color depth).
    //              - `r_read_en`: Register to enable read operations from the Block RAM.
    //              - `r_read_addr`: Register to hold the current address for reading data from the Block RAM.
    //              - `w_read_data`: Wire to carry the read data from the Block RAM.
    //------------------------------------------------------------------------------
    parameter       BusSize     = 11;
    parameter       NumElements = 1600;
    parameter       DataSize    = 8;
    reg                     r_read_en = 1'b1;
    reg  [BusSize-1: 0]     r_read_addr = 0; 
    wire [DataSize-1: 0]    w_read_data;

    //------------------------------------------------------------------------------
    // Block RAM Initialization
    // Description: Instantiates a Block RAM to store the image data. The image is read from
    //              an external file ("skyFace.txt") which contains pixel color data.
    //              The Block RAM is configured to have a specific address bus size, number
    //              of elements, and element size based on the image data format.
    //------------------------------------------------------------------------------
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

    //------------------------------------------------------------------------------
    // Main Logic: Image Drawing
    // Description: Determines the color of each pixel based on its position relative to
    //              the image's position and dimensions. If the pixel is within the bounds
    //              of the image, the color is read from the Block RAM and output to the VGA
    //              signals. The read address is incremented to read the next pixel. If the
    //              pixel is outside the image bounds or if the image is outside the display
    //              area, the output color is set to black. The Block RAM read address is 
    //              reset after the image has been fully displayed (the image's Y position 
    //              is greater than the display's Y position).
    //------------------------------------------------------------------------------
    always @( posedge i_CLK ) begin
        // Draw black outside of screen 
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
                // VGA color is 9 bit, but there is only 8 bit color stored in Block RAM
                // The LSB of the 3 bit Red color value is always 0
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

    //------------------------------------------------------------------------------
    // Synchronization Signal Handling
    // Description: Delays the horizontal and vertical sync signals by one clock cycle
    //              to match the RGB output. This ensures proper timing and synchronization
    //              of the VGA display signals with the pixel color outputs.
    //------------------------------------------------------------------------------
    always @(posedge i_CLK) begin 
        o_hSync <= i_hSync;
        o_vSync <= i_vSync;
    end

endmodule