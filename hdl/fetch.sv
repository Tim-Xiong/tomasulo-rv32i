module fetch
import rv32i_types::*; 
(
    input   logic   clk,
    input   logic   rst,

    output  logic   [31:0]  imem_addr,
    output  logic   [3:0]   imem_rmask,
    input   logic   [31:0]  imem_rdata,
    input   logic           imem_resp,

    input   logic   full_fq,
    output  fetch_queue_t fetch_data,
    output  logic   pc_write,

	input   logic	jal_ready,
	input	logic	[31:0]	jal_addr,
	input	logic 	[63:0]	jal_order,

	input   logic	br_flush,
	input	logic	[31:0]	br_addr,
	input	logic 	[63:0]	br_order
);

logic	[31:0]	pc,pc_next;
logic 	[63:0]	order;

assign imem_rmask = 4'b1111;
assign pc_write = (imem_resp && !full_fq) || br_flush || jal_ready;
assign fetch_data = {imem_rdata, pc, pc_next, order};

always_comb begin
	if (pc_write) begin
		imem_addr = pc_next;
	end else begin
		imem_addr = pc;
	end
end

always_comb begin
	pc_next = pc + 32'd4;
	if(br_flush) begin
		pc_next = br_addr;
	end else if(jal_ready) begin
		pc_next = jal_addr;
	end
end

always_ff @(posedge clk) begin
	if (rst) begin
		pc <= 32'h60000000;
		order <= 64'd0;
	end else if (pc_write) begin
		pc <= pc_next;
		order <= order + 1;
		if(br_flush) begin
			order <= br_order + 1;
		end else if(jal_ready) begin
			order <= jal_order + 1;
		end
	end
end

endmodule
