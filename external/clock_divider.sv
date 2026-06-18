// divided_clocks[0] = 25MHz, [1] = 12.5Mhz, ... [23] = 3Hz, [24] = 1.5Hz, [25] = 0.75Hz, ...
// HARDWARE ONLY - not to be used in simulation
// [20] = 50MHz/2^21~~ 47Hz
// [19] = 50MHz/2^20 ~~ 95Hz
module clock_divider (clock, divided_clocks);
  input  logic        clock;
  output logic [31:0] divided_clocks = 0;

  always_ff @(posedge clock) begin
    divided_clocks <= divided_clocks + 1;
  end

endmodule  // clock_divider
