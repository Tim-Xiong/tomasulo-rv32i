module decode
import rv32i_types::*;
(
	/*Clock,reset,data input*/
	input	logic	clk,
	input	logic	rst,
	input	logic	data_in_en,
	input	fetch_queue_t data_in,

	/*Reservation station ready logic*/
	input	logic	alu_rs, // 1 if alu rs not full
	input	logic	mem_rs,
	input	logic	mul_rs,
	input	logic	div_rs, 
	input	logic	br_rs, 
	input 	logic 	lsq_avai,
	input 	logic	rob, // 1 if rob not full

	/*Reservation station selection*/
	output	logic	alu_select,
	output	logic	mem_select,
	output	logic	mul_select,
	output	logic	div_select,
	output	logic	br_select,
	output 	logic 	lsq_select,

	/*Data output*/
	output	logic	decode_available,	// 1 when available for decode
	output	logic	decode_output_ready,
	output 	rs_types_t	rs_dest,
	output	decode_output_t  result,

	/*Jump logic*/
	output	logic	jal_ready,
	output	logic	[31:0]	jal_addr,
	output	logic	[63:0]  jal_order
);
/*
	The decode module takes in the instruction to be decoded, and
	outputs the result to both the reservation station and rob. If any
	of the above is full, the instruction will be stalled inside this module.


*/
logic   [2:0]   funct3;
logic   [6:0]   funct7;
logic   [6:0]   opcode;
logic   [31:0]  i_imm;
logic   [31:0]  s_imm;
logic   [31:0]  b_imm;
logic   [31:0]  u_imm;
logic   [31:0]  j_imm;
logic	[4:0]	rs1_addr;
logic	[4:0]	rs2_addr;
logic   [4:0]   rd_addr;

logic	[31:0]	inst;
logic			bp_update;
logic			issue_ready;
bp_t			bp_result;

fetch_queue_t data_reg;

bp bp_i(
	.clk(clk),
	.rst(rst),
	.update(bp_update),
	.bp_prediction(bp_result)
);

assign inst = data_reg.inst;

always_ff @(posedge clk) begin
	if(rst) begin
		data_reg <= '0;
	end else begin
		if(decode_output_ready) begin
			data_reg <= '0;
		end
		if(data_in_en) begin
			data_reg <= data_in;
		end
		if(issue_ready && jal_ready) begin
			data_reg <= '0;
		end
	end
end

always_comb begin:Decode_IO
	alu_select = 1'b0;
	mem_select = 1'b0;
	mul_select = 1'b0;
	div_select = 1'b0;
	br_select = 1'b0;
	lsq_select = 1'b0;
	issue_ready = 1'b0;
	decode_available = 1'b0;
	decode_output_ready = 1'b0;
	unique case(rs_dest)
	alu: begin
		if(alu_rs && rob) begin
			alu_select = 1'b1;
			issue_ready = 1'b1;
			decode_available = 1'b1;
			decode_output_ready = 1'b1;
		end
	end
	mul: begin
		if(mul_rs && rob) begin
			mul_select = 1'b1;
			issue_ready = 1'b1;
			decode_available = 1'b1;
			decode_output_ready = 1'b1;
		end
	end
	mem:begin
		if(mem_rs && rob) begin
			mem_select = 1'b1;
			issue_ready = 1'b1;
			decode_available = 1'b1;
			decode_output_ready = 1'b1;
		end
	end
	div: begin
		if(div_rs && rob) begin
			div_select = 1'b1;
			issue_ready = 1'b1;
			decode_available = 1'b1;
			decode_output_ready = 1'b1;
		end
	end
	branch: begin
		if(br_rs && rob) begin
			br_select = 1'b1;
			issue_ready = 1'b1;
			decode_available = 1'b1;
			decode_output_ready = 1'b1;
		end
	end
	ldst: begin
		if(lsq_avai && rob) begin
			decode_available = 1'b1;
			decode_output_ready = 1'b1;
			lsq_select = 1'b1;
			issue_ready = 1'b1;
		end
	end
	invalid: begin
		decode_available = 1'b1;
		decode_output_ready = 1'b0;
	end
	default: begin
		decode_available = 1'b0;
		decode_output_ready = 1'b0;
	end
	endcase
end


