
// Module Acts as a ball in Pong 

module ballBehavior #(
    parameter           START           = 103,  // g key
    parameter           RESTART         = 98,   // b key
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
    output  wire [9:0]  o_ball_x,       // Top left X
    output  wire [9:0]  o_ball_y,       // Top left Y
    output  reg         o_p1_scored,
    output  reg         o_p2_scored);  

    // Must keep track of previous location (ensure dont go out of range)
    parameter buffer = 10;                  // Defines buffer around edge of screen
    parameter upperBound = 0+buffer;
    parameter lowerBound = 480-buffer;
    parameter rightBound = 640-buffer;
    parameter leftBound  = 0+buffer;
    parameter ballStartX = (640/2) - (BALL_WIDTH/2);
    parameter ballStartY = (480/2) - (BALL_HEIGHT/2);
    reg [9:0] r_x_pos = ballStartX;
    reg [9:0] r_y_pos = ballStartY; 
    reg       r_deltaX_sign = 0;            // 0 = Right,   1 = Left
    reg       r_deltaY_sign = 0;            // 0 = Up,      1 = Down
    reg [4:0] r_ballSpeed   = START_SPEED;  // Max = 32
    reg [4:0] r_number_hits = 0;            // Number of hits dictates ball speed

    // Ensure Have to avoid underflow when paddle is at top of screen
    wire [9:0] w_p1_top_collsion;
    wire [9:0] w_p2_top_collsion;
    assign w_p1_top_collsion = (i_p1_y_pos<BALL_HEIGHT) ? 0 : i_p1_y_pos - BALL_HEIGHT;
    assign w_p2_top_collsion = (i_p2_y_pos<BALL_HEIGHT) ? 0 : i_p2_y_pos - BALL_HEIGHT;

    // Set up FSM
    parameter FSM_IDLE          = 3'b000;
    parameter FSM_START         = 3'b001;
    parameter FSM_MOVE          = 3'b010;
    parameter FSM_P1_SCORED     = 3'b011;
    parameter FSM_P2_SCORED     = 3'b100;
    parameter FSM_HIT_PADDLE    = 3'b101;
    parameter FSM_HIT_TOPBOT    = 3'b110;
    parameter FSM_UP_SPEED      = 3'b111;
    reg [2:0] r_CurrentState = FSM_IDLE;

    // Main Logic 
    always @(posedge i_CLK) begin
        case(r_CurrentState)
            // ########################################
            // Wait for G key to be pressed
            FSM_IDLE: begin
                if(i_key_byte == START)
                    r_CurrentState <= FSM_START;
                else
                    r_CurrentState <= FSM_IDLE;
                r_x_pos <= ballStartX;
                r_y_pos <= ballStartY;
                r_ballSpeed <= START_SPEED;
            end
            // ########################################
            // Move the ball back to start position 
            FSM_START: begin
                if(i_key_byte == RESTART)
                    r_CurrentState <= FSM_IDLE;
                else
                    r_CurrentState <= FSM_MOVE;
                r_x_pos <= ballStartX;
                r_y_pos <= ballStartY;
                r_ballSpeed <= START_SPEED;
            end
            // ########################################
            // Move Unless: P1 Score, P2 Score, Paddle Collide, Top/Bot Collide
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
            // ########################################
            // Updates P1's score, and starts next round
            FSM_P1_SCORED: begin
                // Handle Manual Game Reset
                if(i_key_byte == RESTART)
                    r_CurrentState <= FSM_IDLE;
                else 
                    r_CurrentState <= FSM_START;
                o_p1_scored <= 1;
            end
            // ########################################
            // Updates P2's score, and starts next round
            FSM_P2_SCORED: begin
                // Handle Manual Game Reset
                if(i_key_byte == RESTART)
                    r_CurrentState <= FSM_IDLE;
                else 
                    r_CurrentState <= FSM_START;
                o_p2_scored <= 1;
            end
            // ########################################
            // Handles special movment needed when ball hits paddle 
            FSM_HIT_PADDLE: begin
                // Handle Manual Game Reset
                if(i_key_byte == RESTART)
                    r_CurrentState <= FSM_IDLE;
                else 
                    r_CurrentState <= FSM_MOVE;
                
                // Flip X momentum, inc num hits
                r_deltaX_sign <= ~r_deltaX_sign;
                r_number_hits <= r_number_hits + 1;

                // Depending on X sign, move left or right
                if(r_deltaX_sign)
                    r_x_pos <= r_x_pos + r_ballSpeed; 
                else
                    r_x_pos <= r_x_pos - r_ballSpeed; 

                // Move normally in Y
                if(r_deltaY_sign)
                    r_y_pos <= r_y_pos + r_ballSpeed;
                else
                    r_y_pos <= r_y_pos - r_ballSpeed;
            end
            // ########################################
            // Handles special movment needed when ball hits paddle 
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
            // ########################################
            // Currently not in use
            FSM_UP_SPEED: begin
                // Handle Manual Game Reset
                if(i_key_byte == RESTART)
                    r_CurrentState <= FSM_IDLE;
                else 
                    r_CurrentState <= FSM_MOVE;

                // Increase ball speed based on number of hits
                if(r_number_hits == 5 || r_number_hits == 15)  
                    r_ballSpeed <= r_ballSpeed + 5;
            end

        endcase
    end

    assign o_ball_y = r_y_pos;
    assign o_ball_x = r_x_pos;

endmodule