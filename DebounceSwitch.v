
// This is similar to a function in C
    // 1) We have some parameters
    // 2) We have some local variables
    // 3) We have some sort of for loop thing 

// We intake the current swtich value, and once that value =/= the 
// previous value (which we save) 250,000 times, we output the current
// switch value. In this way we filter out any changes less than our 
// debounce limit of 250,000 clk cyles (10ms). B/c this is acting in 
// parallel with everything else, it doesnt matter that it is constatly 
// resetting the count (in c this would hold everything up)

// Truth table 
/*
    in   prev      wait        out 
    0     0        reset        0
    0     1       250,000       0
    1     0        reset        0
    1     1       250,000       1
*/

module DebounceSwitch(
    input i_CLK,
    input i_SW,
    output o_SW,);

    // Add a constant (paramater) which is just a value that gets
    // set once and never changes 
    parameter c_DEBOUNCE_LIMIT = 250000; // 10ms @ 25Mhz

    // Init (local?) parameters
    reg         rState  = 1'b0;
    reg [17:0]  rCount  = 0;        // 18 bits is > 250,000
        // This is might just 18 FFs

    always @(posedge i_CLK)
    begin
        // If value of swtich =/= prev value of switch
        // AND we are below the debounce limit 
        if(i_SW !== rState && rCount < c_DEBOUNCE_LIMIT)
            rCount <= rCount + 1;               // i ++
        // Otherwise, if @ debounce limit, reset and toggle 
        else if (rCount == c_DEBOUNCE_LIMIT)
        begin
            rCount <= 0;
            rState <= i_SW;
        end
        // Otherwise, (current == prev) reset counter to 0
        else
            rCount <= 0;    // i = 0;
    end

    // Make wire between o_SW and FF for rState
    assign o_SW = rState; 

endmodule