
//------------------------------------------------------------------------------
// Module: vgaTopMod
// Description: This module is the top-level module that integrates various 
//              components to create a Pong inspired video game on a VGA display. 
//              It includes functionality for the movment and rendering of paddles 
//              and a ball. It displays a dotted line down the center, marking the 
//              two player's sides of the display. The module receives input via 
//              UART so players can control the paddles with a keyboard.
//
// Inputs:
//  - CLK:       System clock signal used for timing and synchronization.
//  - RX:        Serial input for receiving UART data.
//
// Outputs:
//  - VGA_HS:    Horizontal sync signal for VGA output.
//  - VGA_VS:    Vertical sync signal for VGA output.
//  - LED1:      LED output signal reflecting the received UART data.
//  - LED2:      LED output signal reflecting the received UART data.
//  - LED3:      LED output signal reflecting the received UART data.
//  - LED4:      LED output signal reflecting the received UART data.
//  - VGA_R0:    VGA red channel bit 0 output.
//  - VGA_R1:    VGA red channel bit 1 output.
//  - VGA_R2:    VGA red channel bit 2 output.
//  - VGA_G0:    VGA green channel bit 0 output.
//  - VGA_G1:    VGA green channel bit 1 output.
//  - VGA_G2:    VGA green channel bit 2 output.
//  - VGA_B0:    VGA blue channel bit 0 output.
//  - VGA_B1:    VGA blue channel bit 1 output.
//  - VGA_B2:    VGA blue channel bit 2 output.
//
// Modules Instantiated:
//  - vgaSyncPorches: Generates VGA sync signals and pixel positions.
//  - UartReceive:    Handles UART reception and converts serial data to parallel data.
//  - slowCLK:        Generates a slower clock signal for controlling game logic.
//  - ballBehavior:   Handles the movement and behavior of the ball.
//  - vgaImage:       Renders the ball as a desired image on the VGA display.
//  - paddleBehavior: Controls the movement of player paddles based on input.
//  - vgaRectangle:   Renders paddles on the VGA display.
//  - vagDottledLine: Renders a dotted line in the middle of the screen.
//
// Notes:
//  - The module handles both VGA output and UART input. The paddle positions 
//    are updated based on UART input, and the VGA signals are generated to 
//    display the game elements. The LEDs reflect the state of the received 
//    UART data bits.
//------------------------------------------------------------------------------

