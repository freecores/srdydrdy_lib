//----------------------------------------------------------------------
// Srdy/Drdy sequence generator
//
// Simplistic traffic generator for srdy/drdy blocks.  Generates an
// incrementing data sequence.
//
// Naming convention: c = consumer, p = producer, i = internal interface
//----------------------------------------------------------------------
// Author: Guy Hutchison
//
// This block is uncopyrighted and released into the public domain.
//----------------------------------------------------------------------

// delay unit for nonblocking assigns, default is to #1
`ifndef SDLIB_DELAY 
 `define SDLIB_DELAY #1 
`endif

module sd_seq_gen
  #(parameter width=8)
  (input clk,
   input reset,
   output reg     p_srdy,
   input          p_drdy,
   output reg [width-1:0] p_data);

  reg 			  nxt_p_srdy;
  reg [width-1:0] 	  nxt_p_data;

  parameter pat_dep = 8;

  reg [pat_dep-1:0] 	  srdy_pat;
  integer 		  spp, startup;

  initial
    begin
      srdy_pat = {pat_dep{1'b1}};
      spp = 0;
      startup = 0;
    end

  always @*
    begin
      nxt_p_data = p_data;
      nxt_p_srdy = p_srdy;

      if (startup < 10)
	begin
	end
      else if (p_srdy & p_drdy)
	begin
	  if (srdy_pat[spp])
	    begin
	      nxt_p_data = p_data + 1;
	      nxt_p_srdy = 1;
	    end
	  else
	    nxt_p_srdy = 0;
	end
      else if (!p_srdy)
	begin
	  if (srdy_pat[spp])
	    begin
	      nxt_p_data = p_data + 1;
	      nxt_p_srdy = 1;
	    end
	  else
	    nxt_p_srdy = 0;
	end
    end // always @ *

  always @(posedge clk)
    begin
      if ((p_srdy & p_drdy) | !p_srdy)
	spp = (spp + 1) % pat_dep;
    end

  always @(posedge clk)
    begin
      if (reset)
	begin
	  p_srdy <= `SDLIB_DELAY 0;
	  p_data <= `SDLIB_DELAY 0;
	end
      else
	begin
	  p_srdy <= `SDLIB_DELAY nxt_p_srdy;
	  p_data <= `SDLIB_DELAY nxt_p_data;
	  if (startup < 10)
	    startup = startup + 1;
	end
    end

endmodule // sd_seq_gen
