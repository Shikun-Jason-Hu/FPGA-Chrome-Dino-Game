`timescale 1ns/1ps
// this is the testbench for dino_controller, where we test for different scanrios
// of different inputs and transitions to the states as well as seeing if output
// sends correctly.
// 1. running
// 2. jumping
// 3. ducking
// 4. dying
module dino_controller_tb();

    logic       clk, reset, game_tick;
    logic       jump, duck, hit;
    logic [1:0] dino_status;
    logic [1:0] dino_motion;
    logic		 animation_counter;
    logic [9:0] dino_x;
    logic [7:0] dino_y;

    // instantiate dut
    dino_controller dut (.*);

    // 50 MHz clock — 20 ns period
    parameter PERIOD = 20;
    initial clk = 0;
    always #(PERIOD/2) clk = ~clk;

    // local constants matching dino_controller local parameters
    localparam DINO_X   = 10'd50;
    localparam GROUND_Y = 8'd178;
    localparam DUCK_Y   = 8'd187;


    // pulse game_tick once (all always_ff in dino_controller run on posedge game_tick)
	 // instead of posedge clk
    task do_tick();
        @(posedge clk); #1;
        game_tick = 1;
        @(posedge clk); #1;
        game_tick = 0;
    endtask


    // reset
    task do_reset();
		 reset = 1; 
		 jump = 0; 
		 duck = 0; 
		 hit = 0;
		 do_tick();          
		 reset = 0;
		 do_tick();          



		 // TEST 1: running
    //   dino should stay at GROUND_Y with status = RUN (2'd0)
    task test_running();
        $display("\nTEST 1: running");
        jump = 0; duck = 0; hit = 0;
        do_reset();

        repeat (5) begin
            do_tick();
            $display("  tick — x=%0d  y=%0d  status=%0d", dino_x, dino_y, dino_status);
        end

        if (dino_y == GROUND_Y && dino_status == 2'd0)
            $display("  PASS: y=%0d (GROUND_Y), status=RUN", dino_y);
        else
            $display("  FAIL: y=%0d (expected %0d), status=%0d (expected 0)",
                     dino_y, GROUND_Y, dino_status);
    endtask



    // TEST 2: jumping
    //   after jump=1, dino rises above GROUND_Y (technically dino's y < GROUND_Y) then lands back
    task test_jumping();
        $display("\nTEST 2: jumping");
        jump = 0; duck = 0; hit = 0;
        do_reset();

        //  jump
        jump = 1;   do_tick();
        jump = 0;

        $display("  entered jump — status=%0d (expect 1=JUMP)", dino_status);

        // print each tick until landed
        while (dino_status == 2'd1) begin
            $display("  airborne: y=%0d", dino_y);
            do_tick();
        end

        $display("  landed: y=%0d  status=%0d", dino_y, dino_status);

        if (dino_y == GROUND_Y && dino_status == 2'd0)
            $display("  PASS: landed at GROUND_Y=%0d, status=RUN", GROUND_Y);
        else
            $display("  FAIL: y=%0d (expected %0d), status=%0d (expected 0)",
                     dino_y, GROUND_Y, dino_status);
    endtask



    // TEST 3: ducking
    //   duck=1 lowers dino to DUCK_Y; releasing returns to RUN + GROUND_Y
    task test_ducking();
        $display("\nTEST 3: ducking");
        jump = 0; duck = 0; hit = 0;
        do_reset();

        duck = 1;   do_tick();
        $display("  duck held:     y=%0d  status=%0d (expect y=%0d, status=2=DUCK)",
                 dino_y, dino_status, DUCK_Y);

        duck = 0;   do_tick();
        $display("  duck released: y=%0d  status=%0d (expect y=%0d, status=0=RUN)",
                 dino_y, dino_status, GROUND_Y);

        if (dino_y == GROUND_Y && dino_status == 2'd0)
            $display("  PASS");
        else
            $display("  FAIL");
    endtask



    // TEST 4: dying
    //   hit=1 while running. dino freezes; inputs are ignored; reset recovers
    task test_dying();
        logic [7:0] y_snap;
        $display("\nTEST 4: dying");
        jump = 0; duck = 0; hit = 0;
        do_reset();

        // trigger death
        hit = 1;    do_tick();
        hit = 0;
        y_snap = dino_y;
        $display("  hit applied — y=%0d  status=%0d", dino_y, dino_status);

        // try to jump which is ignored in DEAD state
        jump = 1;
        repeat (3) begin
            do_tick();
            $display("  jump ignored? y=%0d  status=%0d", dino_y, dino_status);
        end
        jump = 0;

        if (dino_y == y_snap)
            $display("  PASS: jump ignored while dead");
        else
            $display("  FAIL: y changed to %0d after death", dino_y);

        // recover via reset
        do_reset();
        $display("  after reset — y=%0d  status=%0d (expect y=%0d, status=0)",
                 dino_y, dino_status, GROUND_Y);

        if (dino_y == GROUND_Y && dino_status == 2'd0)
            $display("  PASS: recovered");
        else
            $display("  FAIL: did not recover");
    endtask



    // running tasks (tests)
    initial begin
        reset = 1; 
		  game_tick = 0;
        jump = 0; 
		  duck = 0; 
		  hit = 0;
        @(posedge clk);
        #1 reset = 0;   @(posedge clk);

        test_running();
        test_jumping();
        test_ducking();
        test_dying();

        $display("\n end of test");
        $stop();
    end

endmodule // tb_dino_controller
