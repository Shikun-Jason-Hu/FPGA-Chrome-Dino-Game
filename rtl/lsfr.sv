// the LSFR module creates "random" output through XOR-ing shifting registers
// that we can use for obstacle_controller module for randomness in:
//		2'b type of obstacles (none, cactus, bird)
//		1'b bird spawning height (high or low)
//		5'b gap between each spawn
//	which give us a total of 8'b of randomness we need each clk cycle
module lfsr (
	input  logic       clk,
	input  logic       reset,

	output logic [1:0] obs_type,    // 0=none, 1=cactus, 2=bird
	output logic       bird_height, // 0=low, 1=high
	output logic [4:0] spawn_gap    // random gap between obstacles
);

    
	// 8-bit LFSR at positions 8,6,5,4
	// produces sequence of 255 values before it starts repeating itself
	localparam SEED = 8'b10101010;  // need random non-zero starting value
	

	// 8-bit LFSR Register
	logic [7:0] lfsr_reg;
	logic       feedback;

	// Feedback tap polynomial at 7,5,4,3 indices
	assign feedback = lfsr_reg[7] ^ lfsr_reg[5] ^ lfsr_reg[4] ^ lfsr_reg[3];

	always_ff @(posedge clk) begin
		if (reset)
			lfsr_reg <= SEED;           // must never be all zeros to begin with
		else
			lfsr_reg <= {lfsr_reg[6:0], feedback};  // shift left, insert feedback
	end

	
	// output logic
   // slice up so outputs aren't correlated
   always_comb begin
		// [1:0] will be obstacle type
		// map to only TYPE_CACTUS or TYPE_BIRD (never TYPE_NONE from spawner)
		// Type thresholds out of 4 possible values:
		// 00/01  is cactus (50% chance)
		// 10/11     is bird   (50% chance)
		case (lfsr_reg[1:0])
			2'b00:   obs_type = 2'd1;  // cactus
			2'b01:   obs_type = 2'd1;  // cactus
			2'b10:   obs_type = 2'd2;  // bird
			2'b11:   obs_type = 2'd2;  // bird
			default: obs_type = 2'd1;
		endcase

		// bit [2] is bird height
		bird_height = lfsr_reg[2];     // 0=low, 1=high

		// bits [7:3] is spawn gap (5 bits which give us 0-31)
		// scale up so minimum gap is always reasonable
		spawn_gap = lfsr_reg[7:3];     // used by spawner as frame count between spawns
	end

endmodule