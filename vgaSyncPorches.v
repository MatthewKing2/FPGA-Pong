
//------------------------------------------------------------------------------
// Module: vgaSyncPorches
// Description: Generates VGA synchronization signals (HSync and VSync) and 
//              pixel positions (o_x_pos and o_y_pos) for a 640x480 VGA monitor
//              using a 25 MHz input clock. The module calculates the horizontal 
//              and vertical synchronization signals based on standard VGA timing 
//              parameters, including front and back porch periods. The output 
//              signals are synchronized with the pixel positions to ensure correct 
//              image display on the monitor.
//
// Parameters:
//  - TOTAL_COLS: Total number of horizontal pixels per line (including front 
//                and back porches) for the VGA display.
//  - TOTAL_ROWS: Total number of vertical lines per frame (including front 
//                and back porches) for the VGA display.
//  - ACTIVE_COLS: Number of horizontal active pixels (visible area) per line.
//  - ACTIVE_ROWS: Number of vertical active lines (visible area) per frame.
//  - c_FRONT_PORCH_HORZ: Number of horizontal front porch pixels.
//  - c_BACK_PORCH_HORZ: Number of horizontal back porch pixels.
//  - c_FRONT_PORCH_VERT: Number of vertical front porch lines.
//  - c_BACK_PORCH_VERT: Number of vertical back porch lines.
//
// Inputs:
//  - i_CLK: 25 MHz clock signal used for timing and synchronization.
//
// Outputs:
//  - o_HSync: Horizontal synchronization signal.
//  - o_VSync: Vertical synchronization signal.
//  - o_x_pos: Current horizontal pixel position.
//  - o_y_pos: Current vertical line position.
//------------------------------------------------------------------------------

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

    //------------------------------------------------------------------------------
    // X and Y Position Registers
    // Description: Registers to hold the current pixel position (r_x_pos and r_y_pos) 
    //              on the screen. X position is horizontal pixle number, and Y position 
    //              is vertical line number.
    //------------------------------------------------------------------------------
    reg [9:0] r_x_pos;
    reg [9:0] r_y_pos;

    //------------------------------------------------------------------------------
    // Monitor Dimensions and Parameters
    // Description: Defines the dimensions and synchronization parameters of the VGA 
    //              monitor. These parameters are used to generate the HSync and VSync 
    //              signals and to calculate the active display area versus the total 
    //              display area.
    //------------------------------------------------------------------------------
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

    //------------------------------------------------------------------------------
    // HSync and VSync Signal Generation
    // Description: Generates the horizontal and vertical synchronization signals (o_HSync 
    //              and o_VSync). The HSync signal is asserted during the horizontal 
    //              synchronization period and deasserted during the active display area. 
    //              Similarly, the VSync signal is asserted during the vertical 
    //              synchronization period and deasserted during the active display area.
    //------------------------------------------------------------------------------
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

    //------------------------------------------------------------------------------
    // X and Y Position Output Synchronization
    // Description: Outputs the current x and y positions (o_x_pos and o_y_pos) with a 
    //              1 clock cycle delay to synchronize with the HSync and VSync signals. 
    //              This ensures that the pixel positions align correctly with the 
    //              synchronization signals for accurate image display.
    //------------------------------------------------------------------------------
    always @(posedge i_CLK)
    begin
        o_x_pos <= r_x_pos;
        o_y_pos <= r_y_pos;
    end
    
endmodule
