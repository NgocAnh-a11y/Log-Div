//module find_mbs #(parameter int IW = 32
//                 )( input logic clk,
//					     input logic rstn,
//						  input logic i_sel,
//						  input logic i_ld,
//						  input logic p_ld,
//						  input logic [IW - 1:0] f_norm,
//						  output logic find_p,
//						  output logic [IW - 1:0] p);
//
//
//logic [IW - 1:0] i_next; // output register i
//logic [IW - 1:0] i; // input register i
//
//// Mux select i
//always_comb begin
//    if (find_p) begin
//	    i_next = i;
//	 end else if (i_sel == 0) begin
//	    i_next = IW - 1;
//	 end else begin
//	    i_next = i - 1;
//	 end
//end
//
//// Register i
//always_ff @(posedge clk or negedge rstn) begin
//    if (!rstn) begin
//	    i <= 0;
//	 end else if (i_ld) begin
//	    i <= i_next;
//	 end
//end
//
//logic f_norm_i;
//
//// Register p
//always_ff @(posedge clk or negedge rstn) begin
//    if (!rstn) begin
//	    p <= 0;
//	 end else if (p_ld) begin
//	    p <= i;
//	 end
//end
//
//assign f_norm_i = f_norm[i];
//assign find_p = (f_norm_i == 1) ? 1 : 0;
//
//endmodule

module find_mbs #(parameter int IW = 32
                 )(input logic [IW - 1:0] f_norm,
                   output logic [IW - 1:0] p,
					    output logic valid_final);
					  
logic [7:0] valid_bus;
logic [1:0] pos_bus [7:0];

logic [2:0] cluster_sel;

logic [1:0] pos_final;
find_in_4bit u_find7 ( .in(f_norm[IW - 1: IW - 4]),
                       .valid(valid_bus[7]),
							  .pos(pos_bus[7]));
							  
find_in_4bit u_find6 ( .in(f_norm[IW - 4 - 1: IW - 8]),
                       .valid(valid_bus[6]),
							  .pos(pos_bus[6]));
							  
find_in_4bit u_find5 ( .in(f_norm[IW - 8 - 1: IW - 12]),
                       .valid(valid_bus[5]),
							  .pos(pos_bus[5]));
							  
find_in_4bit u_find4 ( .in(f_norm[IW - 12 - 1: IW - 16]),
                       .valid(valid_bus[4]),
							  .pos(pos_bus[4]));
							  
find_in_4bit u_find3 ( .in(f_norm[IW - 16 - 1: IW - 20]),
                       .valid(valid_bus[3]),
							  .pos(pos_bus[3]));
							  
find_in_4bit u_find2 ( .in(f_norm[IW - 20 - 1: IW - 24]),
                       .valid(valid_bus[2]),
							  .pos(pos_bus[2]));
							  
find_in_4bit u_find1 ( .in(f_norm[IW - 24 - 1: IW - 28]),
                       .valid(valid_bus[1]),
							  .pos(pos_bus[1]));
							  
find_in_4bit u_find0 ( .in(f_norm[IW - 28 - 1: IW - 32]),
                       .valid(valid_bus[0]),
							  .pos(pos_bus[0]));
							  
select_cluster u_sel_cul (.valid(valid_bus),
                          .cluster_sel(cluster_sel),
								  .valid_final(valid_final));
								  
// MUX pos
always_comb begin
    if (cluster_sel == 3'b111) begin
	    pos_final = pos_bus[7];
	 end else if (cluster_sel == 3'b110) begin
	    pos_final = pos_bus[6];
	 end else if (cluster_sel == 3'b101) begin
	    pos_final = pos_bus[5];
	 end else if (cluster_sel == 3'b100) begin
	    pos_final = pos_bus[4];
	 end else if (cluster_sel == 3'b011) begin
	    pos_final = pos_bus[3];
	 end else if (cluster_sel == 3'b010) begin
	    pos_final = pos_bus[2];
	 end else if (cluster_sel == 3'b001) begin
	    pos_final = pos_bus[1];
	 end else if (cluster_sel == 3'b000) begin
	    pos_final = pos_bus[0];
	 end else begin
	    pos_final = 2'bx;
	 end
end

assign p = {cluster_sel, pos_final};

endmodule
