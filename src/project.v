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
    
    wire btn4, btn6, btn8, btn10, btn20, btn100;
    //debouncer (clk, rst_sync, ui_in[0], btn4);
    //debouncer (clk, rst_sync, ui_in[1], btn6);
    //debouncer (clk, rst_sync, ui_in[2], btn8);
    //debouncer (clk, rst_sync, ui_in[3], btn10);
    //debouncer (clk, rst_sync, ui_in[4], btn20);
    //debouncer (clk, rst_sync, ui_in[5], btn100);
    assign btn4 = ui_in[0];
    assign btn6 = ui_in[1];
    assign btn8 = ui_in[2];
    assign btn10 = ui_in[3];
    assign btn20 = ui_in[4];
    assign btn100 = ui_in[5];
    
    wire anybtn;
    assign anybtn = btn4 | btn6 | btn8 | btn10 | btn20 | btn100;
    
    reg [4:0] digit1, digit10;
    always @(posedge clk)
        if (anybtn) begin
            if (digit10 == 4'd0 && digit1 == 4'd1 && !btn100) begin
                if      (btn4)   begin digit10 <= 4'd0; digit1 <= 4'd4; end
                else if (btn6)   begin digit10 <= 4'd0; digit1 <= 4'd6; end
                else if (btn8)   begin digit10 <= 4'd0; digit1 <= 4'd8; end
                else if (btn10)  begin digit10 <= 4'd1; digit1 <= 4'd0; end
                else if (btn20)  begin digit10 <= 4'd2; digit1 <= 4'd0; end
            end
            else begin
                // decrement
                if (digit1 != 0) digit1 <= digit1 - 4'd1;
                else begin
                    if (digit10 == 0) digit10 <= 4'd9; else digit10 - 4'b1;
                    digit1 == 4'b9;
                end
            end
        end

    // All output pins must be assigned. If not used, assign to 0.
    assign uo_out[7:0] = {digit10, digit1}
    assign uio_out = 8'b0;
    assign uio_oe  = 8'b0;
    
endmodule
