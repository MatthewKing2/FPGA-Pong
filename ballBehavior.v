
//------------------------------------------------------------------------------
// Module: ballBehavior
// Description: Manages the behavior of the ball in the PONG game. This module
//              handles the ball's movement, collision detection with paddles and
//              screen boundaries, and scoring. It also controls the speed of the
//              ball based on interactions and updates the ball's position accordingly.
// Parameters:
//  - START: ASCII key code to start the game (default: 'g')
//  - RESTART: ASCII key code to reset the game (default: 'b')
//  - START_SPEED: Initial speed of the ball
//  - MAX_SPEED: Maximum speed of the ball
//  - BALL_HEIGHT: Height of the ball
//  - BALL_WIDTH: Width of the ball
//  - P1_X_POS: X position of Player 1's paddle
//  - P2_X_POS: X position of Player 2's paddle
//  - PADDLE_WIDTH: Width of the paddles
//  - PADDLE_HEIGHT: Height of the paddles
// Inputs:
//  - i_CLK: System clock
//  - i_key_byte: ASCII byte from user's keyboard input
//  - i_p1_y_pos: Y position of Player 1's paddle
//  - i_p2_y_pos: Y position of Player 2's paddle
// Outputs:
//  - o_ball_x: X coordinate of the ball's top left corner
//  - o_ball_y: Y coordinate of the ball's top left corner
//  - o_p1_scored: Indicates if Player 1 has scored
//  - o_p2_scored: Indicates if Player 2 has scored
//------------------------------------------------------------------------------

