// this is the renderer module,  it take the game data and otuput the pixle color for each pixel.
// it have input clk, game_tick, px, py (the pxile coordinate), 
// x_dino, y_dino, (dino coordinate) dino_status , dino_motion(1 and  0 for different frame), 
// obs_x, obs_y, obs_types (obtacle data), pterosaur_motion (1 and 0 for wing up/down), 
// reset, ground_speed( as the ground offset) and hit signal.
// it output r, g, b for the pixel color at px and py coordinate.
module renderer (
	input  logic        clk,
	input  logic        game_tick,
	input  logic [9:0]  px,
	input  logic [8:0]  py,
	input  logic [8:0]  x_dino,
	input  logic [7:0]  y_dino,
	input  logic [1:0]  dino_status,
	input  logic        dino_motion,
	input  logic [8:0]  obs_x[1:0],
	input  logic [8:0]  obs_y[1:0],
	input  logic [1:0]  obs_types[1:0],
	input  logic        pterosaur_motion,  
	input  logic        reset,
	input  logic [8:0]  ground_speed,      
	input  logic        hit,
	output logic [7:0]  r, g, b
);

// local parameters for game dimensions, sprite IDs, and ROM sizes
	localparam int GAME_WIDTH  = 320;
	localparam int GAME_HEIGHT = 240;

	localparam int SPR_DINO_RUN1  = 0;	// alternating legs when running
	localparam int SPR_DINO_RUN2  = 1;
	localparam int SPR_DINO_JUMP  = 2;
	localparam int SPR_DINO_DUCK1 = 3;	// ducking and alternating legs
	localparam int SPR_DINO_DUCK2 = 4;
	localparam int SPR_DINO_HIT   = 5;	
	localparam int SPR_CACTUS     = 6;  // cactus obstacle
	localparam int SPR_PTERO_UP   = 7;	// bird fapping wing
	localparam int SPR_PTERO_DN   = 8;
	localparam int SPRITE_W = 32;
	localparam int SPRITE_H = 40;
    // graound and game over screen dimensions
	localparam int GROUND_Y = 175;
	localparam int GROUND_W = 320;
	localparam int GROUND_H = 8;

	localparam int GAMEOVER_W = 100;
	localparam int GAMEOVER_H = 50;

	int ground_addr;
	int ground_image_y;

    // ROMS for sprites, ground, and game over screen (aysnchornis)
	logic [SPRITE_W-1:0]   sprite_rom  [0:SPRITE_H*9-1];
	logic [GROUND_W-1:0]   ground_rom  [0:GROUND_H-1];
	logic [GAMEOVER_W-1:0] gameover_rom[0:GAMEOVER_H-1];
    // initil the rom 
    initial begin
        $readmemh("rom/sprite_rom.hex",sprite_rom);
        $readmemh("rom/ground_rom.hex",ground_rom) ;
        $readmemh("rom/game_over.hex", gameover_rom);
        // this is the direcotyr for the rom files, you can change it to your own path if needed
    end


    // game_over_pixel function 
    // take px and py and return if that pixl should be on for game over 
    function logic game_over_pixel;
        input int px;
        input int py;
        int image_x, image_y;
        begin
            if ((px >= (GAME_WIDTH- GAMEOVER_W)/2 ) &&
                (px < (GAME_WIDTH  + GAMEOVER_W)/2 ) &&
                (py >= (GAME_HEIGHT- GAMEOVER_H)/2)  &&
                    (py < (GAME_HEIGHT+ GAMEOVER_H)/2)) begin
                image_x=px-(GAME_WIDTH- GAMEOVER_W)/2;
                image_y = py -(GAME_HEIGHT - GAMEOVER_H)/2;
                game_over_pixel =gameover_rom[image_y][GAMEOVER_W - 1 - image_x];
            end else
                game_over_pixel=1'b0;
        end
    endfunction

	 
    // sprite_pixel function
    // take px, py,for target x and y
    // center_x, center_y for the center of the sprite and sid for the sprite id 
    // output if that pixel should be on for the sprite
    function logic sprite_pixel;
        input int px;
        input int py;
        input int center_x;
        input int center_y;
        input int sid;
        int left, top, image_x, image_y, addr;
        begin
            left = center_x -SPRITE_W/2;
            top  = center_y- SPRITE_H/2;
            if ((px >= left) &&(px< left + SPRITE_W) &&
                (py >= top)&& (py < top  +SPRITE_H))  begin
                image_x = px - left;
                image_y =py-top;
                addr = sid* SPRITE_H+ image_y;
                sprite_pixel= sprite_rom[addr][31 - image_x];
            end else
                sprite_pixel =1'b0;
        end
    endfunction


    // reddnering logic
    always_comb begin
        int dino_sprite_id;
        int obs_sprite_id;
        // initl value
        r = 0; g = 0; b = 0;
        ground_addr = 0;
        ground_image_y = 0;
        // reset 
        if (reset) begin
            r = 0; 
            g = 0; 
            b = 0;
        end else begin

            // Ground rendering
            if (py >= GROUND_Y && py < GROUND_Y + GROUND_H) begin
                // get the offeset of the ground and y coordinate in the ground image
                int sum;
                sum = ground_speed + int'(px);
                ground_addr = (sum >= GROUND_W) ? sum - GROUND_W : sum;
                ground_image_y = py - GROUND_Y;
                // check if the ground pixel should be on 
                if (py == GROUND_Y + 0 && ground_rom[0][ground_addr]) begin r = 255; g = 255; b = 255; end
                if (py == GROUND_Y + 1 && ground_rom[1][ground_addr]) begin r = 255; g = 255; b = 255; end
                if (py == GROUND_Y + 2 && ground_rom[2][ground_addr]) begin r = 255; g = 255; b = 255; end
                if (py == GROUND_Y + 3 && ground_rom[3][ground_addr]) begin r = 255; g = 255; b = 255; end
                if (py == GROUND_Y + 4 && ground_rom[4][ground_addr]) begin r = 255; g = 255; b = 255; end
                if (py == GROUND_Y + 5 && ground_rom[5][ground_addr]) begin r = 255; g = 255; b = 255; end
                if (py == GROUND_Y + 6 && ground_rom[6][ground_addr]) begin r = 255; g = 255; b = 255; end
                if (py == GROUND_Y + 7 && ground_rom[7][ground_addr]) begin r = 255; g = 255; b = 255; end
            end

            // selecting sprite
            dino_sprite_id = SPR_DINO_RUN1;
            obs_sprite_id  = SPR_CACTUS;
            // chose dino image
            if (hit) begin
                dino_sprite_id = SPR_DINO_HIT;
            end else begin
                if (dino_status == 2'd2) begin          // DUCK
                    dino_sprite_id = dino_motion ? SPR_DINO_DUCK2 : SPR_DINO_DUCK1;
                end else if (dino_status == 2'd1) begin // JUMP
                    dino_sprite_id = SPR_DINO_JUMP;
                end else begin                          // RUN
                    dino_sprite_id = dino_motion ? SPR_DINO_RUN2 : SPR_DINO_RUN1;
                end
            end
            // rendering dino sprite
            if (sprite_pixel(px, py, x_dino, y_dino, dino_sprite_id)) begin
                r = 255; g = 255; b = 255;
            end

            // Obstacle sprites chosing 
            for (int i = 0; i < 2; i++) begin
                if (obs_types[i] == 2'd1) begin
                    obs_sprite_id = SPR_CACTUS;
                end else if (obs_types[i] == 2'd2) begin
                    obs_sprite_id = pterosaur_motion ? SPR_PTERO_DN : SPR_PTERO_UP;
                end
                // rendering obstacle sprite
                if (obs_types[i] != 2'd0) begin
                    if (sprite_pixel(px, py, obs_x[i], obs_y[i], obs_sprite_id)) begin
                        r = 255; g = 255; b = 255;
                    end
                end
            end

            // Game over sprite rendering
            if (hit) begin
                if (game_over_pixel(px, py)) begin
                    r = 255; 
                    g = 255; 
                    b = 255;
                end
            end

        end
    end

endmodule
