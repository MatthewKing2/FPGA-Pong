
// Module Acts as a paddle in Pong 

module paddleBehavior #(
    parameter           UP      = 119,   // w
    parameter           DOWN    = 115,   // s
    parameter           SPEED   = 5,
    parameter           HEIGHT  = 100,
    parameter           START_Y = 300)(
    input   wire        i_CLK,
    input   wire [7:0]  i_key_byte,
    output  wire [9:0]  o_y_pos);  

    // Must keep track of previous location (ensure dont go out of range)
    parameter upperBound = 15;
    parameter lowerBound = 480-15;
    reg [9:0] r_prev_y_pos = START_Y;
    reg [7:0] r_prev_valid_key = 0;
    
    // If a movment button is pressed and the paddle is not out of 
    // bounds, move it accordingly
    always @( posedge i_CLK ) begin
        if((r_prev_valid_key == UP) && (o_y_pos > upperBound)) begin
            r_prev_y_pos <= r_prev_y_pos - SPEED;
        end
        else if((r_prev_valid_key == DOWN) && ((o_y_pos + HEIGHT) < lowerBound)) begin
            r_prev_y_pos <= r_prev_y_pos + SPEED;
        end
    end

    // See if a valid key (for this player) was pressed & store it
    always @( posedge i_CLK ) begin 
        if((i_key_byte == UP) || (i_key_byte == DOWN))
            r_prev_valid_key <= i_key_byte;
    end 

    assign o_y_pos = r_prev_y_pos;

endmodule