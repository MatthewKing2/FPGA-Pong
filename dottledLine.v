
//------------------------------------------------------------------------------
// Module: vagDottedLine
// Description: Draws a dotted vertical line on the VGA display. The line consists of
//              alternating dots and gaps, with configurable dot height, width, and gap.
//              The line is drawn at a the middle of the VGA display and spans the
//              vertical height of the screen, with dots spaced according to the
//              DOT_GAP parameter. The module handles synchronization signals to match
//              the RGB output timing.
// Parameters:
//  - DOT_HEIGHT: Height of each dot in pixels
//  - DOT_WIDTH: Width of each dot in pixels
//  - DOT_GAP: Vertical gap between consecutive dots in pixels
// Inputs:
//  - i_CLK: System clock
//  - i_hSync: Horizontal sync signal from the VGA controller
//  - i_vSync: Vertical sync signal from the VGA controller
//  - i_display_x_pos: Current X position of the pixel being displayed
//  - i_display_y_pos: Current Y position of the pixel being displayed
// Outputs:
//  - o_red: 3 bit Red color component for VGA output
//  - o_green: 3 bit Green color component for VGA output
//  - o_blue: 3 bit Blue color component for VGA output
//  - o_hSync: Horizontal sync output signal
//  - o_vSync: Vertical sync output signal
//------------------------------------------------------------------------------

module vagDottledLine #(
    parameter           DOT_HEIGHT  = 5,
    parameter           DOT_WIDTH   = 2,
    parameter           DOT_GAP     = 5)(
    input   wire        i_CLK,
    input   wire        i_hSync,
    input   wire        i_vSync,
    input   wire [9:0]  i_display_x_pos,
    input   wire [9:0]  i_display_y_pos,
    output  reg  [2:0]  o_red,       
    output  reg  [2:0]  o_green,     
    output  reg  [2:0]  o_blue,      
    output  reg         o_hSync,   
    output  reg         o_vSync);  

    //------------------------------------------------------------------------------
    // Local Variables / Parameters
    // Description: Defines internal variables and parameters used for generating the
    //              dotted line pattern.
    //  - X_LOCATION: X coordinate for the vertical line (centered horizontally on the screen)
    //  - r_draw: Register to determine if the current pixel should be drawn (dot, = 1) or not (gap, = 0)
    //  - r_count_gap: Counter to track the vertical gap between dots
    //  - r_count_height: Counter to track the height of the current dot
    //  - r_prev_y_pos: Register to store the previous Y position to detect changes in display Y
    //------------------------------------------------------------------------------
    parameter X_LOCATION        = (640-DOT_WIDTH)/2; 
    reg       r_draw            = 0;
    reg [4:0] r_count_gap       = 0;
    reg [4:0] r_count_height    = 0;
    reg [9:0] r_prev_y_pos      = 0;

    //------------------------------------------------------------------------------
    // Y Pixel Change Handling
    // Description: Updates the counters and drawing flag when the Y pixel position changes.
    //              - If the vertical position has changed and is within the screen bounds,
    //                the counters for gap and dot height are updated to determine if a dot
    //                should be drawn. If the gap count equals DOT_GAP, a new dot is started.
    //                If the dot height count equals DOT_HEIGHT, the gap count is reset.
    //              - If the vertical position exceeds the bottom of the screen, reset counters
    //                and stop drawing.
    //------------------------------------------------------------------------------
    always @( posedge i_CLK ) begin
        if((r_prev_y_pos != i_display_y_pos) && (i_display_y_pos <= (480-DOT_GAP))) begin 
            r_prev_y_pos <= i_display_y_pos;
            if(r_count_gap == DOT_GAP) begin 
                r_count_height <= 0;
                r_draw <= 1;
            end
            if(r_count_height == DOT_HEIGHT) begin
                r_count_gap <= 0;
                r_draw <= 0;
            end
            if(r_draw == 1) 
                r_count_height <= r_count_height + 1;
            else 
                r_count_gap <= r_count_gap + 1;
        end
        // Reset when at the bottom of screen
        else if(i_display_y_pos > (480-DOT_GAP)) begin
            r_draw <= 0;    // cut off any dots 
            r_count_gap <= 0;
            r_count_height <= 0;
        end
    end

    //------------------------------------------------------------------------------
    // Main Logic: Drawing
    // Description: Determines the color of each pixel based on its position and the
    //              current drawing state. The pixel is drawn as white if it is within
    //              a dot and the horizontal position is within the bounds of the dot width.
    //              Otherwise, the pixel is drawn as black. The RGB output is updated
    //              accordingly based on the drawing state.
    //------------------------------------------------------------------------------
    always @( posedge i_CLK ) begin
        // Draw black outside of screen 
        if( i_display_x_pos >= 640 || i_display_y_pos >= 480 ) begin
            o_red   <= 0;
            o_green <= 0;
            o_blue  <= 0;
        end
        // Draw Pattern when on screen 
        else begin
            // If inside a dot, draw white 
            if ((r_draw == 1) &&
                (i_display_x_pos >= X_LOCATION) &&
                (i_display_x_pos <= X_LOCATION + DOT_WIDTH))
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