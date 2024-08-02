
//------------------------------------------------------------------------------
// Module: UartReceive
// Description: Receives a series of bits from a UART communication at a baud 
//              rate of 115200 bits/sec and converts them into a parallel byte. 
//              The module uses a finite state machine (FSM) to handle the reception 
//              and decoding of UART data. The FSM transitions through states to 
//              capture the start bit, data bits, and end bit, and then asserts 
//              the `o_DataValid` signal to indicate when a valid byte has been received.
//
// Inputs:
//  - i_CLK: Clock signal used for timing and state transitions.
//  - i_Rx_Series: Serial data input from the UART transmission.
//
// Outputs:
//  - o_DataValid: Signal indicating that a valid byte has been received and 
//                 is available on `o_Rx_Byte`.
//  - o_Rx_Byte: Parallel output byte that contains the received data.
//
// Parameters:
//  - None (All parameters are internal and hardcoded for 115200 baud rate).
//------------------------------------------------------------------------------

module UartReceive(
    input        i_CLK,
    input        i_Rx_Series,
    output       o_DataValid,
    output [7:0] o_Rx_Byte);

    //------------------------------------------------------------------------------
    // State Definitions
    // Description: Parameters defining the FSM states for UART reception. 
    //              - fsm_idle: Waiting for the start bit.
    //              - fsm_start: Detecting the start bit.
    //              - fsm_data: Receiving and shifting in data bits.
    //              - fsm_end: Verifying the stop bit and setting data valid flag.
    //              - fsm_clean: Preparing for the next byte reception.
    //------------------------------------------------------------------------------
    parameter fsm_idle  = 3'b000;
    parameter fsm_start = 3'b001;
    parameter fsm_data  = 3'b010;
    parameter fsm_end   = 3'b011;
    parameter fsm_clean = 3'b100;

    //------------------------------------------------------------------------------
    // Local Counters and Registers
    // Description: 
    //  - r_CurrentState: holds the current state of the FSM, controlling 
    //                    the UART reception process. It transitions between idle, start, 
    //                    data, end, and clean states based on the UART signal and internal 
    //                    counters.
    //  - r_ClkCycles: Counter to track the timing of bit sampling. Used to ensure 
    //                 accurate sampling of bits at the correct baud rate.
    //  - r_BitIndex: Index to track which bit of the data byte is being received.
    //  - r_DataValid: Register to indicate when a valid byte has been received.
    //  - r_Rx_Byte: Register to store the received byte data.
    //
    // Note: `r_DataValid` and `r_Rx_Byte` are necessary as registers since they hold 
    //       state information and outputs, which are updated during the FSM's operation.
    //------------------------------------------------------------------------------
    reg [3:0] r_CurrentState = fsm_idle;
    reg [7:0] r_ClkCycles = 0;
    reg [2:0] r_BitIndex  = 0;
    reg [1:0] r_DataValid = 0;
    reg [7:0] r_Rx_Byte;

    // Main Logic 
    always @(posedge i_CLK) begin
        case(r_CurrentState)
            //------------------------------------------------------------------------------
            // Idle State (fsm_idle)
            // Description: The FSM remains in the idle state until it detects the start bit 
            //              (a low, 1'b0) on `i_Rx_Series`. It initializes the local registers 
            //              and transitions to the start state upon detecting the start bit.
            //------------------------------------------------------------------------------
            fsm_idle: begin
                r_ClkCycles <= 0;
                r_BitIndex  <= 0;
                r_DataValid <= 0;
                if(i_Rx_Series == 1'b0)
                    r_CurrentState <= fsm_start; 
                else
                    r_CurrentState <= fsm_idle;
            end

            //------------------------------------------------------------------------------
            // Start Bit State (fsm_start)
            // Description: In this state, the FSM waits until the middle of the start bit 
            //              period is reached to ensure accurate sampling. If the start bit 
            //              is still detected as low, it transitions to the data reception state. 
            //              Otherwise, it returns to the idle state if the start bit is invalid.
            //------------------------------------------------------------------------------
            fsm_start: begin
                // Wait until middle of start bit
                if(r_ClkCycles >= ((217-1)/2)) begin 
                    // Transition states if start bit is valid (still low)
                    if(i_Rx_Series == 1'b0)
                        r_CurrentState <= fsm_data;
                    else 
                        r_CurrentState <= fsm_idle; 
                    r_ClkCycles <= 0;
                end
                // Keep counting until at middle of start bit
                else begin 
                    r_ClkCycles <= r_ClkCycles + 1;
                    r_CurrentState <= fsm_start;
                end
            end

            //------------------------------------------------------------------------------
            // Data Reception State (fsm_data)
            // Description: In this state, the FSM samples and captures the data bits. It 
            //              waits until the middle of each bit period to sample the bit from 
            //              `i_Rx_Series`. The data bits are shifted into `r_Rx_Byte`. Once all 
            //              8 data bits are received, it transitions to the end state.
            //------------------------------------------------------------------------------
            fsm_data: begin
                // If in middle of bit
                if(r_ClkCycles >= 217) begin 
                    // Capture data into output register
                    r_Rx_Byte[r_BitIndex] <= i_Rx_Series; 
                    // See if done reading in data?
                    if(r_BitIndex == 7) begin 
                        r_CurrentState <= fsm_end;
                        r_ClkCycles <= 0; 
                    end
                    else
                        r_BitIndex <= r_BitIndex + 1;
                    r_ClkCycles <= 0;
                end

                // Keep counting until in middle of bit
                else begin 
                    r_ClkCycles <= r_ClkCycles + 1;
                    r_CurrentState <= fsm_data;
                end
            end

            //------------------------------------------------------------------------------
            // End Bit State (fsm_end)
            // Description: In this state, the FSM checks the stop bit to verify that it is 
            //              high. If the stop bit is valid, it asserts `r_DataValid` to indicate 
            //              that a complete byte has been received. It then transitions to the 
            //              clean state. If the stop bit is not valid, it remains in this state 
            //              to continue verifying the stop bit.
            //------------------------------------------------------------------------------
            fsm_end: begin
                // Wait until middle of stop bit
                if(r_ClkCycles >= 217) begin 
                    if(i_Rx_Series == 1'b1)
                        r_DataValid <= 1'b1;
                    r_CurrentState <= fsm_clean;
                end

                // Keep counting until middle of stop bit
                else begin 
                    r_ClkCycles <= r_ClkCycles + 1;
                    r_CurrentState <= fsm_end;
                end
            end

            //------------------------------------------------------------------------------
            // Clean Up State (fsm_clean)
            // Description: The FSM resets local registers and the `r_DataValid` signal for one 
            //              clock cycle before transitioning back to the idle state to prepare 
            //              for the reception of the next byte. The `r_ClkCycles` and `r_BitIndex` 
            //              counters are also reset in this state.
            //------------------------------------------------------------------------------
            fsm_clean: begin
                r_DataValid <= 0; 
                r_ClkCycles <= 0;
                r_BitIndex  <= 0;
                r_CurrentState <= fsm_idle;
            end
        endcase
    end

    //------------------------------------------------------------------------------
    // Assignments
    // Description: Outputs are assigned the values of the internal registers. 
    //              - `o_DataValid` is set to `r_DataValid` to indicate the validity 
    //                of the received byte.
    //              - `o_Rx_Byte` is set to `r_Rx_Byte` to output the received byte data.
    //------------------------------------------------------------------------------
    assign o_DataValid = r_DataValid; 
    assign o_Rx_Byte = r_Rx_Byte; 

endmodule