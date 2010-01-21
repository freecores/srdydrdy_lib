// combination refmodel/monitor for scoreboard

module sb_monitor
  #(parameter width=8,
    parameter items=64,
    parameter use_txid=0,
    parameter use_mask=0,
    parameter txid_sz=2,
    parameter asz=$clog2(items))
  (input      clk,
   input      reset,

   input      c_srdy,
   input      c_drdy,
   input      c_req_type, // 0=read, 1=write
   input [txid_sz-1:0] c_txid,
   input [width-1:0] c_mask,
   input [width-1:0] c_data,
   input [asz-1:0]   c_itemid,

   input     p_srdy,
   output reg   p_drdy,
   input  [txid_sz-1:0] p_txid,
   input [width-1:0]   p_data
   );

  
  reg [width-1:0]      sbmem [0:items-1];

  always @(posedge clk)
    begin
      if (c_srdy & c_drdy & (c_req_type == 1))
        begin
          sbmem[c_itemid] <= #20 (sbmem[c_itemid] & ~c_mask) | (c_data & c_mask);
        end

      if (p_srdy & p_drdy)
        begin
          if (p_data != sbmem[p_txid])
            begin
              $display ("%t: ERROR: sb returned %x, expected %x",
                        $time, p_data, sbmem[p_txid]);
            end
        end
    end
  
  initial
    begin
      p_drdy = 1;
    end

endmodule // sb_monitor
