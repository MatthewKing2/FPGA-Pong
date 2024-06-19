
// Module draws white rectangle at X,Y with H,W 

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

    // Add 1 clk of delay to H,VSync to match RGB 
    always @(posedge i_CLK) begin 
        o_hSync <= i_hSync;
        o_vSync <= i_vSync;
    end

endmodule