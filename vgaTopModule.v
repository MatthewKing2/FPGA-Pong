//------------------------------------------------------------------
//-- VGA Pattern Tester 
//------------------------------------------------------------------
// Info: Device utilisation:
// Info:            ICESTORM_LC:   719/ 1280    56%
// Info:           ICESTORM_RAM:     0/   16     0%
// Info:                  SB_IO:    16/  112    14%
// Info:                  SB_GB:     5/    8    62%
// Info:           ICESTORM_PLL:     0/    1     0%
// Info:            SB_WARMBOOT:     0/    1     0%

module vgaTopMod (
  input  CLK, // clock (pcf)
  input  RX,
  output VGA_HS,
  output VGA_VS,
  output LED1,
  output LED2,
  output LED3,
  output LED4,
  output VGA_R0,
  output VGA_R1,
  output VGA_R2,
  output VGA_G0,
  output VGA_G1,
  output VGA_G2,
  output VGA_B0,
  output VGA_B1,
  output VGA_B2);

  // Init wires to connect modules to modules
  wire [9:0] w_x_pos;
  wire [9:0] w_y_pos;
  wire w_hSync;
  wire w_vSync;
  wire [7:0] w_key_press;
  wire w_slow_clk;
  wire [9:0] w_p1_y;
  wire [9:0] w_p2_y;

  // Init wires to connect modules to pins
  wire [2:0] w1_red;
  wire [2:0] w1_green;
  wire [2:0] w1_blue;
  wire [2:0] w2_red;
  wire [2:0] w2_green;
  wire [2:0] w2_blue;

  // Set Up stuff 
  // ##################################################
  vgaSyncPorches singals(
    .i_CLK  (CLK),
    .o_HSync(w_hSync),
    .o_VSync(w_vSync),
    .o_x_pos(w_x_pos),
    .o_y_pos(w_y_pos),
  );

  UartReceive uart(
      .i_CLK(CLK),
      .i_Rx_Series(RX),
      .o_DataValid(),
      .o_Rx_Byte(w_key_press),
  );

  slowCLK #(.period(833333)) 
    gameEngine (
    .i_CLK(CLK),
    .o_CLK(w_slow_clk),
  );

  // ##################################################


  // Paddle #1
  // ##################################################
  paddleBehavior # (.UP(119), .DOWN(115), .SPEED(7)) 
    paddleOneBehavior (
    .i_CLK(w_slow_clk),
    .i_key_byte(w_key_press),
    .o_y_pos(w_p1_y),
  );

  vgaRectangle #(.X_POS(10)) 
    paddleOneDisplay(
    .i_CLK(CLK),
    .i_hSync(w_hSync),
    .i_vSync(w_vSync),
    .i_display_x_pos(w_x_pos),
    .i_display_y_pos(w_y_pos),
    .i_rect_y_pos(w_p1_y),
    .o_red(w1_red),       
    .o_green(w1_green),     
    .o_blue(w1_blue),      
    .o_hSync(VGA_HS),   
    .o_vSync(VGA_VS),
  );
  // ##################################################


  // Paddle #2
  // ##################################################
  paddleBehavior # (.UP(105), .DOWN(107), .SPEED(7)) 
    paddleTwoBehavior (
    .i_CLK(w_slow_clk),
    .i_key_byte(w_key_press),
    .o_y_pos(w_p2_y),
  );

  vgaRectangle #(.X_POS(615)) 
    paddleTwoDisplay(
    .i_CLK(CLK),
    .i_hSync(w_hSync),
    .i_vSync(w_vSync),
    .i_display_x_pos(w_x_pos),
    .i_display_y_pos(w_y_pos),
    .i_rect_y_pos(w_p2_y),
    .o_red(w2_red),       
    .o_green(w2_green),     
    .o_blue(w2_blue),      
    .o_hSync(),   
    .o_vSync(),
  );
  // ##################################################


  // Assign Wires to pins
  assign LED1   = w_key_press[3];
  assign LED2   = w_key_press[2];
  assign LED3   = w_key_press[1];
  assign LED4   = w_key_press[0];
  assign VGA_R0 = w2_red[0]   || w1_red[0];
  assign VGA_R1 = w2_red[1]   || w1_red[1];
  assign VGA_R2 = w2_red[2]   || w1_red[2];
  assign VGA_G0 = w2_green[0] || w1_green[0];
  assign VGA_G1 = w2_green[1] || w1_green[1];
  assign VGA_G2 = w2_green[2] || w1_green[2];
  assign VGA_B0 = w2_blue[0]  || w1_blue[0];
  assign VGA_B1 = w2_blue[1]  || w1_blue[1];
  assign VGA_B2 = w2_blue[2]  || w1_blue[2];

endmodule 