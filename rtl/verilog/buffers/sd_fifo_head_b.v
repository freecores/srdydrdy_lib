//----------------------------------------------------------------------
// Srdy/Drdy FIFO Head "B"
//
// Building block for FIFOs.  The "B" (big) FIFO is design for larger FIFOs
// based around memories, with sizes that may not be a power of 2.
//
// The bound inputs allow multiple FIFO controllers to share a single
// memory.  The enable input is for arbitration between multiple FIFO
// controllers, or between the fifo head and tail controllers on a
// single port memory.
//
// The commit parameter enables write/commit behavior.  This creates
// two write pointers, one which is used for writing to memory and
// a commit pointer which is sent to the tail block.
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

module sd_fifo_head_b
  #(parameter depth=16,
    parameter commit=0,
    parameter asz=$clog2(depth)
  )
  (
   input       clk,
   input       reset,
   input       enable,
   input       c_commit,
   input       c_abort,  // should be asserted when c_srdy == 0
   input       c_srdy,
   output      c_drdy,

   input [asz-1:0]  bound_low,
   input [asz-1:0]  bound_high,

   input [asz-1:0]      rdptr,
   output reg [asz-1:0] cur_wrptr,
   output reg [asz-1:0] com_wrptr,
   output reg         mem_we
   );
  
  reg [asz-1:0]       nxt_wrptr;
  reg [asz-1:0]       wrptr_p1;
  reg 			empty;
  reg                   full, nxt_full;
  reg [asz-1:0]         nxt_com_wrptr;

  assign 		c_drdy = !full & enable;
  
  always @*
    begin
      if (cur_wrptr[asz-1:0] == bound_high)
	begin
	  wrptr_p1[asz-1:0] = bound_low;
	end
      else
        wrptr_p1 = cur_wrptr + 1;
      
      empty = (cur_wrptr == rdptr) & !full;
      nxt_full = ((wrptr_p1 == rdptr) | (full & (cur_wrptr == rdptr)));

      if ((commit == 1) && c_abort)
        begin
          nxt_wrptr = com_wrptr;
        end
      else if (enable & c_srdy & !full)
        begin
          nxt_wrptr = wrptr_p1;
          mem_we = 1;
        end
      else
        begin
	  nxt_wrptr = cur_wrptr;
          mem_we = 0;
        end
    end

  always @(posedge clk)
    begin
      if (reset)
	begin
	  cur_wrptr <= `SDLIB_DELAY bound_low;
          full  <= `SDLIB_DELAY 0;
	end
      else
	begin
	  cur_wrptr <= `SDLIB_DELAY nxt_wrptr;
          full  <= `SDLIB_DELAY nxt_full;
	end // else: !if(reset)
    end // always @ (posedge clk)

  generate 
    if (commit)
      begin
	always @*
	  begin
            if (enable & c_commit & !c_abort & c_srdy & !full)
              nxt_com_wrptr = wrptr_p1;
            else
              nxt_com_wrptr = com_wrptr;
	  end
    
	always @(posedge clk)
	  begin
            if (reset)
              com_wrptr <= `SDLIB_DELAY bound_low;
            else
              com_wrptr <= `SDLIB_DELAY nxt_com_wrptr;
	  end
      end // if (commit)
    else
      begin
	always @*
	  com_wrptr = cur_wrptr;
      end
  endgenerate

endmodule // fifo_head

