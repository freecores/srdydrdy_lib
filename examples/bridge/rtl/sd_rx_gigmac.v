// mock-up of RX portion of gigabit ethernet MAC
// performs packet reception and creates internal
// packet codes, as well as checking CRC on incoming
// packets.

// incoming data is synchronous to "clk", which should
// be the GMII RX clock.  Output data is also synchronous
// to this clock, so needs to go through a sync FIFO.

// If output is not ready while receiving data,
// truncates the packet and makes it an error packet.

module sd_rx_gigmac
  (
   input        clk,
   input        reset,
   input        gmii_rx_dv,
   input [7:0]  gmii_rxd,

   output       rxg_srdy,
   input        rxg_drdy,
   output [1:0] rxg_code,
   output [7:0] rxg_data
   );

  reg 		rxdv1, rxdv2;
  reg [7:0] 	rxd1, rxd2;
  reg [31:0] 	calc_crc, nxt_calc_crc;
  reg [31:0] 	pkt_crc, nxt_pkt_crc;
  reg [3:0] 	valid_bits, nxt_valid_bits;

  reg [5:0] 	state, nxt_state;
  reg 		ic_srdy;
  wire 		ic_drdy;
  reg [1:0] 	ic_code;
  reg [7:0] 	ic_data;

  wire [31:0] 	crc_comp_a, crc_comp_b;

  assign crc_comp_a = { pkt_crc[23:0], rxd2 };
  assign crc_comp_b = fixup_crc (calc_crc);
  localparam	CRC32_POLY = 32'h04C11DB7;

  function [31:0] add_crc32;
    input [7:0] add_byte;
    input [31:0] prev_crc;
    integer 	 b, msb;
    reg [31:0] 	 tmp_crc;
    begin
      tmp_crc = prev_crc;
      for (b = 0; b < 8; b = b + 1) 
	begin
          msb = tmp_crc[31];
          tmp_crc = tmp_crc << 1;
          if (msb != add_byte[b]) 
	    begin
              tmp_crc = tmp_crc ^ CRC32_POLY;
              tmp_crc[0] = 1;
            end
	end
      add_crc32 = tmp_crc;
    end
  endfunction // for

  function [31:0] fixup_crc;
    input [31:0] calc_crc;
    reg [31:0] 	 temp;
    integer 	 b;
    begin
      // Mirror:
      for (b = 0; b < 32; b = b + 1)
         temp[31-b] = calc_crc[b];
         
      // Swap and Complement:
      fixup_crc = ~{temp[7:0], temp[15:8], temp[23:16], temp[31:24]};
    end
  endfunction // for
      

