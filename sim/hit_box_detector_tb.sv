// this is the hit box testing bench 
module hit_box_detector_tb;

  logic [8:0] x_dino, y_dino;
  logic [2:0] dino_status;
  logic [8:0] obs_x [1:0];
  logic [8:0] obs_y [1:0];
  logic [1:0] obs_types [1:0];
  logic reset;
  logic hit;
  // initlize the hit box detector module
  hit_box_detector dut (
    .x_dino(x_dino),
    .y_dino(y_dino),
    .dino_status(dino_status),
    .obs_x(obs_x),
    .obs_y(obs_y),
    .obs_types(obs_types),
    .reset(reset),
    .hit(hit)
  );
  // start testing
  initial begin
    // default values
    reset =1'b0;
    x_dino= 9'd100;
    y_dino =9'd100 ;
    dino_status = 3'd0 ;

    obs_x[0] = 9'd0;
    obs_y[0]= 9'd0;
    obs_types[0]= 2'd0;

    obs_x[1] = 9'd0;
    obs_y[1] =9'd0;
    obs_types[1]= 2'd0;

    #10;

    // Test 1: no obstacle,  not hit
    
    $display("Test 1 no obstacle: hit = %b", hit);

    // Test 2: cactus overlapping dino in obs[0],  hit
    obs_x[0]= 9'd100;
    obs_y[0] =9'd100;
    obs_types[0] =2'd1 ;

    #10;
    $display("Test 2 cactus overlap ( first obstacle): hit = %b", hit);

    // Test 3: cactus far away in obs[0],  not hit
    obs_x[0] =9'd200;
    obs_y[0]= 9'd100 ;
    obs_types[0]=2'd1;

    #10;
    $display("Test 3 cactus far (first obstacle): hit = %b", hit);

    // Test 4: pterosaur overlapping in obs[1],  hit
    obs_x[1] = 9'd100;
    obs_y[1] =9'd100;
    obs_types[1]= 2'd2;
    obs_types[0] =2'd0; // make sure obs[0] is empty
    #10;
    $display("Test 4 pterosaur overlap( second obstacle): hit = %b", hit);

    // Test 5: ducking dino overlapping cactus in obs[1],  hit
    dino_status = 3'd2;
    obs_x[1]= 9'd100;
    obs_y[1] =9'd100;
    obs_types[1] = 2'd1;

    #10;
    $display("Test 5 duck overlap ( second obstacle): hit = %b", hit);

    // Test 6: reset active, hit should be 0
    reset =1'b1;

    #10;
    $display("Test 6 reset: hit = %b", hit);

    reset =1'b0;

    #10;
    $stop;
  end

endmodule