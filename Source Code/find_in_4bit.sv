module find_in_4bit (input logic [3:0] in,
                     output logic valid,
							output logic [1:0] pos);
									
always_comb begin
    if (in[3] == 1) begin
	    valid = 1;
		 pos = 2'b11;
	 end else if (in[2] == 1) begin
	    valid = 1;
		 pos = 2'b10;
	 end else if (in[1] == 1) begin
	    valid = 1;
		 pos = 2'b01;
	 end else if (in[0] == 1) begin
	    valid = 1;
		 pos = 2'b00;
	 end else begin
	    valid = 0;
		 pos = 2'bx;
	 end
end

endmodule
