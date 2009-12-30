//----------------------------------------------------------------------
// Srdy/Drdy FIFO Tail "B"
//
// Building block for FIFOs.  The "B" (big) FIFO is design for larger FIFOs
// based around memories, with sizes that may not be a power of 2.
//
// The bound inputs allow multiple FIFO controllers to share a single
// memory.  The enable input is for arbitration between multiple FIFO
// controllers, or between the fifo head and tail controllers on a
// single port memory.
//
// The commit parameter enables read/commit behavior.  This creates
// two read pointers, one which is used for reading from memory and
// a commit pointer which is sent to the head block.  The abort behavior
// has a 3-cycle performance penalty due to pipeline flush.
//
// The FIFO tail assumes a memory with one-cycle read latency, and
// has output buffering to compensate for this.
//
// Naming convention: c = consumer, p = producer, i = internal interface
//----------------------------------------------------------------------
// Author: Guy Hutchison
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


module sd_fifo_tail_b
  #(parameter width=8,
    parameter depth=16,
    parameter commit=0,
    parameter asz=$clog2(depth))
    (
     input       clk,
     input       reset,
     input       enable,

     input [asz-1:0]      bound_low,
     input [asz-1:0]      bound_high,

     output reg [asz-1:0]   cur_rdptr,
     output reg [asz-1:0]   com_rdptr,
     input  [asz-1:0]       wrptr,
     output reg           mem_re,

     output reg [asz:0]   usage,
     
     output               p_srdy,
     input                p_drdy,
     input                p_commit,
     input                p_abort,
     input [width-1:0]    mem_rd_data,
     output [width-1:0]   p_data
     );

  reg [asz-1:0]           cur_rdptr;
  reg [asz-1:0]           nxt_cur_rdptr;
  reg [asz-1:0]           cur_rdptr_p1;
  reg [asz-1:0] 	  com_rdptr;
  reg 			empty, full;

  reg 			p_srdy;
  reg 			nxt_irdy;

  reg [width-1:0]       hold_a, hold_b;
  reg                   valid_a, valid_b;
  reg                   prev_re;
  reg [asz:0]           tmp_usage;
  reg [asz:0]           fifo_size;

  // Stage 1 -- Read pipeline
  // issue a read if:
  //   1) we are enabled
  //   2) valid_a is 0, OR
  //   3) valid_b is 0, OR
  //   4) valid_a && valid_b && trdy
  always @*
    begin
      
      if (cur_rdptr[asz-1:0] == (bound_high))
	begin
	  cur_rdptr_p1[asz-1:0] = bound_low;
	end
      else
        cur_rdptr_p1 = cur_rdptr + 1;
      
      empty = (wrptr == cur_rdptr);

      if (commit && p_abort)
	begin
	  nxt_cur_rdptr = com_rdptr;
	  mem_re = 0;
	end
      else if (enable & !empty & (!valid_a | (!prev_re & !valid_b) | 
                             (valid_a & valid_b & p_drdy)))
        begin
	  nxt_cur_rdptr = cur_rdptr_p1;
          mem_re = 1;
        end
      else
        begin
	  nxt_cur_rdptr = cur_rdptr;
          mem_re = 0;
        end // else: !if(enable & !empty & (!valid_a | !valid_b |...

      fifo_size = (bound_high - bound_low + 1);
      tmp_usage = wrptr[asz-1:0] - cur_rdptr[asz-1:0];
      if (~tmp_usage[asz])
        usage = tmp_usage[asz-1:0];
      else
        usage = fifo_size - (cur_rdptr[asz-1:0] - wrptr[asz-1:0]);  
    end

  always @(posedge clk)
    begin
      if (reset)
	cur_rdptr <= `SDLIB_DELAY bound_low;
      else 
	cur_rdptr <= `SDLIB_DELAY nxt_cur_rdptr;
    end

  generate
    if (commit == 1)
      begin : gen_s0
	reg [asz-1:0]  rdaddr_s0, rdaddr_a, rdaddr_b;
	reg [asz-1:0]  nxt_com_rdptr;

	always @(posedge clk)
	  begin
	    if (reset)
	      com_rdptr <= `SDLIB_DELAY bound_low;
	    else
	      com_rdptr <= `SDLIB_DELAY nxt_com_rdptr;

	    if (mem_re)
	      rdaddr_s0 <= `SDLIB_DELAY cur_rdptr;
	  end
      end
    else
      begin : gen_ns0
	always @*
	  com_rdptr = cur_rdptr;
      end
  endgenerate

  // Stage 2 -- read buffering
  always @(`SDLIB_CLOCKING)
    begin
      if (reset)
        begin
	  valid_a <= `SDLIB_DELAY 0;
          hold_a  <= `SDLIB_DELAY 0;
          prev_re <= `SDLIB_DELAY 0;
        end
      else 
        begin
	  if (commit && p_abort)
	    prev_re <= `SDLIB_DELAY 0;
	  else
            prev_re <= `SDLIB_DELAY mem_re;

	  if (commit && p_abort)
	    valid_a <= `SDLIB_DELAY 0;
          else if (prev_re)
            begin
	      valid_a <= `SDLIB_DELAY 1;
              hold_a  <= `SDLIB_DELAY mem_rd_data;
            end
          else if (!valid_b | p_drdy)
            valid_a <= `SDLIB_DELAY 0;
        end
    end // always @ (posedge clk or posedge reset)
  
  generate
    if (commit == 1)
      begin : gen_s2
	always @(posedge clk)
	  begin
	    if (prev_re)
	      rdaddr_a <= `SDLIB_DELAY rdaddr_s0;
	  end
      end
  endgenerate

  // Stage 3 -- output irdy/trdy
  always @(`SDLIB_CLOCKING)
    begin
      if (reset)
        begin
	  valid_b <= `SDLIB_DELAY 0;
          hold_b  <= `SDLIB_DELAY 0;
        end
      else 
        begin
	  if (commit && p_abort)
	    valid_b <= `SDLIB_DELAY 0;
          else if (valid_a & (!valid_b | p_drdy))
            begin
	      valid_b <= `SDLIB_DELAY 1;
              hold_b  <= `SDLIB_DELAY hold_a;
            end
          else if (valid_b & p_drdy)
            valid_b <= `SDLIB_DELAY 0;
        end
    end // always @ (posedge clk or posedge reset)

  generate
    if (commit == 1)
      begin : gen_s3
	always @(posedge clk)
	  begin
	    if (valid_a & (!valid_b | p_drdy))
	      rdaddr_b <= `SDLIB_DELAY rdaddr_a;
	  end

	always @*
	  begin
	    if (p_commit)
	      nxt_com_rdptr = rdaddr_b;
	    else
	      nxt_com_rdptr = com_rdptr;
	  end
      end
  endgenerate

  assign p_srdy = valid_b;
  assign p_data = hold_b;
 
endmodule // it_fifo