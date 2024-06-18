
// This module is designed for 640x480 vga monitor with a 25 MHz input clock

module vgaSyncPorches (
    input   wire        i_CLK,
    output  reg         o_HSync,
    output  reg         o_VSync,
    output  reg [9:0]   o_x_pos,
    output  reg [9:0]   o_y_pos);

    // Basic Monitor Dimentions
    parameter TOTAL_COLS = 800;
    parameter TOTAL_ROWS = 525;
    parameter ACTIVE_COLS = 640;
    parameter ACTIVE_ROWS = 480;
    // Front and Back Porch
    parameter c_FRONT_PORCH_HORZ = 18;
    parameter c_BACK_PORCH_HORZ  = 50;
    parameter c_FRONT_PORCH_VERT = 10;
    parameter c_BACK_PORCH_VERT  = 33;

    // X and Y pos on screen
    reg [9:0] r_x_pos;
    reg [9:0] r_y_pos;

    // Generates the X and Y position 
    always @(posedge i_CLK) begin
            if(r_x_pos < 800)
                  r_x_pos <= r_x_pos + 1;
            else begin
                r_x_pos <= 0; 
                if(r_y_pos < 525)
                    r_y_pos <= r_y_pos + 1;
                else
                    r_y_pos <= 0;
            end
    end

    //Create HSync and VSync signals 
    always @(posedge i_CLK)
    begin
        if ((r_x_pos < c_FRONT_PORCH_HORZ + ACTIVE_COLS) || (r_x_pos > TOTAL_COLS - c_BACK_PORCH_HORZ - 1))
            o_HSync <= 1'b1;  
        else
            o_HSync <= 0;
        
        if ((r_y_pos < c_FRONT_PORCH_VERT + ACTIVE_ROWS) || (r_y_pos > TOTAL_ROWS - c_BACK_PORCH_VERT - 1))
            o_VSync <= 1'b1;  
        else
            o_VSync <= 0;
    end

    // Adds 1 clk cycle delay to (outputed) X,Y to keep in sync with H,VSync 
    always @(posedge i_CLK)
    begin
        o_x_pos <= r_x_pos;
        o_y_pos <= r_y_pos;
    end
    
endmodule
