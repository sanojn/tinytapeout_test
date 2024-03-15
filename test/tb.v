`default_nettype none `timescale 1ns / 1ps

/* This testbench just instantiates the module and makes some convenient wires
   that can be driven / tested by the cocotb test.py.
*/
module tb ();

  // Dump the signals to a VCD file. You can view it with gtkwave.
  initial begin
    $dumpfile("tb.vcd");
    $dumpvars(0, tb);
    #1;
  end

  // Wire up the inputs and outputs:
  reg clk;
  reg rst_n;
  reg ena;
  reg [7:0] ui_in;
  reg [7:0] uio_in;
  wire [7:0] uo_out;
  wire [7:0] uio_out;
  wire [7:0] uio_oe;

  // Replace tt_um_example with your module name:
  tt_um_example user_project (

      // Include power ports for the Gate Level test:
`ifdef GL_TEST
      .VPWR(1'b1),
      .VGND(1'b0),
`endif

      .ui_in  (ui_in),    // Dedicated inputs
      .uo_out (uo_out),   // Dedicated outputs
      .uio_in (uio_in),   // IOs: Input path
      .uio_out(uio_out),  // IOs: Output path
      .uio_oe (uio_oe),   // IOs: Enable path (active high: 0=input, 1=output)
      .ena    (ena),      // enable - goes high when design is selected
      .clk    (clk),      // clock
      .rst_n  (rst_n)     // not reset
  );

   
  // The testbench module does some preprocesing of inputs and outputs that
  // simplifies life for the cocotb testbench
  
  // Apply button inputs as active high or low depending on uio_in[5]
  wire btn4, btn6, btn8, btn10, btn12, btn20, btn100;
  assign ui_in[0] = (uio_in[5] ? btn4 : ~btn4);
  assign ui_in[1] = (uio_in[5] ? btn6 : ~btn6);
  assign ui_in[2] = (uio_in[5] ? btn8 : ~btn8);
  assign ui_in[3] = (uio_in[5] ? btn10 : ~btn10);
  assign ui_in[4] = (uio_in[5] ? btn12 : ~btn12);
  assign ui_in[5] = (uio_in[5] ? btn20 : ~btn20);
  assign ui_in[6] = (uio_in[5] ? btn100 : ~btn100);
  assign ui_in[7] = 1'b0;
  wire anyButtonPressed;
  assign anyButtonPressed = btn4 | btn6 | btn8 | btn10 | btn12 | btn20 | btn100;

  // Check which segments are lit
  // common signals are active when equal to uio_in[7]
  wire digit1_active, digit10_active;
  assign digit1_active  = ( uio_out[0] == uio_in[7] ) && uio_oe[0]==1'b1;
  assign digit10_active = ( uio_out[1] == uio_in[7] ) && uio_oe[1]==1'b1;

  // segments are lit when equal to uio_in[6] and when the common
  // signal of either digit1 or digit10 is active
  wire [7:0] litsegments;
  assign litsegments = ( uio_in[6] ? uo_out : ~uo_out ) && (digit1_active || digit10_active);

  // Translate the lit segments to a digit
  reg [3:0] shownDigit;
  always @(litsegments) begin
     #1000 // wait 1 us after signal change to allow all signals to settle
           // this is useful especially for gate level simulations
     case (litsegments)
        8'b00111111: shownDigit <= 4'd0;
        8'b00000110: shownDigit <= 4'd1;
        8'b01011011: shownDigit <= 4'd2;
        8'b01001111: shownDigit <= 4'd3;
        8'b01100110: shownDigit <= 4'd4;
        8'b01101101: shownDigit <= 4'd5;
        8'b01111101: shownDigit <= 4'd6;
        8'b00000111: shownDigit <= 4'd7;
        8'b01111111: shownDigit <= 4'd8;
        8'b01101111: shownDigit <= 4'd9;
        8'b00000000: shownDigit <= 4'd15; // empty display
        default: shownDigit <= 4'd14; // undefined digit
     endcase
  end
  
endmodule
