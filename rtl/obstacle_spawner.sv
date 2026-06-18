// the obstacle spawner module determines when to spawn and what to spawn
// based on given inputs like if the user is in game and how many clk cycle it's been
module obstacle_spawner (
	input  logic        clk,
	input  logic        reset,
	input  logic        game_tick,

	// from lfsr
	input  logic [1:0]  obs_type,     // random obstacle type
	input  logic        bird_height,  // random bird height
	input  logic [4:0]  spawn_gap,    // random gap 0-31
	input logic         hit,

	// to obstacle_controller
	output logic        spawn_en,     // pulse high when ready to spawn
	output logic [1:0]  spawn_type,   // what to spawn
	output logic        spawn_h       // bird height to spawn at
	
);

	localparam MIN_GAP = 7'd90;  // minimum gap needed between each spawn

	logic [7:0] gap_counter;  // 6 bits to hold MIN_GAP + spawn_gap (max 20+31=51)

    always_ff @(posedge game_tick) begin
		if (reset) begin
			gap_counter <= MIN_GAP;   // start with a full gap before first spawn
			spawn_en    <= 1'b0;
			spawn_type  <= 2'd0;
			spawn_h     <= 1'b0;
		end
        else if (!hit) begin
			spawn_en <= 1'b0;  // default low every tick

			if (gap_counter == '0) begin
				// ready to spawn — sample LFSR outputs right now
				spawn_en   <= 1'b1;
				spawn_type <= obs_type;
				spawn_h    <= bird_height;

				// load next gap from LFSR + minimum floor
				gap_counter <= MIN_GAP + spawn_gap;
			end
			else begin
				gap_counter <= gap_counter - 1;
			end
		end
	end

endmodule