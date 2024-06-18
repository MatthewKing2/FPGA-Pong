
// Slow clk signal @ period perameter (in clk cycles)

module slowCLK #( 
    parameter period = 2500000)
    (
    input   wire    i_CLK,
    output  reg     o_CLK,);

    // This is the size of the pwd period, needs to be 100
    // b/c brightness is on the scale of 0->100
    // parameter period = 250000; // 1 sec @ 25MHz

    // Init local register to keep track of count 
    reg [0:25] rCount = 25'b0;

    // Depending on how far into the pwm period we are, either
    // output 1 or 0 to the LED
    always @(posedge i_CLK) begin
        if(rCount < period/2) 
            o_CLK <= 1;
        else
            o_CLK <= 0;
    end

    // When we reach the end of the pwm period, reset to the 
    // begining of the period
    always @(posedge i_CLK) begin
        if(rCount >= period) 
            rCount <= 0;
        else
            rCount <= rCount + 1;
    end

endmodule