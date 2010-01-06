// Inputs are ri (Ring In), ro (Ring Out),
// fli (FIB lookup in), prx (port in/RX), and ptx (port out/TX)

module port_ring_tap
  #(parameter rdp_sz = 64,
    parameter portnum = 0)
  (
   input         clk,
   input         reset,

   input         ri_srdy,
   output        ri_drdy,
   input [rdp_sz-1:0] ri_data,
   
   input         prx_srdy,
   output        prx_drdy,
   input [rdp_sz-1:0] prx_data,

   output        ro_srdy,
   input         ro_drdy,
   output [rdp_sz-1:0] ro_data,
   
   output        ptx_srdy,
   input         ptx_drdy,
   output [rdp_sz-1:0] ptx_data,

   input         fli_srdy,
   output        fli_drdy,
   input [`NUM_PORTS-1:0] fli_data
   );

  /*AUTOWIRE*/
  
  /* sd_input AUTO_TEMPLATE "tc_\(.*\)"
   (
    .c_\(.*\)     (@_\1[]),
    .ip_\(.*\)    (l@_\1[]),
   );
   */

  sd_input #(rdp_sz) tc_ri
    (/*AUTOINST*/
     // Outputs
     .c_drdy                            (ri_drdy),               // Templated
     .ip_srdy                           (lri_srdy),              // Templated
     .ip_data                           (lri_data[width-1:0]),   // Templated
     // Inputs
     .clk                               (clk),
     .reset                             (reset),
     .c_srdy                            (ri_srdy),               // Templated
     .c_data                            (ri_data[width-1:0]),    // Templated
     .ip_drdy                           (lri_drdy));              // Templated
  
  sd_input #(rdp_sz) tc_prx
    (/*AUTOINST*/
     // Outputs
     .c_drdy                            (prx_drdy),              // Templated
     .ip_srdy                           (lprx_srdy),             // Templated
     .ip_data                           (lprx_data[width-1:0]),  // Templated
     // Inputs
     .clk                               (clk),
     .reset                             (reset),
     .c_srdy                            (prx_srdy),              // Templated
     .c_data                            (prx_data[width-1:0]),   // Templated
     .ip_drdy                           (lprx_drdy));             // Templated
  
  sd_input #(`NUM_PORTS) tc_fli
    (/*AUTOINST*/
     // Outputs
     .c_drdy                            (fli_drdy),              // Templated
     .ip_srdy                           (lfli_srdy),             // Templated
     .ip_data                           (lfli_data[width-1:0]),  // Templated
     // Inputs
     .clk                               (clk),
     .reset                             (reset),
     .c_srdy                            (fli_srdy),              // Templated
     .c_data                            (fli_data[width-1:0]),   // Templated
     .ip_drdy                           (lfli_drdy));             // Templated

  /* sd_output AUTO_TEMPLATE "tc_\(.*\)"
   (
    .ic_\(.*\)    (l@_\1[]),
    .p_\(.*\)     (@_\1[]),
   );
   */

  sd_output #(rdp_sz) tc_ptx
    (/*AUTOINST*/
     // Outputs
     .ic_drdy                           (lptx_drdy),             // Templated
     .p_srdy                            (ptx_srdy),              // Templated
     .p_data                            (ptx_data[width-1:0]),   // Templated
     // Inputs
     .clk                               (clk),
     .reset                             (reset),
     .ic_srdy                           (lptx_srdy),             // Templated
     .ic_data                           (lptx_data[width-1:0]),  // Templated
     .p_drdy                            (ptx_drdy));              // Templated

  sd_output #(rdp_sz) tc_ro
    (/*AUTOINST*/
     // Outputs
     .ic_drdy                           (lro_drdy),              // Templated
     .p_srdy                            (ro_srdy),               // Templated
     .p_data                            (ro_data[width-1:0]),    // Templated
     // Inputs
     .clk                               (clk),
     .reset                             (reset),
     .ic_srdy                           (lro_srdy),              // Templated
     .ic_data                           (lro_data[width-1:0]),   // Templated
     .p_drdy                            (ro_drdy));               // Templated

endmodule // port_ring_tap
// Local Variables:
// verilog-library-directories:("." "../../../rtl/verilog/closure" "../../../rtl/verilog/memory" "../../../rtl/verilog/forks")
// End:  