module vgaTopMod (
  input  CLK,
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


  //------------------------------------------------------------------------------
  // Internal Wires:
  //  - w_x_pos:     Current X position on the VGA screen.
  //  - w_y_pos:     Current Y position on the VGA screen.
  //  - w_hSync:     Horizontal sync signal from the VGA controller.
  //  - w_vSync:     Vertical sync signal from the VGA controller.
  //  - w_key_press: Captured key presses from the UART receiver.
  //  - w_slow_clk:  Slow clock for controlling game logic speed.
  //  - w_p1_y:      Y position of player 1's paddle.
  //  - w_p2_y:      Y position of player 2's paddle.
  //  - w_ball_x:    X position of the ball.
  //  - w_ball_y:    Y position of the ball.
  //------------------------------------------------------------------------------
  wire [9:0] w_x_pos;
  wire [9:0] w_y_pos;
  wire w_hSync;
  wire w_vSync;
  wire [7:0] w_key_press;
  wire w_slow_clk;
  wire [9:0] w_p1_y;
  wire [9:0] w_p2_y;
  wire [9:0] w_ball_x;
  wire [9:0] w_ball_y;

  //------------------------------------------------------------------------------
  // Color Wires (from various modules):
  //  - w1_red, w1_green, w1_blue: RGB color outputs for paddle 1.
  //  - w2_red, w2_green, w2_blue: RGB color outputs for paddle 2.
  //  - w3_red, w3_green, w3_blue: RGB color outputs for the ball.
  //  - w4_red, w4_green, w4_blue: RGB color outputs for the dotted line.
  //------------------------------------------------------------------------------
  wire [2:0] w1_red;
  wire [2:0] w1_green;
  wire [2:0] w1_blue;
  wire [2:0] w2_red;
  wire [2:0] w2_green;
  wire [2:0] w2_blue;
  wire [2:0] w3_red;
  wire [2:0] w3_green;
  wire [2:0] w3_blue;
  wire [2:0] w4_red;
  wire [2:0] w4_green;
  wire [2:0] w4_blue;


  //------------------------------------------------------------------------------
  // "Background" Module Instantiation and Setup
  // Description: This section sets up the VGA sync signals, UART receiver, and 
  //              a slow clock at 30Hz for controlling game logic.
  //------------------------------------------------------------------------------
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


  //------------------------------------------------------------------------------
  // Ball Section
  // Description: This section defines the behavior and display of the ball. 
  //              The `ballBehavior` module handles the movement logic, while 
  //              the `vgaImage` module renders the ball on the screen.
  //------------------------------------------------------------------------------
  ballBehavior #(.BALL_HEIGHT(40), .BALL_WIDTH(40), .START_SPEED(5))
    ball(
    .i_CLK(w_slow_clk),
    .i_key_byte(w_key_press),
    .i_p1_y_pos(w_p1_y),
    .i_p2_y_pos(w_p2_y),
    .o_ball_x(w_ball_x),
    .o_ball_y(w_ball_y),
    .o_p1_scored(),
    .o_p2_scored(),
  );  

  vgaImage #(.HEIGHT(40), .WIDTH(40)) 
    ballDisplay(
    .i_CLK(CLK),
    .i_hSync(w_hSync),
    .i_vSync(w_vSync),
    .i_display_x_pos(w_x_pos),
    .i_display_y_pos(w_y_pos),
    .i_rect_x_pos(w_ball_x),
    .i_rect_y_pos(w_ball_y),
    .o_red(w3_red),       
    .o_green(w3_green),     
    .o_blue(w3_blue),      
    .o_hSync(),   
    .o_vSync(),
  );


  //------------------------------------------------------------------------------
  // Paddle #1 Section
  // Description: This section defines the behavior and display of player 1's 
  //              paddle. The `paddleBehavior` module handles the movement logic 
  //              based on key presses, and the `vgaRectangle` module renders 
  //              the paddle on the screen.
  //------------------------------------------------------------------------------
  paddleBehavior # (.UP(119), .DOWN(115), .SPEED(7)) 
    paddleOneBehavior (
    .i_CLK(w_slow_clk),
    .i_key_byte(w_key_press),
    .o_y_pos(w_p1_y),
  );
  
  parameter P1_X_POS = 10;
  vgaRectangle paddleOneDisplay(
    .i_CLK(CLK),
    .i_hSync(w_hSync),
    .i_vSync(w_vSync),
    .i_display_x_pos(w_x_pos),
    .i_display_y_pos(w_y_pos),
    .i_rect_x_pos(P1_X_POS),
    .i_rect_y_pos(w_p1_y),
    .o_red(w1_red),       
    .o_green(w1_green),     
    .o_blue(w1_blue),      
    .o_hSync(VGA_HS),   
    .o_vSync(VGA_VS),
  );


  //------------------------------------------------------------------------------
  // Paddle #2 Section
  // Description: Similar to Paddle #1, this section defines the behavior and 
  //              display of player 2's paddle.
  //------------------------------------------------------------------------------
  paddleBehavior # (.UP(105), .DOWN(107), .SPEED(7)) 
    paddleTwoBehavior (
    .i_CLK(w_slow_clk),
    .i_key_byte(w_key_press),
    .o_y_pos(w_p2_y),
  );

  parameter P2_X_POS = 615;
  vgaRectangle paddleTwoDisplay(
    .i_CLK(CLK),
    .i_hSync(w_hSync),
    .i_vSync(w_vSync),
    .i_display_x_pos(w_x_pos),
    .i_display_y_pos(w_y_pos),
    .i_rect_x_pos(P2_X_POS),
    .i_rect_y_pos(w_p2_y),
    .o_red(w2_red),       
    .o_green(w2_green),     
    .o_blue(w2_blue),      
    .o_hSync(),   
    .o_vSync(),
  );


  //------------------------------------------------------------------------------
  // Dotted Line Section
  // Description: This section renders a dotted line down the center of the 
  //              screen, separating the playing field.
  //------------------------------------------------------------------------------
  vagDottledLine dottledLine(
      .i_CLK(CLK),
      .i_hSync(w_hSync),
      .i_vSync(w_vSync),
      .i_display_x_pos(w_x_pos),
      .i_display_y_pos(w_y_pos),
      .o_red(w4_red),       
      .o_green(w4_green),     
      .o_blue(w4_blue),      
      .o_hSync(),   
      .o_vSync(),
  );  


  //------------------------------------------------------------------------------
  // Output Assignments
  // Description: The final section of the module assigns the wire values 
  //              to the output pins, including VGA signals and LEDs. The RGB 
  //              signals are combined using a logical OR to blend colors from 
  //              multiple objects on the screen.
  //------------------------------------------------------------------------------
  assign LED1   = w_key_press[3];
  assign LED2   = w_key_press[2];
  assign LED3   = w_key_press[1];
  assign LED4   = w_key_press[0];
  assign VGA_R0 = w1_red[0]   || w2_red[0]   || w3_red[0]    || w4_red[0];
  assign VGA_R1 = w1_red[1]   || w2_red[1]   || w3_red[1]    || w4_red[1];
  assign VGA_R2 = w1_red[2]   || w2_red[2]   || w3_red[2]    || w4_red[2];
  assign VGA_G0 = w1_green[0] || w2_green[0] || w3_green[0]  || w4_green[0];
  assign VGA_G1 = w1_green[1] || w2_green[1] || w3_green[1]  || w4_green[1];
  assign VGA_G2 = w1_green[2] || w2_green[2] || w3_green[2]  || w4_green[2];
  assign VGA_B0 = w1_blue[0]  || w2_blue[0]  || w3_blue[0]   || w4_blue[0];
  assign VGA_B1 = w1_blue[1]  || w2_blue[1]  || w3_blue[1]   || w4_blue[1];
  assign VGA_B2 = w1_blue[2]  || w2_blue[2]  || w3_blue[2]   || w4_blue[2];

endmodule 