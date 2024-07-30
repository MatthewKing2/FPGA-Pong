
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
    output  wire [9:0]  o_ball_x,       // Top left X,Y
    output  wire [9:0]  o_ball_y,
    output  reg         o_p1_scored,
    output  reg         o_p2_scored);  

    // Must keep track of previous location (ensure dont go out of range)
    parameter buffer = 10;
    parameter upperBound = 0+buffer;
    parameter lowerBound = 480-buffer;
    parameter rightBound = 640-buffer;
    parameter leftBound  = 0+buffer;
    parameter ballStartX = (640/2) - (BALL_WIDTH/2);
    parameter ballStartY = (480/2) - (BALL_HEIGHT/2);
    reg [9:0] r_x_pos = ballStartX;
    reg [9:0] r_y_pos = ballStartY; 
    reg       r_deltaX_sign = 0;   // 0 = Right, 1 = Left
    reg       r_deltaY_sign = 0;   // 0 = Up, 1 = Down
    reg [1:0] r_gameStart   = 0;
    // reg       r_gameStart   = 0;
    // reg [1:0] r_collieded_Y = 0; 
    // reg [1:0] r_collieded_X = 0; 
    // reg       r_gameReset   = 0;
    reg [4:0] r_ballSpeed   = START_SPEED;  // Max = 32
    reg [4:0] r_number_hits = 0;            // Number of hits dictates ball speed
    // reg       r_speed_updated = 0;          // Flag, 0=F, 1=T

    // Have to avoid underflow when paddle is at top of screen
    wire [9:0] w_p1_top_collsion;
    wire [9:0] w_p2_top_collsion;
    assign w_p1_top_collsion = (i_p1_y_pos<BALL_HEIGHT) ? 0 : i_p1_y_pos - BALL_HEIGHT;
    assign w_p2_top_collsion = (i_p2_y_pos<BALL_HEIGHT) ? 0 : i_p2_y_pos - BALL_HEIGHT;

    // See if a valid key (for the ball) was pressed & store it
    always @( posedge i_CLK ) begin 
        if(i_key_byte == START)
            r_gameStart <= 1;
        else if(i_key_byte == RESTART)
            r_gameStart <= 0;
    end 

    parameter FSM_IDLE          = 4'b0000;
    parameter FSM_START         = 4'b0001;
    parameter FSM_MOVE          = 4'b0010;
    parameter FSM_P1_SCORED     = 4'b0011;
    parameter FSM_P2_SCORED     = 4'b0100;
    parameter FSM_HIT_PADDLE    = 4'b0101;
    parameter FSM_HIT_TOPBOT    = 4'b0110;
    parameter FSM_X_SHOVE       = 4'b0111;
    parameter FSM_Y_SHOVE       = 4'b1000;
    parameter FSM_UP_SPEED      = 4'b1001;

    reg [3:0] r_CurrentState = FSM_START;

    // Main Logic 
    always @(posedge i_CLK) begin
        case(r_CurrentState)
            // ########################################
            // Wait for G key to be pressed
            FSM_IDLE: begin
                if(r_gameStart)
                    r_CurrentState <= FSM_START;
                r_x_pos <= ballStartX;
                r_y_pos <= ballStartY;
                r_ballSpeed <= START_SPEED;
                r_CurrentState <= FSM_IDLE;
            end
            // ########################################
            // Move the ball back to start position 
            FSM_START: begin
                r_x_pos <= ballStartX;
                r_y_pos <= ballStartY;
                r_ballSpeed <= START_SPEED;
                r_CurrentState <= FSM_MOVE;
            end
            // ########################################
            // Check: P1 Score, P2 Score, Paddle Collide, Top/Bot Collide
            // If nothing, move
            FSM_MOVE: begin
                // P1 Score
                if(r_x_pos < leftBound)
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
                    if(r_deltaX_sign == 0)
                        r_x_pos <= r_x_pos + r_ballSpeed;
                    else
                        r_x_pos <= r_x_pos - r_ballSpeed;
                    if(r_deltaY_sign == 1)
                        r_y_pos <= r_y_pos + r_ballSpeed;
                    else
                        r_y_pos <= r_y_pos - r_ballSpeed;
                end
            end
            // ########################################
            FSM_P1_SCORED: begin
                o_p1_scored <= 1;
                r_CurrentState <= FSM_START;
            end
            // ########################################
            FSM_P2_SCORED: begin
                o_p2_scored <= 1;
                r_CurrentState <= FSM_START;
            end
            // ########################################
            FSM_HIT_PADDLE: begin
                r_deltaX_sign <= ~r_deltaX_sign;
                r_number_hits <= r_number_hits + 1;
                r_CurrentState <= FSM_X_SHOVE;
            end
            // ########################################
            FSM_HIT_TOPBOT: begin
                r_deltaY_sign <= ~r_deltaY_sign;
                r_CurrentState <= FSM_Y_SHOVE;
            end
            // ########################################
            // Move the ball so it is no longer in collision with a paddle on the x axis 
            // 1) See where I hit 
            // 2) Move in correct direction
            FSM_X_SHOVE: begin
                if(r_deltaX_sign) begin
                    r_x_pos <= r_x_pos - r_ballSpeed; 
                        // Shouldn't overflow r_ballSpeed b/c it will get resized
                        // to the much bigger r_x_pos before math
                end
                else begin 
                    r_x_pos <= r_x_pos + r_ballSpeed; 
                end
                r_CurrentState <= FSM_MOVE;
            end
            // ########################################
            // Move the ball so it is no longer in collision with a wall on the y axis 
            // reg       r_deltaY_sign = 0;   // 0 = Up, 1 = Down
            FSM_Y_SHOVE: begin
                if(r_deltaY_sign) // if = 1, just hit top, inc y
                    r_y_pos <= r_y_pos + r_ballSpeed;
                else
                    r_y_pos <= r_y_pos - r_ballSpeed; 
                r_CurrentState <= FSM_MOVE;
            end
            // ########################################
            // Currently not in use
            FSM_UP_SPEED: begin
                if(r_number_hits == 5 || r_number_hits == 15)  
                    r_ballSpeed <= r_ballSpeed + 5;
                r_CurrentState <= FSM_MOVE;
            end

        endcase
    end

    assign o_ball_y = r_y_pos;
    assign o_ball_x = r_x_pos;

endmodule