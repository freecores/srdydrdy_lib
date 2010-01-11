module distributor
  #(parameter width=8)
  (input         clk,
   input         reset,

   input         ptx_srdy,
   output        ptx_drdy,
   input [`PFW_SZ-1:0] ptx_data,

   output        p_srdy,
   input         p_drdy,
   output [1:0]  p_code,
   output [7:0]  p_data
   );

  wire [width-1:0]	ic_data;		// From body of template_body_1i1o.v
  wire			ic_drdy;		// From sdout of sd_output.v
  wire			ic_srdy;		// From body of template_body_1i1o.v
  wire [width-1:0]	ip_data;		// From sdin of sd_input.v
  wire			ip_drdy;		// From body of template_body_1i1o.v
  wire			ip_srdy;		// From sdin of sd_input.v
  // End of automatics

  sd_input #(width) sdin
    (/*AUTOINST*/
     // Outputs
     .c_drdy				(c_drdy),
     .ip_srdy				(ip_srdy),
     .ip_data				(ip_data[width-1:0]),
     // Inputs
     .clk				(clk),
     .reset				(reset),
     .c_srdy				(c_srdy),
     .c_data				(c_data[width-1:0]),
     .ip_drdy				(ip_drdy));

  template_body_1i1o #(width) body
    (/*AUTOINST*/
     // Outputs
     .ic_data				(ic_data[width-1:0]),
     .ic_srdy				(ic_srdy),
     .ip_drdy				(ip_drdy),
     // Inputs
     .clk				(clk),
     .reset				(reset),
     .ic_drdy				(ic_drdy),
     .ip_data				(ip_data[width-1:0]),
     .ip_srdy				(ip_srdy));

  sd_output #(width) sdout
    (/*AUTOINST*/
     // Outputs
     .ic_drdy				(ic_drdy),
     .p_srdy				(p_srdy),
     .p_data				(p_data[width-1:0]),
     // Inputs
     .clk				(clk),
     .reset				(reset),
     .ic_srdy				(ic_srdy),
     .ic_data				(ic_data[width-1:0]),
     .p_drdy				(p_drdy));

endmodule // template_1i1o

module template_body_1i1o
  #(parameter width=8)
  (input                  clk,
   input                  reset,
   output reg [width-1:0] ic_data,
   output reg		  ic_srdy,
   output reg		  ip_drdy,
   input		  ic_drdy,
   input [width-1:0]	  ip_data,
   input		  ip_srdy
   );

   always @*
     begin
       ic_data = ip_data;
       if (ip_srdy & ip_drdy)
	 begin
	   ic_srdy = 1;
	   ip_drdy = 1;
	 end
       else
	 begin
	   ic_srdy = 0;
	   ip_drdy = 0;
	 end
     end
   
endmodule // template_body_1i1o

// Local Variables:
// verilog-library-directories:("." "../../../rtl/verilog/closure" "../../../rtl/verilog/memory" "../../../rtl/verilog/forks")
// End:  
