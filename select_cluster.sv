module select_cluster (input logic [7:0] valid,
                       output logic [2:0] cluster_sel,
							  output logic valid_final);
							  
always_comb begin
    if (valid[7]) begin
	    cluster_sel = 3'b111;
		 valid_final = 1;
	 end else if (valid[6]) begin
	    cluster_sel = 3'b110;
		 valid_final = 1;
	 end else if (valid[5]) begin
	    cluster_sel = 3'b101;
		 valid_final = 1;
	 end else if (valid[4]) begin
	    cluster_sel = 3'b100;
		 valid_final = 1;
	 end else if (valid[3]) begin
	    cluster_sel = 3'b011;
		 valid_final = 1;
	 end else if (valid[2]) begin
	    cluster_sel = 3'b010;
		 valid_final = 1;
	 end else if (valid[1]) begin
	    cluster_sel = 3'b001;
		 valid_final = 1;
	 end else if (valid[0]) begin
	    cluster_sel = 3'b000;
		 valid_final = 1;
	 end else begin
	    cluster_sel = 3'bx;
		 valid_final = 0;
	 end
end

endmodule
