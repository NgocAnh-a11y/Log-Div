module div_data #(parameter int IW = 32,
						parameter int INT = 12
						)( input logic clk,
						   input logic rstn,
							input logic signed [IW - 1:0] F1_i,
							input logic signed [IW - 1:0] F2_i,
							input logic f1_ld,
							input logic f2_ld,
							input logic s1_ld,
							input logic s2_ld,
							input logic s_ld,
							input logic u1_ld,
							input logic u2_ld,
							input logic u_ld,
							input logic d_ld,
							input logic k_ld,
							input logic r_ld,
							input logic result_ld,
							output logic f1_neg_0,
							output logic f2_neg_0,
							output logic d_gt_0,
							output logic signed [IW - 1:0] result);

// Number lower than 0
logic signed [IW - 1:0] F1;
logic signed [IW - 1:0] F2; // Q12.20
always_ff @(posedge clk or negedge rstn) begin
    if (!rstn) begin
	    F1 <= 0;
		 F2 <= 0;
	 end else begin
	    if (f1_ld) begin
		    F1 <= F1_i >>> 6;
		 end
		 if (f2_ld) begin
		    F2 <= F2_i >>> 6;
		 end
	 end
end

// Comparator
logic signed [IW - 1:0] f_norm1;
logic signed [IW - 1:0] f_norm2;
always_comb begin
    f1_neg_0 = 0;
	 f2_neg_0 = 0;
	 
	 f_norm1 = F1;
	 f_norm2 = F2;
	 if (F2 == 32'b0) begin
	    f2_neg_0 = 1;
	 end else if (F1 == 32'b0) begin
	    f1_neg_0 = 1;
		 f2_neg_0 = 0;
	 end
end

logic [IW - 1:0] p1, p2;
logic valid_final1, valid_final2;
find_mbs #(.IW(IW)
          ) u_find_mbs1 ( .f_norm(f_norm1),
								  .p(p1),
								  .valid_final(valid_final1));
								 
find_mbs #(.IW(IW)
          ) u_find_mbs2 ( .f_norm(f_norm2),
								  .p(p2),
								  .valid_final(valid_final2));

// Caculate F2
logic [IW - 1:0] f2_m;
logic signed [IW - 1:0] f2_s;
logic [IW - 1:0] f2_u;
always_comb begin
    f2_m = f_norm2 <<< (IW - INT - p2);
	 f2_s = p2 - (IW - INT);
	 f2_u = f2_m - 32'h00100000;
end

logic [IW - 1:0] u2;
logic signed [IW - 1:0] s2;
// Register u2
always_ff @(posedge clk or negedge rstn) begin
    if (!rstn) begin
	    u2 <= 0;
		 s2 <= 0;
	 end else begin
	    if (u2_ld) begin
	       u2 <= f2_u;
	    end 
	    if (s2_ld) begin
	       s2 <= f2_s;
	    end
	 end
end

// Caculate F1
logic [IW - 1:0] f1_m;
logic signed [IW - 1:0] f1_s;
logic [IW - 1:0] f1_u;
always_comb begin
    f1_m = f_norm1 <<< (IW - INT - p1);
	 f1_s = p1 - (IW - INT);
	 f1_u = f1_m - 32'h00100000;
end

logic [IW - 1:0] u1;
logic signed [IW - 1:0] s1;
// Register u1, s1
always_ff @(posedge clk or negedge rstn) begin
    if (!rstn) begin
	    u1 <= 0;
		 s1 <= 0;
	 end else begin
	    if (u1_ld) begin
	       u1 <= f1_u;
	    end 
	    if (s1_ld) begin
	       s1 <= f1_s;
	    end
	 end
end

logic signed [IW - 1:0] s;
logic signed [IW - 1:0] u;
always_ff @(posedge clk or negedge rstn) begin
    if (!rstn) begin
	    s <= 0;
		 u <= 0;
	 end else begin
	    if (s_ld) begin
	       s <= s1 - s2;
	    end
	    if (u_ld) begin
	       u <= $signed({1'b0 , u1}) - $signed({1'b0, u2});
	    end
	 end
end

// Error Correction
logic [IW - 1:0] u1_error, u2_error, r_error;
logic [IW - INT - 1:0] r_est;
logic signed [IW - 1:0] u_error;
always_comb begin
    // 0.3125 <= u1 <= 0.65625
    if ((u1 >= 32'd327680) && (u1 <= 32'd688128)) begin
	    u1_error = 32'd86016; // 0.08201125
	 // 0.125 <= u1 <= 0.84375
	 end else if ((u1 >= 32'd131072) && (u1 <= 32'd884736)) begin
	    u1_error = 32'd53248; // 0.05078125
	 end else begin
	    u1_error = 32'd0;
	 end
	
    // 0.3125 <= u2 <= 0.65625
    if ((u2 >= 32'd327680) && (u2 <= 32'd688128)) begin
	    u2_error = 32'd86016; // 0.08201125
	 // 0.125 <= u2 <= 0.84375
	 end else if ((u2 >= 32'd131072) && (u2 <= 32'd884736)) begin
	    u2_error = 32'd53248; // 0.05078125
	 end else begin
	    u2_error = 32'd0;
	 end
	
    r_est = u[19:0] + u1_error[19:0] - u2_error[19:0];
	 // 0.3125 <= r_est <= 0.65625
	 if ((r_est >= 20'd327680) && (r_est <= 20'd688128)) begin
	    r_error = 32'd81920; // 0.078125
	 // 0.125 <= r_est <= 0.84375
	 end else if ((r_est >= 20'd131072) && (r_est <= 20'd884736)) begin
	    r_error = 32'd49152; // 0.046875
	 end else begin
	    r_error = 32'd0;
	 end
	 
	 u_error = u + u1_error - u2_error - r_error;
end

// Register d
logic signed [IW - 1:0] d;
always_ff @(posedge clk or negedge rstn) begin
    if (!rstn) begin
	    d <= 0;
	 end else if (d_ld) begin
	    d <= (s <<< (IW - INT)) + u_error;
	 end
end

always_comb begin
    if (d >= 0) begin
	    d_gt_0 = 1;
	 end else begin
	    d_gt_0 = 0;
	 end
end

// Find k and r
logic signed [INT - 1:0] k;
logic [IW - INT - 1:0] r;
find_int_frac #(.INT(INT),
                .IW(IW)
					 ) u_find ( .clk(clk),
					            .rstn(rstn),
									.d_gt_0(d_gt_0),
									.r_ld(r_ld),
									.k_ld(k_ld),
									.d(d),
									.k(k),
									.r(r));
									
logic signed [IW - 1:0] result_temp;
always_comb begin
    if (f2_neg_0) begin
	    result_temp = 32'dx;
	 end else if (f1_neg_0) begin
	    result_temp = 32'd0;
	 end else begin
	    if (k >= 0) begin
		    result_temp = $signed(32'h00100000 + r) <<< (k);
	    end else begin
	       result_temp = $signed(32'h00100000 + r) >>> (-k);
	    end
	 end
	 
	 if (F1[IW - 1] ^ F2[IW - 1]) begin
	    result_temp = -result_temp;
	 end
end

// Register Result
always_ff @(posedge clk or negedge rstn) begin
    if (!rstn) begin
	    result <= 0;
	 end else if (result_ld) begin
	    result <= result_temp <<< 6;
	 end
end

endmodule
