
module xbar # (
	parameter DATA_TYPE = 16,
	parameter NUM_PES = 64,
	parameter INPUT_BW = 64,
	parameter LOG2_PES = 6) (
	clk,
	rst,
	i_data_bus, // input data bus
	i_mux_bus, // mux select control bus
	o_dist_bus // output bus to the multipliers
);

	input clk;
	input rst;
	input [INPUT_BW*DATA_TYPE-1 : 0] i_data_bus;
	input [LOG2_PES * NUM_PES -1 : 0] i_mux_bus;
	
	output reg [NUM_PES * DATA_TYPE -1 : 0] o_dist_bus;
	
	wire [NUM_PES * DATA_TYPE -1 : 0] w_dist_bus;
	
	for (i=0; i < NUM_PES; i=i+1) begin : gen_out
		mux # (
			.DATA_TYPE(DATA_TYPE),
			.INPUT_BW(INPUT_BW),
			.SEL_SIZE(LOG2_PES)) my_mux (
			.clk(clk),
			.rst(rst),
			.i_data_bus(i_data_bus),
			.i_mux_sel(i_mux_bus[i*LOG2_PES+:LOG2_PES]),
			.o_dist(w_dist_bus[i*DATA_TYPE+:DATA_TYPE])
		);
	end
	
	always @ (posedge clk) begin
		o_dist_bus = w_dist_bus;
	end
	
endmodule
