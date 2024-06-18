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

  // Init wires to connect modules to pins
  wire [2:0] w_red;
  wire [2:0] w_green;
  wire [2:0] w_blue;


  vgaSyncPorches singals(
    .i_CLK  (CLK),
    .o_HSync(w_hSync),
    .o_VSync(w_vSync),
    .o_x_pos(w_x_pos),
    .o_y_pos(w_y_pos),
);

  // vgaPattern patterns(
  //   .i_CLK  (CLK),
  //   .i_hSync(w_hSync),
  //   .i_vSync(w_vSync),
  //   .i_x_pos(w_x_pos),
  //   .i_y_pos(w_y_pos),
  //   .o_red  (w_red), 
  //   .o_green(w_green),
  //   .o_blue (w_blue),
  //   .o_hSync(VGA_HS),
  //   .o_vSync(VGA_VS),
  // );

  reg [9:0] r_rect_x = 10;
  reg [9:0] r_rect_y = 100;

  vgaRectangle paddleOne(
    .i_CLK(CLK),
    .i_hSync(w_hSync),
    .i_vSync(w_vSync),
    .i_display_x_pos(w_x_pos),
    .i_display_y_pos(w_y_pos),
    .i_rect_x_pos(r_rect_x),
    .i_rect_y_pos(r_rect_y),
    .o_red(w_red),       
    .o_green(w_green),     
    .o_blue(w_blue),      
    .o_hSync(VGA_HS),   
    .o_vSync(VGA_VS),
  );

  // Assign Wires to pins
  assign VGA_R0 = w_red[0];
  assign VGA_R1 = w_red[1];
  assign VGA_R2 = w_red[2];
  assign VGA_G0 = w_green[0];
  assign VGA_G1 = w_green[1];
  assign VGA_G2 = w_green[2];
  assign VGA_B0 = w_blue[0];
  assign VGA_B1 = w_blue[1];
  assign VGA_B2 = w_blue[2];

endmodule 