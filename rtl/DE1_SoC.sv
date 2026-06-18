module DE1_SoC (HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, LEDR, CLOCK_50,
    VGA_R, VGA_G, VGA_B, VGA_BLANK_N, VGA_CLK, VGA_HS, VGA_SYNC_N, VGA_VS,
    V_GPIO);

	output logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
	output logic [9:0] LEDR;
	input  logic       CLOCK_50;
	output logic [7:0] VGA_R, VGA_G, VGA_B;
	output logic       VGA_BLANK_N, VGA_CLK, VGA_HS, VGA_SYNC_N, VGA_VS;
    inout  logic [35:0] V_GPIO;

	
    // Clock Divider
    logic [31:0] divided_clocks;
    clock_divider cd (
        .clock(CLOCK_50),
        .divided_clocks(divided_clocks)
    );

	 
    // N8 Controller
    wire latch, pulse;
    assign V_GPIO[27] = pulse;
    assign V_GPIO[26] = latch;

    logic up, down, reset;
    
    n8_driver controller (
        .clk    (CLOCK_50),
        .data_in(V_GPIO[28]),
        .latch  (latch),
        .pulse  (pulse),
        .up     (up),       // jump
        .down   (down),     // duck
        .left   (),
        .right  (),
        .select (),
        .start  (reset), // reset
        .a      (),
        .b      ()
    );


	// Internal Wires

	// dino_controller outputs
	logic [9:0] dino_x;
	logic [7:0] dino_y;
	logic [1:0] dino_status;
	logic [1:0] dino_motion;
	logic       animation_counter;

	// obstacle_controller outputs
	logic [1:0] obs0_type, obs1_type;
	logic [8:0] obs0_x,   obs1_x;
	logic [7:0] obs0_y,   obs1_y;
	logic [8:0] ground_offset;

	// lfsr outputs
	logic [1:0] lfsr_obs_type;
	logic       lfsr_bird_height;
	logic [4:0] lfsr_spawn_gap;

	// spawner outputs
	logic       spawn_en;
	logic [1:0] spawn_type;
	logic       spawn_h;

	// hit detection
	logic hit;

	// pterosaur wing animation — driven from animation_counter
	logic [1:0] pterosaur_motion;
	assign pterosaur_motion = {1'b0, animation_counter};

	// unused outputs
	assign HEX4 = 7'b1111111;
	assign HEX5 = 7'b1111111;
	assign LEDR = '0;


	// dino_controller
    dino_controller dino_ctrl (
        .clk               (CLOCK_50),
        .reset             (reset),
        .game_tick         (divided_clocks[21]), 
        .jump              (up),
        .duck              (down),
        .hit               (hit),
        .dino_x            (dino_x),
        .dino_y            (dino_y),
        .dino_status       (dino_status),
        .dino_motion       (dino_motion),
        .animation_counter (animation_counter)
    );


	 
    // obstacle_controller
    obstacle_controller obs_ctrl (
        .clk          (CLOCK_50),
        .reset        (reset),
        .game_tick    (divided_clocks[21]),
        .spawn_en     (spawn_en),
        .spawn_type   (spawn_type),
        .spawn_h      (spawn_h),
        .hit(hit),
        .obs0_type    (obs0_type),
        .obs0_x       (obs0_x),
        .obs0_y       (obs0_y),
        .obs1_type    (obs1_type),
        .obs1_x       (obs1_x),
        .obs1_y       (obs1_y),
        .ground_offset(ground_offset)
    );


    // lfsr
    lfsr lfsr_inst (
        .clk        (CLOCK_50),
        .reset      (reset),
        .obs_type   (lfsr_obs_type),
        .bird_height(lfsr_bird_height),
        .spawn_gap  (lfsr_spawn_gap)
    );


    // obstacle_spawner
    obstacle_spawner obs_spawner_inst (
        .clk        (CLOCK_50),
        .reset      (reset),
        .game_tick  (divided_clocks[21]),
        .obs_type   (lfsr_obs_type),
        .bird_height(lfsr_bird_height),
        .spawn_gap  (lfsr_spawn_gap),
        .hit        (hit),
        .spawn_en   (spawn_en),
        .spawn_type (spawn_type),
        .spawn_h    (spawn_h)
    );


    // scoreboard
    scoreboard scoreb_inst (
        .clk      (CLOCK_50),
        .reset    (reset),
        .hit      (hit),
        .HEX0     (HEX0),
        .HEX1     (HEX1),
        .HEX2     (HEX2),
        .HEX3     (HEX3)
    );

	 
    // hit_box_detector
    hit_box_detector hit_box_det (
        .x_dino    (dino_x[8:0]),	// 10'b to 9'b
        .y_dino    (dino_y),
        .dino_status(dino_status),
        .obs_x     ('{obs0_x, obs1_x}),
        .obs_y     ('{obs0_y, obs1_y}),
        .obs_types ('{obs0_type, obs1_type}),
        .reset     (reset),
        .hit       (hit)
    );


    // graphic_driver
    graphic_driver gd (
        .clk             (CLOCK_50),
        .game_tick       (divided_clocks[21]),
        .x_dino          (dino_x[8:0]),      // slice 10-bit to 9-bit
        .y_dino          (dino_y),
        .dino_status     (dino_status),
        .dino_motion_    (dino_motion[0]),    // renderer uses 1-bit
        .obs_x           ('{obs0_x, obs1_x}),
        .obs_y           ('{obs0_y, obs1_y}),
        .obs_types       ('{obs0_type, obs1_type}),
        .pterosaur_motion(pterosaur_motion),
        .reset           (reset),
        .ground_speed    (ground_offset),     // pass the whole 9-bit offset
        .hit             (hit),
        .VGA_R           (VGA_R),
        .VGA_G           (VGA_G),
        .VGA_B           (VGA_B),
        .VGA_BLANK_N     (VGA_BLANK_N),
        .VGA_CLK         (VGA_CLK),
        .VGA_HS          (VGA_HS),
        .VGA_SYNC_N      (VGA_SYNC_N),
        .VGA_VS          (VGA_VS)
    );

endmodule