module ballBehavior #(
    parameter           START           = 103,
    parameter           RESTART         = 98, 
    parameter           START_SPEED     = 5,
    parameter           MAX_SPEED       = 15,
    parameter           BALL_HEIGHT     = 20,
    parameter           BALL_WIDTH      = 20,
    parameter           P1_X_POS        = 10,
    parameter           P2_X_POS        = 615,
    parameter           PADDLE_WIDTH    = 15,
    parameter           PADDLE_HEIGHT   = 100)(
    input   wire        i_CLK,
    input   wire [7:0]  i_key_byte,
    input   wire [9:0]  i_p1_y_pos,
    input   wire [9:0]  i_p2_y_pos,
    output  wire [9:0]  o_ball_x,
    output  wire [9:0]  o_ball_y,
    output  reg         o_p1_scored,
    output  reg         o_p2_scored);  

    //------------------------------------------------------------------------------
    // Parameters and Local Wires Initialization
    // Description: Define constants and local parameters used for boundary calculations,
    //              ball's initial position, and collision handling. These parameters 
    //              define the playing area and ball's initial settings.
    //------------------------------------------------------------------------------
    parameter buffer = 10;
    parameter upperBound = 0+buffer;
    parameter lowerBound = 480-buffer;
    parameter rightBound = 640-buffer;
    parameter leftBound  = 0+buffer;
    parameter ballStartX = (640/2) - (BALL_WIDTH/2);
    parameter ballStartY = (480/2) - (BALL_HEIGHT/2);

    //------------------------------------------------------------------------------
    // Local Registers and Wires
    // Description: Define internal registers and wires for tracking the ball's position,
    //              direction, speed, and collision detection. Local parameters also include
    //              temporary variables to avoid underflow and facilitate collision detection.
    //------------------------------------------------------------------------------
    reg [9:0] r_x_pos = ballStartX;
    reg [9:0] r_y_pos = ballStartY; 
    reg       r_deltaX_sign = 0;            // 0 = Right,   1 = Left
    reg       r_deltaY_sign = 0;            // 0 = Up,      1 = Down
    reg [4:0] r_ballSpeed   = START_SPEED;  // Max = 32
    reg [4:0] r_number_hits = 0;            // Number of hits dictates ball speed

    wire [9:0] w_p1_top_collsion;
    wire [9:0] w_p2_top_collsion;
    assign w_p1_top_collsion = (i_p1_y_pos<BALL_HEIGHT) ? 0 : i_p1_y_pos - BALL_HEIGHT;
    assign w_p2_top_collsion = (i_p2_y_pos<BALL_HEIGHT) ? 0 : i_p2_y_pos - BALL_HEIGHT;
    // Why the above is here:
        // When determining if the ball collided with a paddle, "i_p1_y_pos - BALL_HEIGHT"
        // is needed. However, if i_p1_y_pos < BALL_HEIGHT, underflow will occur from the subtraction
        // The bellow wire is used in place of this computation. It avoids underflow by setting to 0


    //------------------------------------------------------------------------------
    // Finite State Machine States
    // Description: Define states for the FSM that controls the ball's behavior and game logic.
    //              The FSM transitions between different states based on game inputs and 
    //              ball interactions. States include waiting for start, moving, handling scoring,
    //              and collisions with paddles or screen boundaries.
    //------------------------------------------------------------------------------
    parameter FSM_IDLE          = 3'b000;   // Wait for go key (g)
    parameter FSM_START         = 3'b001;   // Move ball to starting location
    parameter FSM_MOVE          = 3'b010;   // Move ball and look for collisions or scoring
    parameter FSM_P1_SCORED     = 3'b011;   // Handle P1 scoring
    parameter FSM_P2_SCORED     = 3'b100;   // Handle P2 scoring
    parameter FSM_HIT_PADDLE    = 3'b101;   // Handle ball, paddle collsion
    parameter FSM_HIT_TOPBOT    = 3'b110;   // Handle ball, top or bottom (of screen) collision
    reg [2:0] r_CurrentState = FSM_IDLE;

    // Main Logic 
    always @(posedge i_CLK) begin
        case(r_CurrentState)
            //------------------------------------------------------------------------------
            // FSM State: FSM_IDLE
            // Description: Waits for the start key to be pressed. Resets the ball's position and
            //              initial momentum. Transitions to FSM_START when the start key is detected.
            //------------------------------------------------------------------------------
            FSM_IDLE: begin
                // Handle Manual Game Reset
                if(i_key_byte == START)
                    r_CurrentState <= FSM_START;
                else
                    r_CurrentState <= FSM_IDLE;

                // Reset starting position and momentum (sign)
                r_x_pos <= ballStartX;
                r_y_pos <= ballStartY;
                r_deltaX_sign = 0; 
                r_deltaY_sign = 0; 
            end

            //------------------------------------------------------------------------------
            // FSM State: FSM_START
            // Description: Resets the ball's position and speed to the starting values. Transitions
            //              to FSM_MOVE when the game is ready to begin or returns to FSM_IDLE if the
            //              restart key is pressed.
            //------------------------------------------------------------------------------
            FSM_START: begin
                // Handle Manual Game Reset
                if(i_key_byte == RESTART)
                    r_CurrentState <= FSM_IDLE;
                else
                    r_CurrentState <= FSM_MOVE;

                // Reset key variables to cleanly reset game 
                // Note: x,y sign not included intentially
                r_x_pos <= ballStartX;
                r_y_pos <= ballStartY;
                r_number_hits <= 0; 
                r_ballSpeed <= START_SPEED;
            end

            //------------------------------------------------------------------------------
            // FSM State: FSM_MOVE
            // Description: Moves the ball based on its current direction and speed. Handles ball 
            //              movement, collision detection with paddles and screen boundaries, and 
            //              scoring logic. Transitions to appropriate states based on game conditions.
            //------------------------------------------------------------------------------
            FSM_MOVE: begin
                // Handle Manual Game Reset
                if(i_key_byte == RESTART)
                    r_CurrentState <= FSM_IDLE;

                // P1 Score
                else if(r_x_pos < leftBound)
                    r_CurrentState <= FSM_P1_SCORED;

                // P2 Score
                else if(r_x_pos + BALL_WIDTH > rightBound)
                    r_CurrentState <= FSM_P2_SCORED;
                
                // Paddle Collision
                else if
                    ((   // Left Paddle:
                    (r_x_pos <= P1_X_POS+PADDLE_WIDTH) && 
                    (r_y_pos >= w_p1_top_collsion) && 
                    (r_y_pos <= i_p1_y_pos + PADDLE_HEIGHT)
                    )||( // Right Paddle:
                    (r_x_pos >= P2_X_POS-BALL_WIDTH ) && 
                    (r_y_pos >= w_p2_top_collsion) && 
                    (r_y_pos <= i_p2_y_pos + PADDLE_HEIGHT)
                    ))
                    r_CurrentState <= FSM_HIT_PADDLE;

                // Top / Bottom Collision
                else if((r_y_pos + BALL_HEIGHT >= lowerBound) || (r_y_pos <= upperBound))
                    r_CurrentState <= FSM_HIT_TOPBOT;

                // Move the ball
                else begin
                    r_CurrentState <= FSM_MOVE;
                    if(r_deltaX_sign)
                        r_x_pos <= r_x_pos - r_ballSpeed;
                    else
                        r_x_pos <= r_x_pos + r_ballSpeed;
                    if(r_deltaY_sign)
                        r_y_pos <= r_y_pos + r_ballSpeed;
                    else
                        r_y_pos <= r_y_pos - r_ballSpeed;
                end
            end

            //------------------------------------------------------------------------------
            // FSM State: FSM_P1_SCORED
            // Description: Handles the scenario where Player 1 scores a point. Updates the scoring
            //              indicator for Player 1 and transitions back to FSM_START to reset the game.
            //------------------------------------------------------------------------------
            FSM_P1_SCORED: begin
                // Handle Manual Game Reset
                if(i_key_byte == RESTART)
                    r_CurrentState <= FSM_IDLE;
                else 
                    r_CurrentState <= FSM_START;
                o_p1_scored <= 1;
            end

            //------------------------------------------------------------------------------
            // FSM State: FSM_P2_SCORED
            // Description: Handles the scenario where Player 2 scores a point. Updates the scoring
            //              indicator for Player 2 and transitions back to FSM_START to reset the game.
            //------------------------------------------------------------------------------
            FSM_P2_SCORED: begin
                // Handle Manual Game Reset
                if(i_key_byte == RESTART)
                    r_CurrentState <= FSM_IDLE;
                else 
                    r_CurrentState <= FSM_START;
                o_p2_scored <= 1;
            end

            //------------------------------------------------------------------------------
            // FSM State: FSM_HIT_PADDLE
            // Description: Manages the ball's behavior when it collides with a paddle. Updates
            //              the ball's direction, increases speed based on the number of hits, and
            //              handles the ball's position adjustment after the collision.
            //------------------------------------------------------------------------------
            FSM_HIT_PADDLE: begin
                // Handle Manual Game Reset
                if(i_key_byte == RESTART)
                    r_CurrentState <= FSM_IDLE;
                else 
                    r_CurrentState <= FSM_MOVE;
                
                // Flip X momentum, inc num hits
                r_deltaX_sign <= ~r_deltaX_sign;
                r_number_hits <= r_number_hits + 1;
                
                // Increase ball speed based on number of hits
                if(r_number_hits == 5 || r_number_hits == 10)  
                    r_ballSpeed <= r_ballSpeed + START_SPEED;

                // Depending on X sign, move left or right
                // 2*r_ballSpeed to help ball move further from paddle
                if(r_deltaX_sign)
                    r_x_pos <= r_x_pos + (2*r_ballSpeed); 
                else
                    r_x_pos <= r_x_pos - (2*r_ballSpeed); 

                // Move normally in Y
                if(r_deltaY_sign)
                    r_y_pos <= r_y_pos + r_ballSpeed;
                else
                    r_y_pos <= r_y_pos - r_ballSpeed;
            end

            //------------------------------------------------------------------------------
            // FSM State: FSM_HIT_TOPBOT
            // Description: Manages the ball's behavior when it collides with the top or bottom
            //              boundaries of the screen. Reverses the ball's vertical direction and 
            //              adjusts its position accordingly.
            //------------------------------------------------------------------------------
            FSM_HIT_TOPBOT: begin
                // Handle Manual Game Reset
                if(i_key_byte == RESTART)
                    r_CurrentState <= FSM_IDLE;
                else 
                    r_CurrentState <= FSM_MOVE;

                // Flip Y momentum
                r_deltaY_sign <= ~r_deltaY_sign;

                // Depending on Y sign, move up or down
                if(r_deltaY_sign) 
                    r_y_pos <= r_y_pos - r_ballSpeed;
                else
                    r_y_pos <= r_y_pos + r_ballSpeed; 

                // Move normally in X
                if(r_deltaX_sign)
                    r_x_pos <= r_x_pos - r_ballSpeed;
                else
                    r_x_pos <= r_x_pos + r_ballSpeed;
            end

        endcase
    end

    //------------------------------------------------------------------------------
    // Output Assignments
    // Description: Assign the final ball positions to the output wires so they can be used
    //              by other modules or downstream logic in the design.
    //------------------------------------------------------------------------------
    assign o_ball_y = r_y_pos;
    assign o_ball_x = r_x_pos;

endmodule