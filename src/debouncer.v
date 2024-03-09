module debouncer (
    input wire clk,
    input wire rst_sync,
    input wire tick,
    input wire button,
    output wire debounced
);
    // Synchronize and debounce input signals
    // Clock cycle is several ms, so single flop is sufficient for metastability avoidance
    reg button_d;
    reg [1:0] state;
    parameter Idle     = 2'b00;
    parameter Glitch   = 2'b01;
    parameter Pressed  = 2'b11;
    parameter Released = 2'b10;
    always @(posedge clk) begin
        button_d <= button;
        case (state)
            Idle: if (tick & button_d) state <= 2'b01;  
                  
            Glitch: if (!button_d) state <= 2'b00;
                    else if (tick) state <= 2'b11;
                    
            Pressed: if (!button_d) state <= 2'b11;
                     
            Released: if (tick) state <= 2'b00;
        endcase
        debounced <= (state == 2'b11);
endmodule
