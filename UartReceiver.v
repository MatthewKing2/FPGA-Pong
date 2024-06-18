
// Module receives series bits from computer @ 115200 bits/sec and converts to parallel byte

module UartReceive(
    input        i_CLK,
    input        i_Rx_Series,
    output       o_DataValid,
    output [7:0] o_Rx_Byte);

    // Initialize some states
    // (not physical, just for naming) 
    parameter fsm_idle  = 3'b000;
    parameter fsm_start = 3'b001;
    parameter fsm_data  = 3'b010;
    parameter fsm_end   = 3'b011;
    parameter fsm_clean = 3'b100;

    // Keep track of the current state
    // (now this is actually in hardware)
    reg [3:0] r_CurrentState = fsm_idle;
        // [N,0] = [MSB,LSB] <-- this is the more common notation
        // [0,N] = [LSB,MSB]

    // Init other local parameters
    reg [7:0] r_ClkCycles = 0;          // 8 bits = 0,256-1
    reg [2:0] r_BitIndex  = 0;          // 3 bits = 0,8-1
    reg [1:0] r_DataValid = 0;          // 1 bit = 0,1
        // Can't write wires high or low, so need register
        // for data valid
    reg [7:0] r_Rx_Byte;

    // Main Logic 
    always @(posedge i_CLK) begin

        case(r_CurrentState)

            // Idle case
            // ########################################
            fsm_idle: begin
                // Keep local values, and ouputs correct 
                r_ClkCycles <= 0;
                r_BitIndex  <= 0;
                r_DataValid <= 0;
                // When start of start bit
              if(i_Rx_Series == 1'b0) begin 
                   r_CurrentState <= fsm_start; 
                end
                // No changes
                else begin 
                    r_CurrentState <= fsm_idle;
                end
            end

            // Start Bit case
            // ########################################
            fsm_start: begin
                if(r_ClkCycles >= ((217-1)/2)) begin 
                    // Transition states if start bit is valid
                    if(i_Rx_Series == 1'b0) begin 
                        r_CurrentState <= fsm_data;
                    end
                    // Go back to idel if invalid start bit
                    else 
                        r_CurrentState <= 0; 
                    r_ClkCycles <= 0;
                end
                // Keep counting until at middle of start bit
                else begin 
                    r_ClkCycles <= r_ClkCycles + 1;
                    r_CurrentState <= fsm_start;
                end
            end

            // Receving Data case
            // ########################################
            fsm_data: begin
                // If in middle of bit
                if(r_ClkCycles >= 217) begin 
                    // Put data into output regsiter
                    r_Rx_Byte[r_BitIndex] <= i_Rx_Series;
                    // Done reading in data?
                    if(r_BitIndex == 7) begin 
                        r_CurrentState <= fsm_end;
                        r_ClkCycles <= 0; // reset counter for end state
                    end
                    // Not done yet 
                    else begin 
                        r_BitIndex <= r_BitIndex + 1;
                    end
                    r_ClkCycles <= 0;
                end
                else begin 
                    r_ClkCycles <= r_ClkCycles + 1;
                    r_CurrentState <= fsm_data;
                end
            end

            // End Bit case
            // ########################################
            fsm_end: begin
                // Look for stop bit and assert data valid line
                if(r_ClkCycles >= 217) begin 
                  if(i_Rx_Series == 1'b1) begin 
                        r_DataValid <= 1'b1;
                    end 
                    r_CurrentState <= fsm_clean;
                end
                else begin 
                    r_ClkCycles <= r_ClkCycles + 1;
                    r_CurrentState <= fsm_end;
                end
            end

            // Clean Up case
            // ########################################
            fsm_clean: begin
                r_DataValid <= 0;   // Data valid is asserted for one clk cycle
                r_ClkCycles <= 0;
                r_BitIndex  <= 0;
                r_CurrentState <= fsm_idle;
            end

        endcase
    end

    // Assignments 
    assign o_DataValid = r_DataValid; // cant write wire high/low needed register
    assign o_Rx_Byte = r_Rx_Byte; 

endmodule
