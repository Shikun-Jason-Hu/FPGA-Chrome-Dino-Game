// This module handles the logic regarding spawning/despawning obstacles and moving them across the screen
// It also freezes every element of the game when "hit" is detected, because that means game is over
module obstacle_controller (
	// general inputs
	input logic clk,
	input logic reset,
	input logic game_tick,
	
	// spawning inputs
	input logic spawn_en,				// enabler for spawner
	input logic [1:0] spawn_type,		// type of spawn: 0=nothing, 1=cactus, 2=bird
	input logic spawn_h,					// bird height of spawn: 0=low flight, 1= high flight
	input logic hit,                    // freezes obstacles upon "hit"
	
	
	// obstacle type & dimension to be output & for hit-box detection
	// for obstacle 0
	output logic [1:0] obs0_type,
	output logic [8:0] obs0_x,
	output logic [7:0] obs0_y,

	// for obstacle 1
	output logic [1:0] obs1_type,
	output logic [8:0] obs1_x,
	output logic [7:0] obs1_y,

	// ground moving speed (aka scroll speed)
   output logic [8:0]  ground_offset
	);
	
	// local parameters and constants for readability within the module
	localparam SCREEN_W = 9'd320;
	localparam SCROLL_SPEED = 9'd3; // # of pixels shifted left every frame
											  // should not exceed width of dino
	localparam GROUND_TEX_W = 9'd200; // the width of ground strip before any wrapping	
	
	// local parameters for obstacles
	localparam TYPE_NONE = 2'd0;
	localparam TYPE_CACTUS = 2'd1;
	localparam TYPE_BIRD = 2'd2;
	
	// cactus sprite dimension
	localparam CACTUS_Y = 8'd164;  // 200(Ground) - 36(Cactus Height)
	
	// bird's y position is constant throughout the frames once it's spawned
	localparam BIRD_LOW = 8'd172;		// bottom at 186 --- 200-14
	localparam BIRD_HIGH = 8'd165;      // adjust so Dino must duck to not get hit
	
	// MAXIMUM # of obstacles that can exist on the page at once
	localparam MAX_OBS = 2;
	
	// tracking obstacles
	logic [8:0] obs_x 	[0: MAX_OBS - 1];
	logic [7:0] obs_y 	[0: MAX_OBS - 1];
	logic [1:0] obs_type [0: MAX_OBS - 1];
	
	// for-loop variable
	integer i;
	
	// ground offset or scrolling logic
    always_ff @(posedge game_tick) begin
		if (reset)
			ground_offset <= '0;						// if reset is HIGH, then we want no offset for ground strip
        else if (!hit) begin
			if (ground_offset >= GROUND_TEX_W - SCROLL_SPEED)	// elif the offset becomes greater than ground's width,
				ground_offset <= '0;					// we wrap the offset around so that it's back at zero
			else
				ground_offset <= ground_offset + SCROLL_SPEED; // otherwise we just offset the ground by scroll speed
		end
	end
	
	// scrolling until despawn logic
	//  handles both scroll and spawn
    // always_ff @(posedge clk) begin
    always_ff @(posedge game_tick) begin
        if (reset) begin
            for (i = 0; i < MAX_OBS; i++) begin
                obs_x[i]    <= SCREEN_W;
                obs_y[i]    <= '0;
                obs_type[i] <= TYPE_NONE;
            end
        end

        else if (!hit) begin
            // scroll + despawn logic
            for (i = 0; i < MAX_OBS; i++) begin
                if (obs_type[i] != TYPE_NONE) begin
                    if (obs_x[i] <= SCROLL_SPEED)
                        obs_type[i] <= TYPE_NONE;
                    else
                        obs_x[i] <= obs_x[i] - SCROLL_SPEED;
                end
            end
    
            // spawn logic
            if (spawn_en && ~hit) begin
                for (i = 0; i < MAX_OBS; i++) begin
                    if (obs_type[i] == TYPE_NONE) begin
                        obs_x[i]    <= SCREEN_W;
                        obs_type[i] <= spawn_type;
    
                        case (spawn_type)
                            TYPE_CACTUS: obs_y[i] <= CACTUS_Y;
                            TYPE_BIRD:   obs_y[i] <= spawn_h ? BIRD_HIGH : BIRD_LOW;
                            default: ;
                        endcase
                        break;
                    end
                end
            end
        end
    end	
	
	// output logic
	// wires internal arrays to the output. To hit-box detection and renderer
	// obs0
	assign obs0_x = obs_x[0];
	assign obs0_y = obs_y[0];
	assign obs0_type = obs_type[0];
	
	// obs1
	assign obs1_x = obs_x[1];
	assign obs1_y = obs_y[1];
	assign obs1_type = obs_type[1];


endmodule
	