always_comb begin: Decode_Section
	//break the instruction into pieces
	funct3 = inst[14:12];
	funct7 = inst[31:25];
	opcode = inst[6:0];
	i_imm  = {{21{inst[31]}}, inst[30:20]};
	s_imm  = {{21{inst[31]}}, inst[30:25], inst[11:7]};
	b_imm  = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
	u_imm  = {inst[31:12], 12'h000};
	j_imm  = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};
	rs1_addr  = inst[19:15];
	rs2_addr  = inst[24:20];
	rd_addr   = inst[11:7];

	//Initialization of outputs
	result.inst = inst;
	result.rs1 = rs1_addr;
	result.r1_select = register;
	result.rs2 = rs2_addr;
	result.imm2 = '0;
	result.r2_select = register;
	result.operation = reg_add;
	result.rd = (opcode inside {op_store}) ? '0 : rd_addr;
	result.order = data_reg.order;
	result.pc = data_reg.pc;
	result.pc_next = data_reg.pc_next;
	result.bp_prediction = not_taken;
	bp_update = 1'b0;
	rs_dest = invalid;
	jal_ready = 1'b0;
	jal_addr = 'x;
	jal_order = '0;
	unique case (opcode)
	op_lui: begin
		//reservation station dest
		rs_dest = alu;
		//selection for r1 and r2
		result.r1_select = zero;
		result.r2_select = immediate;
		//operation to be performed
		result.operation = lui;
		//value for r2, since immediate used
		result.imm2 = u_imm;
	end
	op_auipc: begin
		rs_dest = alu;
		result.r1_select = pc;
		result.r2_select = immediate;
		result.operation = auipc;
		result.imm2 = u_imm;
	end
	op_jal: begin
		rs_dest = alu;
		result.r1_select = pc;
		result.r2_select = zero;
		result.operation = jal;
		jal_ready = 1'b1;
		jal_addr = result.pc + j_imm;
		jal_order = result.order;
		result.pc_next = jal_addr;
	end
	op_jalr: begin //jalr treated as branch due to data dependency
		rs_dest = branch;
		result.r1_select = register;
		result.r2_select = immediate;
		result.operation = jalr;
		result.imm2 = i_imm;
	end
	op_br: begin
		rs_dest = branch;
		result.rd = '0;
		result.r1_select = register;
		result.r2_select = register;
		bp_update = 1'b1;
		unique case(funct3)
			beq: result.operation = br_beq;
			bne: result.operation = br_bne;
			blt: result.operation = br_blt;
			bge: result.operation = br_bge;
			bltu: result.operation = br_bltu;
			bgeu: result.operation = br_bgeu;
			default: result.operation = br_beq;
		endcase
		result.bp_prediction = bp_result;
		if(bp_result == taken) begin //predict taken,send addr to fetch
			jal_ready = 1'b1;
			jal_addr = result.pc + b_imm;
			jal_order = result.order;
			result.pc_next = jal_addr;
		end
	end
	op_load: begin
		rs_dest = ldst;
	end
	op_store: begin
		rs_dest = ldst;
	end
	//reg-imm instructions
	op_imm: begin
		rs_dest = alu;
		unique case(funct3)
		add: result.operation = imm_addi;
		sll: result.operation = imm_slli;
		slt: result.operation = imm_slti;
		sltu: result.operation = imm_sltiu; 
		axor: result.operation = imm_xori;
		sr: begin
			if(funct7[5]) begin
				result.operation = imm_srai;
			end else begin
				result.operation = imm_srli;
			end
		end
		aor: result.operation = imm_ori;
		aand: result.operation = imm_andi;
		endcase
		result.rs1 = rs1_addr;
		result.imm2 = i_imm;
		result.r2_select = immediate;
	end
	//reg-reg instructions
	op_reg:begin
		rs_dest = alu;
		unique case (funct3)
		add: begin
			if(funct7[5]) begin
				result.operation = reg_sub;
			end else if(funct7[0]) begin
				result.operation = reg_mul;
				rs_dest = mul;
			end else begin
				result.operation = reg_add;
			end
		end
		sll: begin
			if(funct7[0]) begin
				result.operation = reg_mulh;
				rs_dest = mul;
			end else begin
				result.operation = reg_sll;
			end
		end
		slt: begin
			if(funct7[0]) begin
				result.operation = reg_mulsu;
				rs_dest = mul;
			end else begin
				result.operation = reg_slt;
			end
		end
		sltu: begin
			if(funct7[0]) begin
				result.operation = reg_mulhu;
				rs_dest = mul;
			end else begin
				result.operation = reg_sltu;
			end
		end
		axor: result.operation = reg_xor;
		sr: begin
			if(funct7[5]) begin
				result.operation = reg_sra;
			end else begin
				result.operation = reg_srl;
			end
		end
		aor: result.operation = reg_or;
		aand: result.operation = reg_and;
		endcase
		result.rs1 = rs1_addr;
		result.rs2 = rs2_addr;
	end
	default: begin

	end
	endcase
end


endmodule
