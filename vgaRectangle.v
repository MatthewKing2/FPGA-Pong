
//------------------------------------------------------------------------------
// Module: vgaRectangle
// Description: Generates a VGA signal to draw a white rectangle on the screen
//              at specified input coordinates. The rectangle is drawn by comparing
//              the coordinates of the current pixle being drawn on the display 
//              and the coordinates to the rectangle's position and dimensions. 
//              The module also handles the synchronization signals to ensure proper
//              VGA display timing.
// Parameters:
//  - HEIGHT: Height of the rectangle
//  - WIDTH: Width of the rectangle
// Inputs:
//  - i_CLK: System clock
//  - i_hSync: Horizontal sync signal from the VGA controller
//  - i_vSync: Vertical sync signal from the VGA controller
//  - i_display_x_pos: Current X position of the pixel being displayed
//  - i_display_y_pos: Current Y position of the pixel being displayed
//  - i_rect_x_pos: X position of the top-left corner of the rectangle
//  - i_rect_y_pos: Y position of the top-left corner of the rectangle
// Outputs:
//  - o_red: 3 bit Red color component for VGA output
//  - o_green: 3 bit Green color component for VGA output
//  - o_blue: 3 bit Blue color component for VGA output
//  - o_hSync: Horizontal sync output signal
//  - o_vSync: Vertical sync output signal
//------------------------------------------------------------------------------

module vgaRectangle #(
    parameter           HEIGHT  = 100,
    parameter           WIDTH   = 15)(
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
    // Main Logic: Rectangle Drawing
    // Description: Determines the color of each pixel based on its position relative
    //              to the rectangle's position and dimensions. If the pixel is within
    //              the bounds of the rectangle, it is set to white; otherwise, it is
    //              set to black. The logic also ensures that pixels outside the display
    //              area are set to black.
    //------------------------------------------------------------------------------
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
            if((i_rect_x_pos < i_display_x_pos) && (i_display_x_pos < i_rect_x_pos + WIDTH) 
            && (i_rect_y_pos < i_display_y_pos) && (i_display_y_pos < i_rect_y_pos + HEIGHT))
            begin
                o_red   <= 3'b111;
                o_green <= 3'b111;
                o_blue  <= 3'b111;
            end
            // If outside the rectangle, black
            else begin
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