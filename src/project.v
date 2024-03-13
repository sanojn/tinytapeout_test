/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`define default_netname none

module tt_um_example (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock, 32768 Hz
    input  wire       rst_n     // reset_n - low to reset
);

    // Synchronize reset input to avoid metastability
    // Use rst_sync as internal asynchronous reset
    reg rst_sync1, rst_sync;
    always @(negedge clk)
        {rst_sync, rst_sync1} = {rst_sync1, rst_n};

    // Prescaler provides a one clock-cycle pulse at 32 Hz
    reg [9:0] prescaler;
    always @(posedge clk)
        if (!rst_sync) prescaler <= 10'd0;
        else prescaler <= prescaler + 1'd1;
    (* keep *) wire tick;
    assign tick = prescaler == 10'd0;
    
    wire btn4, btn6, btn8, btn10, btn12, btn20, btn100;
    debouncer Btn4_deb  (.clk(clk), .rst_n(rst_sync), .tick(tick), .button(ui_in[0]), .debounced(btn4));
    debouncer Btn6_deb  (.clk(clk), .rst_n(rst_sync), .tick(tick), .button(ui_in[1]), .debounced(btn6));
    debouncer Btn7_deb  (.clk(clk), .rst_n(rst_sync), .tick(tick), .button(ui_in[2]), .debounced(btn8));
    debouncer Btn10_deb (.clk(clk), .rst_n(rst_sync), .tick(tick), .button(ui_in[3]), .debounced(btn10));
    debouncer Btn12_deb (.clk(clk), .rst_n(rst_sync), .tick(tick), .button(ui_in[4]), .debounced(btn12));
    debouncer Btn20_deb (.clk(clk), .rst_n(rst_sync), .tick(tick), .button(ui_in[5]), .debounced(btn20));
    debouncer Btn100_deb(.clk(clk), .rst_n(rst_sync), .tick(tick), .button(ui_in[6]), .debounced(btn100));
    
    wire anybtn;
    assign anybtn = btn4 | btn6 | btn8 | btn10 | btn12 | btn20 | btn100;
    
    reg [3:0] digit1, digit10;
    always @(posedge clk)
        if (rst_sync==0) begin
          digit10 <= 4'd0; digit1 <= 4'd1;
        end
        else if (anybtn) begin
            if (digit10 == 4'd0 && digit1 == 4'd1 && !btn100) begin
                if      (btn4)   begin digit10 <= 4'd0; digit1 <= 4'd4; end
                else if (btn6)   begin digit10 <= 4'd0; digit1 <= 4'd6; end
                else if (btn8)   begin digit10 <= 4'd0; digit1 <= 4'd8; end
                else if (btn10)  begin digit10 <= 4'd1; digit1 <= 4'd0; end
                else if (btn12)  begin digit10 <= 4'd1; digit1 <= 4'd2; end
                else if (btn20)  begin digit10 <= 4'd2; digit1 <= 4'd0; end
            end
            else begin
                // decrement
                if (digit1 != 0) digit1 <= digit1 - 4'd1;
                else begin
                    digit1 <= 4'd9;
                    if (digit10 == 0) digit10 <= 4'd9; else digit10 <= digit10 - 4'd1;
                end
            end
        end

    // Multiplex digits and encode for seven segment
    wire showDigit1, showDigit10;
    assign showDigit1  =  clk & ~anybtn; // Show digit1 when clock is high and all buttons are released
    assign showDigit10 = ~clk & ~anybtn & digit10!=4'b0; // Show when clock is low, also blank zeroes
    
    wire [3:0] displaydigit;
    wire [7:0] displaysegments;
    assign displaydigit = (clk? digit1 : digit10); // display muxing uses the 32kHz clk
    seg7_digitsonly outputdecoder(displaydigit, displaysegments[6:0]);
    assign displaysegments[7] = 1'b0;

    
    // Now prepare the actual outputs, using uio_in[1:0] to
    // control inversion for common anode or cathode displays
    // uio_in[1:0] = 00 assumes a common cathode display.
    
    // when uio_in[0] = 1, segment outputs are inverted for common anode displays
    assign uo_out = ( uio_in[0] ? ~displaysegments : displaysegments );
    
    // when uio_in[1] = 1, multiplex outputs are inverted for direct drive common anode displays
    assign uio_out[0] =  ( uio_in[0] ? showDigit1  : ~showDigit1  );   // Digit1
    assign uio_out[1] =  ( uio_in[0] ? showDigit10 : ~showDigit10 );   // Digit10
    
    // All output pins must be assigned. If not used, assign to 0.
    assign uio_out[7:2] = 6'b0;
    assign uio_oe  = 8'b00000011;

endmodule
