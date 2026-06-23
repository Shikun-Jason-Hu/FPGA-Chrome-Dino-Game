// This module is a FSM that handles the game logic and states. Specifically, RUN, JUMP, DUCK, DEAD
// It handles physics of jumping and ducking based on the inputs given from the N8 Controller
// It outputs the x, y coordinate of the dino, which action it's currently doing, and it's animation
// every game tick.
module dino_controller (
	// inputs
	input logic clk,			// 50 MHz clock
	input logic reset,			// resets the dino's motion, position, animation, and states
	input logic game_tick,		// one clk cycle per frame of the game
	input logic jump,				// when up-button is pressed on N8 controller
	input logic duck,				// when down-button is pressed on N8 controller
	input logic hit,				// 1'b1 if collided w/ obstacle, 1'b0 otherwise
	
	// outputs for Graphic Driver module to determine which frame and what motion to drive
	output logic [1:0] dino_status,   // 0=run, 1=jump, 2=duck, 3=dead
	output logic [1:0] dino_motion,   // 0=run_frame, 1=duck_frame, 2=jump_frame
	
	output logic animation_counter, // tells graphic driver module which frame the dino should be
	
	output logic [9:0] dino_x,
	output logic [7:0] dino_y
	);
	
	// some local constants and parameters for readability
	localparam DINO_X = 10'd50;		// dino shouldn't move horizontally
	localparam GROUND_Y = 8'd178;	// ground is y = 200, dino height is 22, so 200-22=178
	localparam DUCK_Y = 8'd187;		// top-left y-coord. when ducking is 200 - 13
	localparam signed JUMP_VELOCITY = -15;	// upward velocity is negative
	localparam GRAVITY = 9'd1;				// adds to velocity each from to slow down jump velocity
	localparam ANIMATION_FRAME = 4'd8;	// the # of ticks until animation frame alternates
	
	
	
	// states enumeration: run, jump, duck, and dead
	typedef enum logic [1:0] {
		RUN   = 2'd0,
		JUMP  = 2'd1,
		DUCK  = 2'd2,
		DEAD  = 2'd3
	} dino_state_t;
	
	dino_state_t ps, ns;
	
	// frames: running, jump, duck
	// dead frame is handled by hit-box detection module together with "hit" signal
	// idle and jump is the same sprite, so we don't need an additional IDLE_FRAME
	localparam STATUS_RUN = 2'd0;
	localparam STATUS_JUMP = 2'd1;
	localparam STATUS_DUCK = 2'd2;

	
	// dino physics
	logic signed    [8:0] y_velocity;		// vertical velocity, one more bit than y-pos b/c signed
	logic			 [7:0] y_position;		// current y-position, X SHOULDN'T MOVE
	logic jump_disable;

	
	// state register
    always_ff @(posedge game_tick) begin
        if (reset)
            ps <= RUN;
        else
            ps <= ns;
   end
	
	// next state logic
	always_comb begin
		ns = ps;
		case (ps) 
			RUN: begin								
				if (hit)			ns = DEAD;						
				else if (jump)	 ns = JUMP;
				else if (duck)	ns = DUCK;
			end
			
			JUMP: begin								
				if (hit)									ns = DEAD;						
				else if (y_position == GROUND_Y && jump_disable)	ns = RUN;
			end
			
			DUCK: begin
				if (hit)				ns = DEAD;		
				else if (!duck)	ns = RUN;
			end
			
			DEAD: begin			// it's stuck at DEAD state unless reset is triggered, where it
				if (reset)		// will go back to IDLE state
					ns = RUN;
			end
		endcase
	end
	

	
	// jump physics
    always_ff @(posedge game_tick) begin
		if (reset) begin
			y_position <= GROUND_Y;
			y_velocity <= '0;
			jump_disable <= '0;
		end
			
			
			else begin
			case(ps)
				
				// run, and dead states are the same cuz you're not moving vertically				
				RUN, DEAD: begin
					y_position <= GROUND_Y;
					y_velocity <= '0;
					jump_disable <= '0;
				end
	
				JUMP: begin				// initially, the Dino will travel upward
					if (y_velocity == -1)
						jump_disable = 1;
						
					if (y_position == GROUND_Y && ~jump_disable)	// with max velocity of -10 (negative # goes up)
						y_velocity <= JUMP_VELOCITY;			// and the GRAVITY acts as a decrement until velocity
						
					else if (ps != JUMP) begin 
					    y_velocity <= '0;
					    jump_disable <= '0;
					end
					    
					else										// goes to zero and becomes positive where Dino will
						y_velocity <= y_velocity + GRAVITY; // begin falling down.
						
					if ($signed({1'b0, y_position}) + y_velocity >= $signed({1'b0, GROUND_Y}))
						y_position <= GROUND_Y;					// y_velocity stops decrementing (aka Dino stops falling)
					else											// when Dino's y-position is at that of the GROUND's
						y_position <= y_position + $unsigned(y_velocity);
				end
				
				DUCK: begin
					y_position <= DUCK_Y;
					y_velocity <= '0;
					jump_disable <= '0;
				end
			endcase
		end	
	end
	
	
	// animation counter logic
// 	always_ff @(posedge clk) begin
    always_ff @(posedge game_tick) begin
		if (reset)
			animation_counter <= '0;
			
// 		else if (game_tick) begin
        else begin
            animation_counter <= ~animation_counter;
		end
	end
	
	
	// output logic
	always_comb begin
		// X is fixed
		dino_x = DINO_X;
		// y position is based on states
		dino_y = y_position;
		
		dino_motion = animation_counter ? 2'd1 : 2'd0;
		
		case (ps)
			RUN: dino_status = STATUS_RUN;
			
			JUMP: dino_status = STATUS_JUMP;
			
			DUCK: dino_status = STATUS_DUCK;
						
			default: dino_status = STATUS_RUN;
			
		endcase
	end
endmodule
	