/* -----\/----- EXCLUDED -----\/-----
  // Copied from: http://www.mindspring.com/~tcoonan/gencrc.v
  // 
  // Generate a (DOCSIS) CRC32.
  //
  // Uses the GLOBAL variables:
  //
  //    Globals referenced:
  //       parameter	CRC32_POLY = 32'h04C11DB7;
  //       reg [ 7:0]	crc32_packet[0:255];
  //       integer	crc32_length;
  //
  //    Globals modified:
  //       reg [31:0]	crc32_result;
  //
task gencrc32;
   integer	byte, bit;
   reg		msb;
   reg [7:0]	current_byte;
   reg [31:0]	temp;
   begin
      crc32_result = 32'hffffffff;
      for (byte = 0; byte < crc32_length; byte = byte + 1) begin
         current_byte = crc32_packet[byte];
         for (bit = 0; bit < 8; bit = bit + 1) begin
            msb = crc32_result[31];
            crc32_result = crc32_result << 1;
            if (msb != current_byte[bit]) begin
               crc32_result = crc32_result ^ CRC32_POLY;
               crc32_result[0] = 1;
            end
         end
      end
      
      // Last step is to "mirror" every bit, swap the 4 bytes, and then complement each bit.
      //
      // Mirror:
      for (bit = 0; bit < 32; bit = bit + 1)
         temp[31-bit] = crc32_result[bit];
         
      // Swap and Complement:
      crc32_result = ~{temp[7:0], temp[15:8], temp[23:16], temp[31:24]};
   end
endtask
 -----/\----- EXCLUDED -----/\----- */

  always @(posedge clk)
    begin
      if (reset)
	begin
	  rxd1  <= #1 0;
	  rxdv1 <= #1 0;
	  rxd2  <= #1 0;
	  rxdv2 <= #1 0;
	end
      else
	begin
	  rxd1  <= #1 gmii_rxd;
	  rxdv1 <= #1 gmii_rx_dv;
	  rxd2  <= #1 rxd1;
	  rxdv2 <= #1 rxdv1;
	end
    end // always @ (posedge clk)

  localparam s_idle = 0, s_preamble = 1, s_sop = 2, s_payload = 3, s_trunc = 4, s_sink = 5;
  localparam ns_idle = 1, ns_preamble = 2, ns_sop = 4, ns_payload = 8, ns_trunc = 16, ns_sink = 32;

  always @*
    begin
      nxt_calc_crc = calc_crc;
      ic_srdy = 0;
      ic_code = `PCC_DATA;
      ic_data = 0;
      nxt_valid_bits = valid_bits;

      case (1'b1)
	state[s_idle] :
	  begin
	    nxt_calc_crc = {32{1'b1}};
	    nxt_pkt_crc  = 0;
	    nxt_valid_bits = 0;
	    if (rxdv2 & (rxd2 == `GMII_SFD))
	      begin
		nxt_state = ns_sop;
	      end
	    else if (rxdv2)
	      begin
		nxt_state = ns_preamble;
	      end
	  end // case: state[s_idle]
	
	state[s_preamble]:
	  begin
	    if (!rxdv2)
	      nxt_state = ns_idle;
	    else if (rxd2 == `GMII_SFD)
	      nxt_state = ns_sop;
	  end

	state[s_sop] :
	  begin
	    if (!rxdv2)
	      begin
		nxt_state = ns_idle;
	      end
	    else if (!ic_drdy)
	      nxt_state = ns_sink;
	    else
	      begin
		ic_srdy = 1;
		ic_code = `PCC_SOP;
		ic_data = rxd2;
		nxt_state = ns_payload;
		nxt_pkt_crc = { 24'h0, gmii_rxd };
		nxt_valid_bits = 4'b0001;
		//nxt_calc_crc = add_crc32 (gmii_rxd, calc_crc);
	      end
	  end // case: state[ns_payload]

	state[s_payload] :
	  begin
	    if (!ic_drdy)
	      nxt_state = ns_trunc;
	    else if (!rxdv1)
	      begin
		nxt_state = ns_idle;
		ic_srdy = 1;
		ic_data = rxd2;
		//if ( { pkt_crc[23:0], rxd2 } == add_crc32 (rxd2, calc_crc))
                `ifdef RX_CHECK_CRC
		if ({ pkt_crc[23:0], rxd2 } == fixup_crc (calc_crc))
		  ic_code = `PCC_EOP;
		else
		  ic_code = `PCC_BADEOP;
                `else
		ic_code = `PCC_EOP;
                `endif
	      end
	    else
	      begin
		ic_srdy = 1;
		ic_code = `PCC_DATA;
		ic_data = rxd2;
		nxt_pkt_crc = { pkt_crc[23:0], rxd2 };
		nxt_valid_bits = { valid_bits[2:0], 1'b1 };
		if (valid_bits[2])
		  nxt_calc_crc = add_crc32 (pkt_crc[23:16], calc_crc);
	      end // else: !if(!rxdv1)
	  end // case: state[ns_payload]

	state[s_trunc] :
	  begin
	    ic_srdy = 1;
	    ic_code = `PCC_BADEOP;
	    ic_data = 0;
	    if (ic_drdy)
	      nxt_state = ns_sink;
	  end

	state[s_sink] :
	  begin
	    if (!rxdv2)
	      nxt_state = ns_idle;
	  end

	default : nxt_state = ns_idle;
      endcase // case (1'b1)	
    end // always @ *

  always @(posedge clk)
    begin
      if (reset)
	begin
	  state <= #1 1;
	  /*AUTORESET*/
	  // Beginning of autoreset for uninitialized flops
	  calc_crc <= 32'h0;
	  pkt_crc <= 32'h0;
	  valid_bits <= 4'h0;
	  // End of automatics
	end
      else
	begin
	  calc_crc <= #1 nxt_calc_crc;
	  pkt_crc  <= #1 nxt_pkt_crc;
	  state    <= #1 nxt_state;
	  valid_bits <= #1 nxt_valid_bits;
	end // else: !if(reset)
    end // always @ (posedge clk)

  sd_output #(8+2) out_hold
    (.clk (clk), .reset (reset),
     .ic_srdy (ic_srdy),
     .ic_drdy (ic_drdy),
     .ic_data ({ic_code,ic_data}),
     .p_srdy  (rxg_srdy),
     .p_drdy  (rxg_drdy),
     .p_data  ({rxg_code, rxg_data}));

endmodule // sd_rx_gigmac
