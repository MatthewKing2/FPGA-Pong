
// Module Takes X,Y cords on display, and generates a pattern 

module vgaPattern(
    input   wire        i_CLK,
    input   wire        i_hSync,
    input   wire        i_vSync,
    input   wire [9:0]  i_x_pos,
    input   wire [9:0]  i_y_pos,
    output  reg  [2:0]  o_red,       
    output  reg  [2:0]  o_green,     
    output  reg  [2:0]  o_blue,      
    output  reg         o_hSync,   
    output  reg         o_vSync);  


    // Make a slow counter to change the size of visible screen
    // ##############################################################
    reg [7:0] imgBuffer = 8'b00000000;
    reg       imgBufferDirection = 0; // 0 = grow, 1 = shrink
    wire w_slow_Clk;

    // Make slow clock
    slowCLK #(
        .period(250000)) 
        slownessOne(
            .i_CLK(i_CLK),
            .o_CLK(w_slow_Clk)
    );

    // On slow clock
    always @( posedge w_slow_Clk) begin 
        // Change direction between grow / shrinking
        if(imgBuffer == 240) begin
            imgBufferDirection <= 1;
        end
        else if(imgBuffer == 5)
            imgBufferDirection <= 0;
        // Update size of visible screen
        if(imgBufferDirection == 0)
            imgBuffer <= imgBuffer + 1;
        else
            imgBuffer <= imgBuffer - 1;
    end
    // ##############################################################



    // Make patern using a changing modules (slow count) and XOR
    // ##############################################################
    reg [9:0] incriment = 0;
    reg [9:0] patt = (i_x_pos ^ i_y_pos) % incriment;

    // Make another slow clock
    slowCLK #(
        .period(250000*240/30))  
        slownessTwo(
            .i_CLK(i_CLK),
            .o_CLK(w_slow_Clk_two)
    );

    // On second slow clock
    always @( posedge w_slow_Clk_two) begin
        // Loop through modules number
        if(incriment == 9)
            incriment <= 0;
        else
            incriment <= incriment + 1; 
    end
    // ##############################################################


    // Main Logic 
    always @( posedge i_CLK ) begin
        // Draw RBG values in valid screen space 
        if(i_x_pos < imgBuffer || i_x_pos >= 640-imgBuffer || i_y_pos < imgBuffer || i_y_pos >= 480-imgBuffer) begin
        //if( i_x_pos >= 640 || i_y_pos >= 480 ) begin
            o_red   <= 0;
            o_green <= 0;
            o_blue  <= 0;
        end
        else begin
            o_green <= !patt[2:0];
        end
    end

    // Add 1 clk of delay to H,VSync to match RGB 
    always @(posedge i_CLK) begin 
        o_hSync <= i_hSync;
        o_vSync <= i_vSync;
    end

endmodule