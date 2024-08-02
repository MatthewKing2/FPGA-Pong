
//------------------------------------------------------------------------------
// Module: paddleBehavior
// Description: Controls the behavior of a paddle in the PONG game. This module
//              handles paddle movement based on user input and ensures the paddle 
//              stays within the screen boundaries. It updates the paddle's vertical
//              position according to the last valid key press for moving up or down.
// Parameters:
//  - UP: Key code for moving the paddle up (default: 'w')
//  - DOWN: Key code for moving the paddle down (default: 's')
//  - SPEED: Movement speed of the paddle
//  - HEIGHT: Height of the paddle
//  - START_Y: Initial vertical position of the paddle (centered)
// Inputs:
//  - i_CLK: System clock
//  - i_key_byte: ASCII byte from user's keyboard input
// Outputs:
//  - o_y_pos: Vertical position of the paddle
//------------------------------------------------------------------------------

module paddleBehavior #(
    parameter           UP      = 119,
    parameter           DOWN    = 115,
    parameter           SPEED   = 5,
    parameter           HEIGHT  = 100,
    parameter           START_Y = (480 - HEIGHT)/2)(
    input   wire        i_CLK,
    input   wire [7:0]  i_key_byte,
    output  wire [9:0]  o_y_pos);  

    //------------------------------------------------------------------------------
    // Parameters and Registers Initialization
    // Description: Define parameters for paddle movement boundaries, initial position,
    //              and register to track the previous valid key press. These are used
    //              to control the paddle's vertical position and ensure it does not
    //              move out of the screen bounds.
    //------------------------------------------------------------------------------
    parameter upperBound = 15;
    parameter lowerBound = 480-15;
    reg [9:0] r_prev_y_pos = START_Y;
    reg [7:0] r_prev_valid_key = 0;
    
    //------------------------------------------------------------------------------
    // Paddle Movement Logic
    // Description: Updates the paddle's vertical position based on the key presses for
    //              moving up and down. Ensures the paddle stays within the screen bounds
    //              by checking the position against upper and lower limits. The movement
    //              is only updated if the paddle is within the allowed range.
    //------------------------------------------------------------------------------
    always @( posedge i_CLK ) begin
        if((r_prev_valid_key == UP) && (o_y_pos > upperBound)) begin
            r_prev_y_pos <= r_prev_y_pos - SPEED;
        end
        else if((r_prev_valid_key == DOWN) && ((o_y_pos + HEIGHT) < lowerBound)) begin
            r_prev_y_pos <= r_prev_y_pos + SPEED;
        end
    end

    //------------------------------------------------------------------------------
    // Key Input Handling
    // Description: Checks for valid key presses (UP or DOWN) and stores the last valid
    //              key press to determine the direction of the paddle's movement. This
    //              ensures that only recognized key presses affect the paddle's position.
    //------------------------------------------------------------------------------
    always @( posedge i_CLK ) begin 
        if((i_key_byte == UP) || (i_key_byte == DOWN))
            r_prev_valid_key <= i_key_byte;
    end 

    //------------------------------------------------------------------------------
    // Output Assignment
    // Description: Assigns the current vertical position of the paddle to the output
    //              wire so that it can be used by other modules or downstream logic
    //              in the design.
    //------------------------------------------------------------------------------
    assign o_y_pos = r_prev_y_pos;

endmodule