module find_int_frac #(parameter int INT = 12,
                       parameter int IW = 32
							  )(input logic clk,
							    input logic rstn,
								 input logic d_gt_0,
                         input logic r_ld,
							    input logic k_ld,
								 input logic [IW - 1:0] d,
							    output logic signed [INT - 1:0] k,
								 output logic [IW - INT - 1:0] r);
								
logic [INT - 1:0] k_mux, k_in, k_abs;
logic [IW - INT - 1:0] r_in, r_mux, r_abs;
logic signed [IW - 1:0] d_abs;

logic r_eq_0;
always_comb begin
    k_in = 0;
	 k_mux = 0;
	 k_abs = 0;
	 r_in = 0;
	 r_mux = 0;
	 r_abs = 0;
	 d_abs = 0;
	 r_eq_0 = 0;
    if (d_gt_0) begin
	    k_in = d[IW - 1:IW - INT];
		 r_in = d[IW - INT - 1:0];
	 end else begin
	    d_abs = -d;
		 k_abs = d_abs[IW - 1:IW - INT];
		 r_abs = d_abs[IW - INT - 1:0];
		 
		 r_eq_0 = (r_abs == 0);
		 
		 if (r_eq_0) begin
		    r_mux = 0;
			 k_mux = -k_abs; // two's complement
		 end else begin
		    r_mux = -r_abs;
			 k_mux = ~k_abs; // negative
		 end
		 
		 k_in = k_mux;
		 r_in = r_mux;
	 end
end

always_ff @(posedge clk or negedge rstn) begin
    if (!rstn) begin
	    k <= 0;
		 r <= 0;
	 end else begin
	    if (k_ld) begin
	       k <= k_in;
	    end 
	    if (r_ld) begin
	       r <= r_in;
	    end
	 end
end

endmodule
