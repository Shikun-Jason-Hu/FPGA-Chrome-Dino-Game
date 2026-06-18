// this module connects the renderer and video driver, 
// and serves as the top-level module for the graphic system
// it takes in all the game state inputs and give VGA outputs
//  it have input clk, game_tick, px, py (the pxile coordinate), 
// x_dino, y_dino, (dino coordinate) dino_status , dino_motion(1 and  0 for different frame), 
// obs_x, obs_y, obs_types (obtacle data), pterosaur_motion (1 and 0 for wing up/down), 
// reset, ground_speed( as the ground offset) and hit signal.
// it output VGA_R, VGA_G, VGA_B for the pixel color
// and VGA_BLANK_N, VGA_CLK, VGA_HS, VGA_SYNC_N, VGA_VS for the VGA signal.
module graphic_driver (
    input  logic        game_tick,
    input  logic        clk,
    input  logic [8:0]  x_dino,           
    input  logic [7:0]  y_dino,           
    input  logic [1:0]  dino_status,
    input  logic        dino_motion_,     
    input  logic [8:0]  obs_x[1:0],
    input  logic [8:0]  obs_y[1:0],
    input  logic [1:0]  obs_types[1:0],
    input  logic [1:0]  pterosaur_motion,	
    input  logic        reset,
    input  logic [8:0]  ground_speed,     
    input  logic        hit,
    output logic [7:0]  VGA_R, VGA_G, VGA_B,
    output logic        VGA_BLANK_N, VGA_CLK, VGA_HS, VGA_SYNC_N, VGA_VS
);
    // conneting renderer and video driver
    logic [9:0] px;
    logic [8:0] py;
    logic [7:0] r,g,b;
    // rendering module 
    renderer renderering (
		.clk             (clk),
		.game_tick       (game_tick),
		.px              (px),
		.py              (py),
		.x_dino          (x_dino),
		.y_dino          (y_dino),
		.dino_status     (dino_status),
		.dino_motion     (dino_motion_),
		.obs_x           (obs_x),
		.obs_y           (obs_y),
		.obs_types       (obs_types),
		.pterosaur_motion(pterosaur_motion[0]),  // renderer uses 1-bit
		.reset           (reset),
		.ground_speed    (ground_speed),
		.hit             (hit),
		.r               (r),
		.g               (g),
		.b               (b)
		);
    // vga driver module
    video_driver #(.WIDTH(320),.HEIGHT(240)) vga (
        .CLOCK_50   (clk),
        .reset      (reset),
        .x          (px),
        .y          (py),
        .r          (r),
        .g          (g),
        .b          (b),
        .VGA_R      (VGA_R),
        .VGA_G      (VGA_G),
        .VGA_B      (VGA_B),
        .VGA_BLANK_N(VGA_BLANK_N),
        .VGA_CLK    (VGA_CLK),
        .VGA_HS     (VGA_HS),
        .VGA_SYNC_N (VGA_SYNC_N),
        .VGA_VS     (VGA_VS)
    );

endmodule
