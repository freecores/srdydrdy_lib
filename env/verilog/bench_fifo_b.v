`timescale 1ns/1ns

module bench_fifo_b;

  reg clk, reset;

  localparam width = 16, depth=32, asz=$clog2(depth);

  initial clk = 0;
  always #10 clk = ~clk;

  reg gen_commit, gen_abort;
  reg chk_commit, chk_abort;
  /*AUTOWIRE*/
  // Beginning of automatic wires (for undeclared instantiated-module outputs)
  wire [width-1:0]	chk_data;		// From fifo_s of sd_fifo_b.v
  wire			chk_drdy;		// From chk of sd_seq_check.v
  wire			chk_srdy;		// From fifo_s of sd_fifo_b.v
  wire [width-1:0]	gen_data;		// From gen of sd_seq_gen.v
  wire			gen_drdy;		// From fifo_s of sd_fifo_b.v
  wire			gen_srdy;		// From gen of sd_seq_gen.v
  wire [asz:0]		usage;			// From fifo_s of sd_fifo_b.v
  // End of automatics

/* sd_seq_gen AUTO_TEMPLATE
 (
 .p_\(.*\)   (gen_\1[]),
 );
 */
  sd_seq_gen #(width) gen
    (/*AUTOINST*/
     // Outputs
     .p_srdy				(gen_srdy),		 // Templated
     .p_data				(gen_data[width-1:0]),	 // Templated
     // Inputs
     .clk				(clk),
     .reset				(reset),
     .p_drdy				(gen_drdy));		 // Templated

/* sd_seq_check AUTO_TEMPLATE
 (
 .c_\(.*\)   (chk_\1[]),
 );
 */
  sd_seq_check #(width) chk
    (/*AUTOINST*/
     // Outputs
     .c_drdy				(chk_drdy),		 // Templated
     // Inputs
     .clk				(clk),
     .reset				(reset),
     .c_srdy				(chk_srdy),		 // Templated
     .c_data				(chk_data[width-1:0]));	 // Templated

/* sd_fifo_b AUTO_TEMPLATE
 (
     .p_\(.*\)   (chk_\1[]),
     .c_\(.*\)   (gen_\1[]),
 );
 */
  sd_fifo_b #(width, depth, 1, 1) fifo_s
    (/*AUTOINST*/
     // Outputs
     .c_drdy				(gen_drdy),		 // Templated
     .p_srdy				(chk_srdy),		 // Templated
     .p_data				(chk_data[width-1:0]),	 // Templated
     .usage				(usage[asz:0]),
     // Inputs
     .clk				(clk),
     .reset				(reset),
     .c_srdy				(gen_srdy),		 // Templated
     .c_commit				(gen_commit),		 // Templated
     .c_abort				(gen_abort),		 // Templated
     .c_data				(gen_data[width-1:0]),	 // Templated
     .p_drdy				(chk_drdy),		 // Templated
     .p_commit				(chk_commit),		 // Templated
     .p_abort				(chk_abort));		 // Templated

  initial
    begin
      $dumpfile("fifo_b.vcd");
      $dumpvars;
      reset = 1;
      gen.rep_count = 0;
      gen_commit = 0;
      gen_abort  = 0;
      chk_commit = 1;
      chk_abort  = 0;
      #100;
      reset = 0;
      repeat (5) @(posedge clk);

      //test1();
      //test2();
      test3();
    end // initial begin

  // test basic overflow/underflow
  task test1;
    begin
      gen_commit = 1;
      gen.rep_count = 2000;

      // burst normal data for 50 cycles
      repeat (50) @(posedge clk);

      gen.srdy_pat = 8'h5A;
      repeat (20) @(posedge clk);

      chk.drdy_pat = 8'hA5;
      repeat (40) @(posedge clk);

      // check FIFO overflow
      gen.srdy_pat = 8'hFD;
      repeat (100) @(posedge clk);

      // check FIFO underflow
      gen.srdy_pat = 8'h11;
      repeat (100) @(posedge clk);

      #5000;
      $finish;
    end
  endtask // test1

  // test of write commit/abort behavior
  task test2;
    begin
      // first fill up entire FIFO
      gen.send (depth-1);
      #50;

      wait (gen_drdy == 0);
      @(posedge clk);
      gen_abort <= #1 1;

      @(posedge clk);
      gen_abort <= #1 0;
      #5;
      if (gen_drdy !== 1)
	begin
	  $display ("ERROR -- drdy should be asserted on empty FIFO");
	  #100 $finish;
	end
      

      gen.send (depth-2);
      @(posedge clk);
      gen_commit <= 1;
      gen.send (1);
      gen_commit <= 0;

      repeat (depth+10)
	@(posedge clk);

      if (chk.last_seq != (depth*2-2))
	begin
	  $display ("ERROR -- last sequence number incorrect (%x)", chk.last_seq);
	  $finish;
	end
      

      #5000;
      $finish;
    end
  endtask // test2

  // test read/commit behavior
  task test3;
    begin
      // fill up FIFO
      gen_commit <= 1;
      chk_commit <= 0;
      chk_abort  <= 0;

      @(negedge clk);
      chk.drdy_pat = 0;
      chk.c_drdy = 0;
      chk.nxt_c_drdy = 0;

      repeat (10) @(posedge clk);
      gen.send (depth-1);

      // read out contents of FIFO
      chk.drdy_pat = 8'h5A;

      repeat (depth*2+2)
	@(posedge clk);
      chk.drdy_pat = 0;

      // FIFO should be full at this point to write side, and empty to
      // read side
      if (gen_drdy || chk_srdy)
	begin
	  $display ("ERROR -- c_drdy or p_srdy asserted");
	  #100 $finish;
	end
      
      // reset the read pointer and the expected value
      chk.last_seq = 0;
      chk_abort <= #1 1;
      @(posedge clk);
      chk_abort <= #1 0;

      // read out contents of FIFO again
      chk.drdy_pat = 8'hFF;

      @(posedge clk);
      repeat (depth-3) @(posedge clk);
      chk_commit <= #1 1;
      repeat (4) @(posedge clk);
      chk_commit <= #1 0;

      // All data has been committed, so drdy should be asserted
      if (gen_drdy)
	begin
	  $display ("ERROR -- c_drdy not asserted");
	  #100 $finish;
	end
      #500;
      $finish;
      
    end
  endtask

endmodule // bench_fifo_s
// Local Variables:
// verilog-library-directories:("." "../../rtl/verilog/buffers")
// End:
