module port_ring_tap_fsm
  #(parameter rdp_sz = 64,
    parameter portnum = 0)
  (
   input               clk,
   input               reset,
   
   output reg               lfli_drdy,
   output reg               lprx_drdy,
   output reg[rdp_sz-1:0]    lptx_data,
   output reg               lptx_srdy,
   output reg               lri_drdy, 
   output reg[rdp_sz-1:0]    lro_data, 
   output reg               lro_srdy, 

   input [rdp_sz-1:0]   lfli_data, 
   input               lfli_srdy, 
   input [rdp_sz-1:0]   lprx_data, 
   input               lprx_srdy, 
   input               lptx_drdy, 
   input [rdp_sz-1:0]   lri_data,  
   input               lri_srdy,  
   input               lro_drdy
   // End of automatics
   );

  reg [6:0]            state, nxt_state;

  wire [`NUM_PORTS-1:0] port_mask;
  reg [`NUM_PORTS-1:0]  pe_vec, nxt_pe_vec;

  assign port_mask = 1 << portnum;

  parameter s_idle = 0,
              s_rcmd = 1,
              s_rfwd = 2,
              s_rcopy = 3,
              s_rsink = 4,
              s_tcmd = 5,
              s_tdata = 6;
  
  always @*
    begin
      lro_data = lri_data;
      
      case (1'b1)
        state[s_idle] :
          begin
            if (lfli_srdy)
              begin
              end
            else if (lri_srdy)
              begin
                if (lri_data[`PRW_DATA] & port_mask)
                  begin
                    // packet is for our port
                    nxt_pe_vec = lri_data[`PRW_DATA] & ~port_mask;

                    // if enable vector is not empty, send the
                    // vector to the next port
                    if ((nxt_pe_vec != 0) & lro_drdy)
                      begin
                        lro_data[`PRW_DATA] = nxt_pe_vec;
                        lro_data[`PRW_PVEC] = 1;
                        lro_srdy = 1;
                        lri_drdy = 1;
                        nxt_state = ns_rcopy;
                      end
                    else
                      begin
                        lri_drdy = 1;
                        nxt_state = ns_rsink;
                      end // else: !if((nxt_pe_vec != 0) & lro_drdy)
                  end // if (lri_data[`PRW_DATA] & port_mask)
                else
                  // packet is not for our port, forward it on the
                  // ring
                  begin
                    if (lro_drdy)
                      begin
                        lri_drdy = 1;
                        lro_srdy = 1;
                        nxt_state = ns_rfwd;
                      end
                  end // else: !if(lri_data[`PRW_DATA] & port_mask)
              end // if (lri_srdy)
          end // case: state[s_idle]

        default : nxt_state = ns_idle;
      endcase // case (1'b1)
    end // always @ *
  
            

endmodule // port_ring_tap_fsm
