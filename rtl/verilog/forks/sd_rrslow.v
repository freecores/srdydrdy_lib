//----------------------------------------------------------------------
//  Srdy/drdy "slow" round-robin arbiter
//
//  Asserts drdy for an input and then moves to the next input.
//
// This component supports multiple round-robin modes:
//
// Mode 0 : Each input gets a single cycle, regardless of data
//          availability.  This mode functions like a TDM
//          demultiplexer.  Output flow control will cause the
//          component to stall, so that inputs do not miss their
//          turn due to flow control.
// Mode 1 : Each input can transmit for as long as it has data.
//          When input deasserts, device will begin to hunt for a
//          new input with data.
// Mode 2 : Continue to accept input until the incoming data
//          matches a particular "end pattern".  The trigger pattern
//          is when (c_data & eod_mask) == eod_pattern.  Once
//          trigger pattern is seen, begin hunting for new input.
//
// Naming convention: c = consumer, p = producer, i = internal interface
//----------------------------------------------------------------------
//  Author: Guy Hutchison
//
// This block is uncopyrighted and released into the public domain.
//----------------------------------------------------------------------

// Clocking statement for synchronous blocks.  Default is for
// posedge clocking and positive async reset
`ifndef SDLIB_CLOCKING 
 `define SDLIB_CLOCKING posedge clk or posedge reset
`endif

// delay unit for nonblocking assigns, default is to #1
`ifndef SDLIB_DELAY 
 `define SDLIB_DELAY #1 
`endif

module sd_rrslow
  #(parameter width=8,
    parameter inputs=2,
    parameter mode=0,
    parameter eod_pattern=0,
    parameter eod_mask=0)
  (
   input               clk,
   input               reset,
  
   input [(width*inputs)-1:0] c_data,
   input [inputs-1:0]      c_srdy,
   output  [inputs-1:0]    c_drdy,

   output reg [width-1:0]  p_data,
   output [inputs-1:0]     p_grant,
   output reg              p_srdy,
   input                   p_drdy
   );
  
  reg [inputs-1:0]    rr_state;
  reg [inputs-1:0]    nxt_rr_state;

  reg [$clog2(inputs)-1:0] data_ind;

  wire [width-1:0]     rr_mux_grid [0:inputs-1];
  reg 		       rr_locked;
  genvar               i;
  integer              j;
  wire                 trig_pattern;

  assign c_drdy = rr_state & {inputs{p_drdy}};
  assign p_grant = rr_state;
  
  generate
    for (i=0; i<inputs; i=i+1)
      begin : grid_assign
        assign rr_mux_grid[i] = c_data >> (i*width);
      end

    if (mode == 2)
      begin : tp_gen
        reg nxt_rr_locked;
        
        assign trig_pattern = (rr_mux_grid[data_ind] & eod_mask) == eod_pattern;
        always @*
          begin
            data_ind = 0;
            for (j=0; j<inputs; j=j+1)
              if (rr_state[j])
                data_ind = j;

            nxt_rr_locked = rr_locked;

            if ((c_srdy & rr_state) & (!rr_locked))
              nxt_rr_locked = 1;
            else if ((c_srdy & rr_state) & p_drdy & trig_pattern )
              nxt_rr_locked = 0;
          end

        always @(`SDLIB_CLOCKING)
          begin
            if (reset)
              rr_locked <= `SDLIB_DELAY 0;
            else
              rr_locked <= `SDLIB_DELAY nxt_rr_locked;
          end
      end // block: tp_gen
    else
      begin : ntp_gen
        assign trig_pattern = 1'b0;
      end
  endgenerate

  always @*
    begin
      p_data = 0;
      p_srdy = 0;
      for (j=0; j<inputs; j=j+1)
        if (rr_state[j])
          begin
            p_data = rr_mux_grid[j];
            p_srdy = c_srdy[j];
          end
    end
  
  always @*
    begin
      if ((mode ==  1) & (c_srdy & rr_state))
        nxt_rr_state = rr_state;
      else if ((mode == 0) & !p_drdy)
        nxt_rr_state = rr_state;
      else if ((mode == 2) & (rr_locked | (c_srdy & rr_state)))
        nxt_rr_state = rr_state;
      else
        nxt_rr_state = { rr_state[0], rr_state[inputs-1:1] };
    end

  always @(`SDLIB_CLOCKING)
    begin
      if (reset)
        rr_state <= `SDLIB_DELAY 1;
      else
        rr_state <= `SDLIB_DELAY nxt_rr_state;
    end

endmodule // sd_rrmux
