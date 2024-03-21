/////////////////////////////////////////////////////////////////////////
// I2C slave with one sub-address byte and
// address auto-increment on the application bus
/////////////////////////////////////////////////////////////////////////
module i2c_slave #(
  parameter SLAVE_ADDR = 7'b1110000 // 0x70 (0xE0 and 0xE1)
  )
  (
	  input	clk,
	  input  rst_n,
	  output sda_o,
    output sda_oe,
    input  sda_i,
    input scl,

     // application interface
     output reg rw,
     output reg [7:0] addr,
     output reg wen,
     output reg [7:0] wdata,
     output reg rdata_used,
     input rdata
  );

  reg pull_sda;
  reg [3:0] sda_r, scl_r; // sample registers for i2c line debouncing and edge detection
  wire scl_rise, scl_fall, sda_rise, sda_fall;

  // i2c event enums
  parameter scl_rise_event = 2'b00;
  parameter scl_fall_event = 2'b01;
  parameter sda_rise_event = 2'b10;
  parameter sda_fall_event = 2'b11;
  
  reg [1:0] last_event;
  wire cmd_start, cmd_stop;

  assign sda_o  = 1'b0;
  assign sda_oe = pull_sda;

  // Detect edges using a glitch/noise filter
  // Require three consecutive identical samples to identify a proper edge:
  always @(posedge clk) begin
    scl_r <= {scl_r[2:0], scl};
    sda_r <= {sda_r[2:0], sda};
  end
  assign scl_rise = (scl_r == 4'b0111);
  assign scl_fall = (scl_r == 4'b1000);
  assign sda_rise = (sda_r == 4'b0111);
  assign sda_fall = (sda_r == 4'b1000);
	
  // Remember previous events
  always @(posedge clk)
    if (scl_rise)
       last_event <= scl_rise_event;
    else if (scl_fall)
       last_event <= scl_fall_event;
    else if	(sda_rise)
       last_event <= sda_rise_event;
    else if (sda_fall)
       last_event = sda_fall_event;

  // Detect start and stop events
  always @(posedge clk) begin
    cmd_start <= (last_event == sda_fall_event) && scl_fall;
    cmd_stop  <= (last_event == scl_rise_event) && sda_rise;
  end

  // FSM state enum
  parameter reset = 4'd0;
  parameter address_r = 4'd1;
  parameter address_f = 4'd2;
  parameter ack = 4'd3;
  parameter write_bytes = 4'd4;
  parameter write_bytes_f = 4'd5;
  parameter write_acq = 4'd6;
  parameter read_bytes_f = 4'd7;
  parameter read_ack = 4'd8;
		
  // This FSM tracks the bus transaction and executes the application R/W commands
  always @(posedge clk) begin
    reg [3:0] state;
		reg addr_ok;
    reg [3:0] counter;
    reg [7:0] dbyte;
	begin
    if (!rst) begin
			counter	   <= 4'd0;
			dbyte		   <= 8'd0;
			addr    	 <= 8'd0;
			rw			   <= 1'b1;
			rdata_used <= 1'b0;
			pull_sda 	 <= 1'b0;
			wdata_en 	 <= 1'b0;
			wdata		   <= 8'd0;
			state	      = reset;
			addr_ok		 <= 1'b0;
    end else begin
      // default assignments
      rdata_used <= 1'b0;

      // restart engine if start or stop was detected
	    if (cmd_start || cmd_stop)
				state = reset;
      case (state)
	      reset: begin
                   pull_sda <= 1'b0;
                   counter  <= 4'd0;
                   dbyte    <= 8'd0;
                   addr_ok  <= 1'b0;
                   wdata_en <= 1'b0;
                   if (cmd_start)
                     state = address_nr;
                   end
        
        address_r:  begin
                      pull_sda	<= 1'b0;
                      if (scl_rise) begin
                        dbyte <= {dbyte[6:0], sda_r[0]}; // shift in data bit
		                    state = address_f;
			                  counter <= counter + 1'b1;
		                   end // scl_rise
                     end // state address_r

        address_f: begin
                     pull_sda <= false;
                     if (scl_fall)
                       if (counter < 4'd8)
                         state = address_r; // need more bits
                       else
                        state = ack;
                    end //state address_f
      
        ack: begin
               counter <= 4'b0;
               if (!addr_ok) begin
                 // We haven't seen the slave address yet, so this must be it
                 if (dbyte[7:1] != SLAVE_ADDR)
		               state = reset; // not our message
		             else begin
                   // This is our I2C address
                   // Acknowledge it
                   pull_sda <= 1'b1;
                   if (scl_fall) begin
                     pull_sda <= 1'b0;
                     // remember that we've seen the address
                     addr_ok <= true;
                     if (!dbyte[0]) begin
                       rw <= 1'b0;
                       // and expect the subaddr byte next
                       state = address_r;
                     end else begin
                       // Remember that this is a read transaction
                       rw <= 1'b1;
                       // Grab data from appliction, start the reply transaction
                       // and prepare the application for next read
                       dbyte <= rdata;
                       addr <= addr + 1'b1;
                       counter <= 4'd0;
                       rdata_used <= 1'b1;
                       state = read_bytes_f;
                     end // dbyte[0] (read/write)
                   end // falling clock in slave address ack state
                 end // SLAVE_ADDR check
               end else begin // addr_ok
                 // We have seen the slave address previously,
                 // so this must be the sub-address byte.
                 // Acknowledge it, pass it to the application and prepare
                 // for write transactions after the next falling clock edge
                 pull_sda <= true;
                 if (scl_fall) begin
                   pull_sda <= 1'b0;
                   addr <= dbyte;
                   counter <= 0;
                   state = write_bytes;
                 end // falling clock in subaddr ack state
               end // addr_ok
             end // state ack
							
				write_bytes: begin
                       pull_sda	<= false;
                       if (scl_rise) begin
                         dbyte <= {dbyte[6:0] , sda_r[0]}; // shift in data bit
										     state = write_bytes_f;
										     counter <= counter + 1'b1;
									     end // scl_rise
                     end // state write_bytes
	
				write_bytes_f: begin
                         pull_sda	<= false;
                         if (scl_fall) begin
                           if (counter < 4'd8)
												     state = write_bytes; // get more bits
											     else begin
												     counter <= 4'd0;
												     wdata_en <= 1'b1;
												     state	= write_acq;
											     end // counter
                         end // scl_fall
                       end // state write_bytes_f
        
				write_acq: begin
                     wdata_en <= 1'b0;
									   pull_sda <= true;
                     if (scl_fall) begin
										   pull_sda <= false;
										   state = write_bytes;
									   end // scl_fall
                   end // state write_acq
									
				read_bytes_f: begin
                        pull_sda <= (dbyte[7] == 1'b0);
                        if (scl_rise)
							            counter <= counter + 1'd1;
										    if (scl_fall)
                          if (counter < 4'd8)
                            dbyte <= {dbyte[6:0], '0'};
			                    else begin 
	                          pull_sda <= 1'b0;
                            state = read_acq;
											    end
                        end // scl_fall in read_bytes_f
										  end //state read_bytes_f
									
				read_acq: begin
                    if (scl_rise)
                      if (sda_r(0) = '1')  // NAK
											  state = reset;
									  if (scl_fall) begin
										  // Capture rdata from app, and prepare it for the next read
										  dbyte <= rdata;
    									addr <= addr + 1'b1;
											counter <= 4'd0;
                      rdata_used <= 1'b1;
											state = read_bytes_f;
                    end // scl_fall in read_acq state
									end // state read_acq
			end case // FSM state
  end
	
  assign wdata = dbyte;

endmodule
