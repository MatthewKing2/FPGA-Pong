
// Module Acts as a paddle in Pong 

module ballBehavior #(
    parameter           START           = 103,  // g key
    parameter           RESTART         = 98,   // b key
    parameter           SPEED           = 5,
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
    reg [1:0] r_gameStart = 0;
    reg [1:0] r_collieded = 0; 
    reg       r_gameReset = 0;

    // Handle Colliding with Walls and Paddles
    always @( posedge i_CLK ) begin
        if(r_collieded == 0) begin
            // Top and Bottom
            if((r_y_pos + BALL_HEIGHT >= lowerBound) || (r_y_pos <= upperBound)) begin
                r_deltaY_sign <= ~r_deltaY_sign;
                r_collieded <= 1;
            end
            // Left Paddle (Player 1)
            if((r_x_pos <= P1_X_POS+PADDLE_WIDTH) && 
                    (r_y_pos >= i_p1_y_pos + BALL_HEIGHT ) && 
                    (r_y_pos <= i_p1_y_pos + PADDLE_HEIGHT)) begin
                r_deltaX_sign <= ~r_deltaX_sign;
                r_collieded <= 1;
            end
            // Right Paddle (Player 2)
            else if((r_x_pos >= P2_X_POS-BALL_WIDTH ) && 
                    (r_y_pos >= i_p2_y_pos + BALL_HEIGHT ) && 
                    (r_y_pos <= i_p2_y_pos + PADDLE_HEIGHT)) begin
                r_deltaX_sign <= ~r_deltaX_sign;
                r_collieded <= 1;
            end
            // Left Wall
            else if((r_x_pos < leftBound) && r_gameReset == 0) begin
                o_p1_scored <= 1;
                r_gameReset <= 1;
            end
            // Right Wall
            else if((r_x_pos + BALL_WIDTH > rightBound) && r_gameReset == 0) begin
                o_p2_scored <= 1;
                r_gameReset <= 1;
            end
            else begin 
                o_p1_scored <= 0;
                o_p2_scored <= 0;
                r_gameReset <= 0;   // Flags that means move normally
            end
        end
        // Wait 2 cycles after a collision before being able to collid again
        else if(r_collieded == 1)
            r_collieded <= 2;
        else
            r_collieded <= 0;
    end
    
    // Move the ball (handles game reset movment)
    always @( posedge i_CLK ) begin 
        if(r_gameReset == 0) begin
            if(r_deltaX_sign == 0)
                r_x_pos <= r_x_pos + SPEED;
            else
                r_x_pos <= r_x_pos - SPEED;
            if(r_deltaY_sign == 1)
                r_y_pos <= r_y_pos + SPEED;
            else
                r_y_pos <= r_y_pos - SPEED;
        end
        else begin 
            r_x_pos <= ballStartX;
            r_y_pos <= ballStartY;
        end
    end

    // See if a valid key (for the ball) was pressed & store it
    always @( posedge i_CLK ) begin 
        if(i_key_byte == START)
            r_gameStart <= 1;
        else if(i_key_byte == RESTART)
            r_gameStart <= 0;
    end 

    assign o_ball_y = r_y_pos;
    assign o_ball_x = r_x_pos;

endmodule