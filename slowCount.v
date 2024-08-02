
//------------------------------------------------------------------------------
// Module: slowCLK
// Description: A clock divider module that generates a slower sqaure clock signal
//              from a higher frequency input clock. The period of the output clock 
//              is parameterized and determined by the number of input clock cycles
//              specified by the 'period' parameter. This module can be used to 
//              create a lower frequency clock signal suitable for PWM or other 
//              timing applications.
// Parameters:
//  - period: Number of input clock cycles that define the period of the output 
//            clock signal. The output clock period will be (period/2) cycles 
//            high and (period/2) cycles low, resulting in a frequency of 1/(period/2).
// Inputs:
//  - i_CLK: Input clock signal with a higher frequency.
// Outputs:
//  - o_CLK: Output slower clock signal with a frequency determined by the 'period' parameter.
//------------------------------------------------------------------------------

module slowCLK #( 
    parameter       period = 2500000)(
    input   wire    i_CLK,
    output  reg     o_CLK,);

    //------------------------------------------------------------------------------
    // Local Register Initialization
    // Description: Initializes the local counter register (rCount) which is used to 
    //              track the number of input clock cycles. The register has a width of 
    //              26 bits to handle a maximum 'period' value of 67,108,864.
    //------------------------------------------------------------------------------
    reg [0:25] rCount = 25'b0;

    //------------------------------------------------------------------------------
    // Output Clock Generation
    // Description: Generates the output clock signal (o_CLK) based on the current 
    //              value of the counter register (rCount). The output clock is set high 
    //              for the first half of the period (period/2) and low for the second half.
    //              This creates a square wave with a frequency equal to 1/(period/2) of the 
    //              input clock frequency.
    //------------------------------------------------------------------------------
    always @(posedge i_CLK) begin
        if(rCount < period/2) 
            o_CLK <= 1;
        else
            o_CLK <= 0;
    end

    //------------------------------------------------------------------------------
    // Counter Increment and Reset
    // Description: Increments the counter register (rCount) on each rising edge of the 
    //              input clock. When the counter reaches the specified period value, it 
    //              is reset to zero, allowing the generation of a continuous square wave.
    //------------------------------------------------------------------------------
    always @(posedge i_CLK) begin
        if(rCount >= period) 
            rCount <= 0;
        else
            rCount <= rCount + 1;
    end

endmodule