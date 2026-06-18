// this is the module hit box detecting
// it takes x and y coordinate of the dino (x_dino, y_dino	), the status of the dino (running or ducking or jumping) (dino_statu), 
// the x and y coordinate of the obstacles (obs_x obs_y),
// the type of the obstacles (cactus or pterosaur or nothing), and reset signal as input
// it output hit signal if the dino is hit
module hit_box_detector (
	input logic [8:0] x_dino,
	input logic [7:0] y_dino,
	input logic [1:0] dino_status,
	input logic [8:0] obs_x[1:0],
	input logic [8:0] obs_y[1:0],
	input logic [1:0] obs_types[1:0],
	input logic reset,
	output logic hit
);
	// hit box size for dino and obstacles
	localparam int DINO_RUN_WIDTH     = 30;
	localparam int DINO_RUN_HEIGHT    = 16;
	localparam int DINO_DUCK_WIDTH    = 30;
	localparam int DINO_DUCK_HEIGHT   = 16;
	localparam int CACTUS_WIDTH       = 18;
	localparam int CACTUS_HEIGHT      = 36;   
	localparam int PTEROSAUR_WIDTH    = 22;
	localparam int PTEROSAUR_HEIGHT   = 14;
	// comintiaotnal logic for hit box  	
	always_comb begin
		int dino_half_w;
		int dino_half_h;
		int obs_half_w;
		int obs_half_h;
		// default hit is 0
		hit = 1'b0;

		//determint dino hit box size 
		if (dino_status == 2'd2) begin
			dino_half_w= DINO_DUCK_WIDTH / 2;
			dino_half_h = DINO_DUCK_HEIGHT / 2;
		end else begin
			dino_half_w =DINO_RUN_WIDTH / 2;
			dino_half_h = DINO_RUN_HEIGHT / 2;
		end
	// checking each obstacle for hit box collision
    for (int i = 0; i <2; i++) begin
      obs_half_w = 0;
      obs_half_h=0;
		// determint obstacle hit box size based on type
      if (obs_types[i] ==2'd1) begin
        obs_half_w =CACTUS_WIDTH / 2;
        obs_half_h = CACTUS_HEIGHT / 2;
      end else if (obs_types[i] == 2'd2) begin
        obs_half_w= PTEROSAUR_WIDTH / 2;
        obs_half_h = PTEROSAUR_HEIGHT/ 2;
      end
		// hited logic
      if (obs_types[i] != 2'd0) begin
        hit = hit || (
          (int'(x_dino) + dino_half_w > int'(obs_x[i])- obs_half_w) &&
          (int'(x_dino) -dino_half_w < int'(obs_x[i]) +obs_half_w)  &&
          (int'(y_dino)+ dino_half_h> int'(obs_y[i]) - obs_half_h) &&
          (int'(y_dino) -dino_half_h < int'(obs_y[i]) +obs_half_h  ) 
        );
      end
    end
	// reset logic 
    if (reset) begin
      hit = 1'b0;
    end
  end

endmodule
