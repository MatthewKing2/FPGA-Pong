
// Module draws white rectangle at X,Y with H,W 

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

    // Local Variables / Parameters
    parameter X_LOCATION        = (640-DOT_WIDTH)/2; // Top left X cord
    reg       r_draw            = 0;    // 1 = Draw, 0 = Black
    reg [4:0] r_count_gap       = 0;    // Max = 32
    reg [4:0] r_count_height    = 0;    // Max = 32
    reg [9:0] r_prev_y_pos      = 0;    // Save the old Display Y to see when it changes

    // When Y pixle changes update Gap and Height counter & determine if Y in range to draw
    always @( posedge i_CLK ) begin
        if((r_prev_y_pos != i_display_y_pos) && (i_display_y_pos <= (480-DOT_GAP))) begin 
            r_prev_y_pos <= i_display_y_pos;
            // If at 
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

    // Main Logic 
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

    // Add 1 clk of delay to H,VSync to match RGB 
    always @(posedge i_CLK) begin 
        o_hSync <= i_hSync;
        o_vSync <= i_vSync;
    end

endmodule