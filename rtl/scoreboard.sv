// the scoreboard module counts each second elapsed as one point
// by assuming 60 clock ticks as a second. The scoreboard will be
// represented as BCD where each digit is stored separately so it's
// easier to drive the HEX displays (active-low)
module scoreboard (
	input logic clk,
	input logic reset,
	input logic hit,

	output logic [6:0] HEX0,	// ones
	output logic [6:0] HEX1,	// tens
	output logic [6:0] HEX2,	// hundreds
	output logic [6:0] HEX3		// thousands
);
	
	localparam TICKS_PER_SECOND = 26'd49_999_999; // 50M = 1 second
	
	logic [25:0] tick_counter; // we need a counter to count up to 50M
	logic second_pulse; // shoot a 1-cycle pulse every second
	
	// BCD digits
	logic [3:0] ones;
	logic [3:0] tens;
	logic [3:0] hundreds;
	logic [3:0] thousands;
	
	// tick counter
 	always_ff @(posedge clk) begin
		if (reset)
			tick_counter <= '0;
        else begin
			if (tick_counter >= TICKS_PER_SECOND - 1)
				tick_counter <= '0;	// reset counter to zero ones it's at 60
			else
				tick_counter <= tick_counter + 1;
		end
	end
	
	assign second_pulse = (tick_counter == TICKS_PER_SECOND - 1);
	
	// BCD Counter that increments each second
 	always_ff @(posedge clk) begin
		if (reset) begin
			ones <= 4'd0;
			tens <= 4'd0;
			hundreds <= 4'd0;
			thousands <= 4'd0;
		end
		
		else if (second_pulse && ~hit) begin
			// ones
			if (ones == 4'd9) begin
				ones <= 4'd0;
				
				// tens
				if (tens == 4'd9) begin
					tens <= 4'd0;
					
					//hundreds
					if (hundreds == 4'd9) begin
						hundreds <= 4'd0;
						
							//thousands
							if (thousands < 4'd9)
								thousands <= thousands + 1;
					end
					else
						hundreds <= hundreds + 1;
				end
				else tens <= tens + 1;
			end
			else ones <= ones + 1;	
		end	
	end
	
	// 7-seg display
	function automatic [6:0] bcd_to_7seg (input [3:0] digit);
		case (digit)
			4'd0: bcd_to_7seg = 7'b1000000;  // 0
			4'd1: bcd_to_7seg = 7'b1111001;  // 1
			4'd2: bcd_to_7seg = 7'b0100100;  // 2
			4'd3: bcd_to_7seg = 7'b0110000;  // 3
			4'd4: bcd_to_7seg = 7'b0011001;  // 4
			4'd5: bcd_to_7seg = 7'b0010010;  // 5
			4'd6: bcd_to_7seg = 7'b0000010;  // 6
			4'd7: bcd_to_7seg = 7'b1111000;  // 7
			4'd8: bcd_to_7seg = 7'b0000000;  // 8
			4'd9: bcd_to_7seg = 7'b0010000;  // 9
			default: bcd_to_7seg = 7'b1111111;  // blank
		endcase
	endfunction

	// driving the displays
	assign HEX0 = bcd_to_7seg(ones);
	assign HEX1 = bcd_to_7seg(tens);
	assign HEX2 = bcd_to_7seg(hundreds);
	assign HEX3 = bcd_to_7seg(thousands);


endmodule
