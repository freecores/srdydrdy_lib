`timescale 1ns/1ps

module env_top;

  reg clk, reset;

  initial
    begin
      clk = 0;
      forever clk = #4 ~clk;
    end

  initial
    begin
      $dumpfile ("env_top.vcd");
      $dumpvars;
      reset = 1;
      #200;
      reset = 0;
      #200;

      fork
	driver0.send_packet (1, 2, 20);
	driver1.send_packet (2, 3, 64);
	driver2.send_packet (3, 4, 64);
	driver3.send_packet (4, 1, 64);
      join

      #500;
      $finish;
    end

  /*AUTOWIRE*/
  // Beginning of automatic wires (for undeclared instantiated-module outputs)
  wire			gmii_rx_clk_0;		// From driver0 of gmii_driver.v
  wire			gmii_rx_clk_1;		// From driver1 of gmii_driver.v
  wire			gmii_rx_clk_2;		// From driver2 of gmii_driver.v
  wire			gmii_rx_clk_3;		// From driver3 of gmii_driver.v
  wire			gmii_rx_dv_0;		// From driver0 of gmii_driver.v
  wire			gmii_rx_dv_1;		// From driver1 of gmii_driver.v
  wire			gmii_rx_dv_2;		// From driver2 of gmii_driver.v
  wire			gmii_rx_dv_3;		// From driver3 of gmii_driver.v
  wire [7:0]		gmii_rxd_0;		// From driver0 of gmii_driver.v
  wire [7:0]		gmii_rxd_1;		// From driver1 of gmii_driver.v
  wire [7:0]		gmii_rxd_2;		// From driver2 of gmii_driver.v
  wire [7:0]		gmii_rxd_3;		// From driver3 of gmii_driver.v
  wire			gmii_tx_dv_0;		// From bridge of bridge_ex1.v
  wire			gmii_tx_dv_1;		// From bridge of bridge_ex1.v
  wire			gmii_tx_dv_2;		// From bridge of bridge_ex1.v
  wire			gmii_tx_dv_3;		// From bridge of bridge_ex1.v
  wire [7:0]		gmii_txd_0;		// From bridge of bridge_ex1.v
  wire [7:0]		gmii_txd_1;		// From bridge of bridge_ex1.v
  wire [7:0]		gmii_txd_2;		// From bridge of bridge_ex1.v
  wire [7:0]		gmii_txd_3;		// From bridge of bridge_ex1.v
  // End of automatics

  /* gmii_driver AUTO_TEMPLATE
   (
     .\(.*\)  (gmii_\1_@[]),
   );
   */
  gmii_driver driver0
    (/*AUTOINST*/
     // Outputs
     .rxd				(gmii_rxd_0[7:0]),	 // Templated
     .rx_dv				(gmii_rx_dv_0),		 // Templated
     .rx_clk				(gmii_rx_clk_0));	 // Templated

  gmii_driver driver1
    (/*AUTOINST*/
     // Outputs
     .rxd				(gmii_rxd_1[7:0]),	 // Templated
     .rx_dv				(gmii_rx_dv_1),		 // Templated
     .rx_clk				(gmii_rx_clk_1));	 // Templated

  gmii_driver driver2
    (/*AUTOINST*/
     // Outputs
     .rxd				(gmii_rxd_2[7:0]),	 // Templated
     .rx_dv				(gmii_rx_dv_2),		 // Templated
     .rx_clk				(gmii_rx_clk_2));	 // Templated

  gmii_driver driver3
    (/*AUTOINST*/
     // Outputs
     .rxd				(gmii_rxd_3[7:0]),	 // Templated
     .rx_dv				(gmii_rx_dv_3),		 // Templated
     .rx_clk				(gmii_rx_clk_3));	 // Templated

  bridge_ex1 bridge
    (/*AUTOINST*/
     // Outputs
     .gmii_tx_dv_0			(gmii_tx_dv_0),
     .gmii_tx_dv_1			(gmii_tx_dv_1),
     .gmii_tx_dv_2			(gmii_tx_dv_2),
     .gmii_tx_dv_3			(gmii_tx_dv_3),
     .gmii_txd_0			(gmii_txd_0[7:0]),
     .gmii_txd_1			(gmii_txd_1[7:0]),
     .gmii_txd_2			(gmii_txd_2[7:0]),
     .gmii_txd_3			(gmii_txd_3[7:0]),
     // Inputs
     .clk				(clk),
     .reset				(reset),
     .gmii_rx_clk_0			(gmii_rx_clk_0),
     .gmii_rx_clk_1			(gmii_rx_clk_1),
     .gmii_rx_clk_2			(gmii_rx_clk_2),
     .gmii_rx_clk_3			(gmii_rx_clk_3),
     .gmii_rx_dv_0			(gmii_rx_dv_0),
     .gmii_rx_dv_1			(gmii_rx_dv_1),
     .gmii_rx_dv_2			(gmii_rx_dv_2),
     .gmii_rx_dv_3			(gmii_rx_dv_3),
     .gmii_rxd_0			(gmii_rxd_0[7:0]),
     .gmii_rxd_1			(gmii_rxd_1[7:0]),
     .gmii_rxd_2			(gmii_rxd_2[7:0]),
     .gmii_rxd_3			(gmii_rxd_3[7:0]));

endmodule // env_top
// Local Variables:
// verilog-library-directories:("." "../rtl")
// End:  