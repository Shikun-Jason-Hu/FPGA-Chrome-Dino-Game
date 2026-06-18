`timescale 1ns/1ps
// this is the testbench for obstacle_controller, where we test for different scanrios
// of different inputs and spawns
// 1. scrolling through the ground and wrapping it when it reaches the edge
// 2. spawning cactus
// 3. spawning bird with height = low
// 4. spawning bird with height = high
// 5. scrolling through obstacles
// 6. removing obstacles (despawning)
// 7. making sure 2 obstacles can co-exist on playfield (VGA)
module obstacle_controller_tb();

    logic       clk, reset, game_tick;
    logic       spawn_en;
    logic [1:0] spawn_type;
    logic       spawn_h;

    logic [1:0] obs0_type, obs1_type;
    logic [8:0] obs0_x,   obs1_x;
    logic [7:0] obs0_y,   obs1_y;
    logic [8:0] ground_offset;

    // instantiate dut
    obstacle_controller dut (.*);

    // 50 MHz clock
	 
    parameter PERIOD = 20;
    initial clk = 0;
    always #(PERIOD/2) clk = ~clk;

    // local constants matching obstacle_controller local parameters
    localparam SCREEN_W      = 9'd320;
    localparam GROUND_TEX_W  = 9'd200;
    localparam TYPE_NONE     = 2'd0;
    localparam TYPE_CACTUS   = 2'd1;
    localparam TYPE_BIRD     = 2'd2;
    localparam CACTUS_Y      = 8'd164;
    localparam BIRD_LOW      = 8'd172;
    localparam BIRD_HIGH     = 8'd150;


	 //TASKS 

    // pulse game_tick b/c we use always_ff @(posedge game-tick)
    task do_tick();
        @(posedge clk); #1;
        game_tick = 1;
        @(posedge clk); #1;
        game_tick = 0;
    endtask


    // reset
    task do_reset();
        spawn_en = 0; spawn_type = 0; spawn_h = 0;
        reset = 1;       do_tick();
        reset = 0;       do_tick();
    endtask


    // spawn one obstacle for one tick then drop spawn_en
    task do_spawn(input logic [1:0] stype, input logic sh);
        spawn_type = stype;
        spawn_h    = sh;
        spawn_en   = 1;     
		  do_tick();
        spawn_en   = 0;
    endtask



    // TEST 1: ground offset scrolling and wrap
    //   offset should increment by 1 each tick "game_tick", wrap to 0 at 200
    task test_ground_scroll();
        $display("\nTEST 1: ground offset scroll + wrap");
        do_reset();

        // watch 5 ticks of normal scroll
        repeat (5) begin
            do_tick();
            $display("  tick — ground_offset=%0d", ground_offset);
        end

        // fast-forward to just before wrap (offset = 198 after 198 ticks from 0)
        // we've already done 5
        repeat (193) do_tick();
        $display("  at offset=%0d (expect 198)", ground_offset);

        do_tick(); // when offset is 199, ground wraps to 0 next tick
        $display("  at offset=%0d (expect 199, about to wrap)", ground_offset);

        do_tick();
        $display("  after wrap: ground_offset=%0d (expect 0)", ground_offset);

        if (ground_offset == 9'd0)
            $display("  PASS: ground offset wrapped correctly");
        else
            $display("  FAIL: expected 0, got %0d", ground_offset);
    endtask



    // TEST 2: cactus spawn
    //   spawning type=1 should place obs0 at x=320, y=164
    task test_cactus_spawn();
        $display("\nTEST 2: cactus spawn");
        do_reset();

        do_spawn(TYPE_CACTUS, 1'b0);
        $display("  after spawn: obs0: type=%0d  x=%0d  y=%0d", obs0_type, obs0_x, obs0_y);
        $display("                (expect type=1  x=%0d  y=%0d)", SCREEN_W, CACTUS_Y);

        if (obs0_type == TYPE_CACTUS && obs0_x == SCREEN_W && obs0_y == CACTUS_Y)
            $display("  PASS!");
        else
            $display("  FAIL!!!");
    endtask



    // TEST 3: bird low spawn
    //   spawn_type=2, spawn_h=0 -> y=172 (BIRD_LOW) spawn with lower height but y-coordinate is actually >
    task test_bird_low_spawn();
        $display("\nTEST 3: bird low spawn");
        do_reset();

        do_spawn(TYPE_BIRD, 1'b0);
        $display("  after spawn — obs0: type=%0d  x=%0d  y=%0d",
                 obs0_type, obs0_x, obs0_y);
        $display("                (expect type=2  x=%0d  y=%0d)", SCREEN_W, BIRD_LOW);

        if (obs0_type == TYPE_BIRD && obs0_x == SCREEN_W && obs0_y == BIRD_LOW)
            $display("  PASS!");
        else
            $display("  FAIL!!");
    endtask



    // TEST 4: bird high spawn
    //   spawn_type=2, spawn_h=1 -> y=150 (BIRD_HIGH)
    task test_bird_high_spawn();
        $display("\nTEST 4: bird high spawn");
        do_reset();

        do_spawn(TYPE_BIRD, 1'b1);
        $display("  after spawn — obs0: type=%0d  x=%0d  y=%0d",
                 obs0_type, obs0_x, obs0_y);
        $display("                (expect type=2  x=%0d  y=%0d)", SCREEN_W, BIRD_HIGH);

        if (obs0_type == TYPE_BIRD && obs0_x == SCREEN_W && obs0_y == BIRD_HIGH)
            $display("  PASS!");
        else
            $display("  FAIL!!!");
    endtask


    // TEST 5: obstacle scrolling
    //   obs0_x should decrement by 1 each tick after spawn
    task test_obstacle_scroll();
        logic [8:0] expected_x;
        $display("\nTEST 5: obstacle scrolling");
        do_reset();

        do_spawn(TYPE_CACTUS, 1'b0);
        expected_x = SCREEN_W;

        repeat (5) begin
            do_tick();
            expected_x = expected_x - 9'd1;
            $display("  tick — obs0_x=%0d  (expect %0d)", obs0_x, expected_x);
        end

        if (obs0_x == expected_x)
            $display("  PASS: scrolled correctly to x=%0d", obs0_x);
        else
            $display("  FAIL: expected x=%0d, got %0d", expected_x, obs0_x);
    endtask



    // TEST 6: obstacle despawn
    //   spawn a cactus, scroll it all the way to x=0 -> type goes to NONE
    task test_obstacle_despawn();
        $display("\nTEST 6: obstacle despawn");
        do_reset();

        do_spawn(TYPE_CACTUS, 1'b0);
        $display("  spawned at x=%0d, scrolling to despawn...", obs0_x);

        // scroll until despawned (320 ticks)
        while (obs0_type != TYPE_NONE) begin
            do_tick();
        end

        $display("  despawned — obs0: type=%0d  x=%0d  (expect type=0)", obs0_type, obs0_x);

        if (obs0_type == TYPE_NONE)
            $display("  PASS");
        else
            $display("  FAIL");
    endtask



    // TEST 7: two obstacles at once
    //   spawn a cactus, then spawn a bird
    task test_two_obstacles();
        $display("\nTEST 7: two obstacles at once");
        do_reset();

        // spawn first obstacle into obs0
        do_spawn(TYPE_CACTUS, 1'b0);
        $display("  after 1st spawn — obs0: type=%0d x=%0d y=%0d",
                 obs0_type, obs0_x, obs0_y);

        // tick a few times so obs0 has scrolled left
        repeat (5) do_tick();

        // spawn second obstacle into obs1
        do_spawn(TYPE_BIRD, 1'b1);
        $display("  after 2nd spawn — obs0: type=%0d x=%0d  obs1: type=%0d x=%0d",
                 obs0_type, obs0_x, obs1_type, obs1_x);
        $display("                    (expect obs0=cactus, obs1=bird at x=%0d)", SCREEN_W);

        if (obs0_type == TYPE_CACTUS && obs1_type == TYPE_BIRD && obs1_x == SCREEN_W)
            $display("  PASS");
        else
            $display("  FAIL");
    endtask


    // running tasks
    initial begin
       reset = 1; game_tick = 0;
		 spawn_en = 0; spawn_type = 0; spawn_h = 0;
		 do_tick();     
		 reset = 0;
		 do_tick();  
		 
        test_ground_scroll();
        test_cactus_spawn();
        test_bird_low_spawn();
        test_bird_high_spawn();
        test_obstacle_scroll();
        test_obstacle_despawn();
        test_two_obstacles();

        $display("TESTING COMPLETE!");
        $stop();
    end

endmodule // obstacle_controller_tb
