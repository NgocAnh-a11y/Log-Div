module div #(parameter int IW = 32,
				 parameter int INT = 12
				)( input logic clk,
			      input logic rstn,
					input logic signed [IW - 1:0] F1, F2,
				   input logic start,
				   output logic valid_value,
				   output logic done,
				   output logic signed [IW - 1:0] result);

logic f1_neg_0, f2_neg_0;
logic d_gt_0;

logic f1_ld, f2_ld;
logic u1_ld, s1_ld;
logic u2_ld, s2_ld;
logic s_ld, u_ld;
logic d_ld, k_ld, r_ld;
logic result_ld;

div_fsm u_div_fsm ( .clk(clk),
                    .rstn(rstn),
			           .start(start),
			           .d_gt_0(d_gt_0),
						  .f1_neg_0(f1_neg_0),
						  .f2_neg_0(f2_neg_0),
						  .s1_ld(s1_ld),
						  .s2_ld(s2_ld),
						  .s_ld(s_ld),
						  .u1_ld(u1_ld),
						  .u2_ld(u2_ld),
						  .u_ld(u_ld),
			           .done(done),
			           .valid_value(valid_value),
			           .result_ld(result_ld),
			           .d_ld(d_ld),
			           .k_ld(k_ld),
			           .r_ld(r_ld),
			           .f2_ld(f2_ld),
			           .f1_ld(f1_ld));
			 
div_data #(.IW(IW),
			  .INT(INT)
			 ) u_div_data ( .clk(clk),
							    .rstn(rstn),
								 .F1_i(F1),
								 .F2_i(F2),
								 .f1_ld(f1_ld),
								 .f2_ld(f2_ld),
								 .s1_ld(s1_ld),
								 .s2_ld(s2_ld),
								 .s_ld(s_ld),
								 .u1_ld(u1_ld),
								 .u2_ld(u2_ld),
								 .u_ld(u_ld),
								 .d_ld(d_ld),
								 .k_ld(k_ld),
								 .r_ld(r_ld),
								 .result_ld(result_ld),
								 .f1_neg_0(f1_neg_0),
								 .f2_neg_0(f2_neg_0),
								 .d_gt_0(d_gt_0),
								 .result(result));
								 
endmodule
