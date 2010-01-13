module ring_arb
  (
   input        clk,
   input        reset,

   input [`NUM_PORTS-1:0] rarb_req,
   output reg [`NUM_PORTS-1:0] rarb_ack
   );
  integer                      i;
  reg [`NUM_PORTS-1:0]         nxt_rarb_ack;
  reg [$clog2(`NUM_PORTS)-1:0] nxt_ack;
  
  always @*
    begin
      nxt_rarb_ack = rarb_ack;
      nxt_ack = 0;

      if (rarb_req == 0)
        nxt_rarb_ack = 0;
      else if ((rarb_ack == 0) |
          ((rarb_req & rarb_ack) == 0))
        begin
          nxt_ack = 0;
          for (i=`NUM_PORTS; i>0; i=i-1)
            if (rarb_req[i-1])
              nxt_ack = i-1;
          nxt_rarb_ack = 1 << nxt_ack;
        end
    end // always @ *

  always @(posedge clk)
    begin
      if (reset)
        rarb_ack <= #1 0;
      else
        rarb_ack <= #1 nxt_rarb_ack;
    end
       

endmodule // ring_arb
