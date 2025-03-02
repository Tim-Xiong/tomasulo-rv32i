module rs_mul
import rv32i_types::*;
(
	input	logic	clk,
	input	logic	rst,

/*Operation Bus Inputs*/
	input	logic	operation_bus_valid, //If the decode modules output is valid
	input	logic 	mul_select,
	input   decode_output_t data,	//Data from decode module
	input	logic	[2:0]	rob_dest, //The rob entry of the inst on oper_bus

/*register Inputs*/
	input	logic	[31:0]	reg_data[32], //Data of register
	input	logic			reg_rob_valid[32], //If the dependency is valid
	input	logic	[2:0]	reg_rob[32], //The dependency itself
	input	logic	[$clog2(ROB_DEPTH)-1:0]   rob_reg_addr,

/*ROB Inputs*/
/*Check rob if the data requested was already broadcasted*/
/*Two ports for two possible requests*/
	input	rob_entry_t		rob_data[ROB_DEPTH],
	input	logic			regf_we,
    input   logic [4:0]  rob2reg_addr,      // Address for write operation, this should come from commit stage
    input   logic [31:0]  rob2reg_data,


/*Common Data Bus inputs*/
	input 	logic	cdb_en, //If cdb has valid data
	input 	cdb_t	cdb,	//cdb's data

/*Arith Unit Inputs*/
	input	logic	unit_ready,	//If MU is ready

/*Arith unit outputs*/
	output	rs_mul_output_t	result,	//The result for the rs
	output	logic	rs_result_en,	//If the result is valid

	output	logic	rs_not_full	//1 if rs not full
);
rs_t			slots[4];
logic	[3:0]	busy;
rs_t			input_rs;
rs_t			output_rs;

assign rs_not_full = !(busy[0] & busy[1] & busy[2] & busy[3]);

always_ff @(posedge clk) begin: Input
	rs_result_en <= 1'b0;
	if (rst) begin
		busy <= 4'b0000;
		rs_result_en <= 1'b0;
	end else begin
		if (operation_bus_valid && mul_select) begin
			for(int i = 0; i < 4; i++) begin
				if(busy[i] == 1'b0) begin
					slots[i] <= input_rs;
					busy[i] <= 1'b1;
					break;
				end
			end
		end
		if(cdb_en) begin
			for(int i = 0; i < 4; i++) begin
				/*Check if the rob on cdb matches the one in rs*/
				if(busy[i] && slots[i].rob1_en && slots[i].rob1 == cdb.rob_entry) begin
					slots[i].q1_data <= cdb.rd_data;
					slots[i].rob1_en <= 1'b0;
				end 
				if(busy[i] && slots[i].rob2_en && slots[i].rob2 == cdb.rob_entry) begin
					slots[i].q2_data <= cdb.rd_data;
					slots[i].rob2_en <= 1'b0;
				end
			end
		end
		if (unit_ready) begin
			for(int i = 0; i < 4; i++) begin
				if(slots[i].rob1_en == 1'b0 && slots[i].rob2_en == 1'b0
				&& busy[i] == 1'b1) begin
					output_rs <= slots[i];
					busy[i] <= 1'b0;
					rs_result_en <= 1'b1;
					break;
				end
			end
		end
	end
end

/*This breaks down input from decode to data struct accepted by rs*/
always_comb begin:RS_Input
	//Init
	input_rs.operation = data.operation;
	input_rs.rob1_en = 1'b0;
	input_rs.rob1 = '0;
	input_rs.rob2_en = 1'b0;
	input_rs.rob2 = '0;
	input_rs.q1_data = '0;
	input_rs.q2_data = '0;
	input_rs.rob_dest = rob_dest;

	/*check r1 dependency*/
	if(reg_rob_valid[data.rs1]) begin //check for data dependency
		input_rs.rob1_en = 1'b1;
		input_rs.rob1 = reg_rob[data.rs1];
		if(cdb_en && cdb.rob_entry == input_rs.rob1) begin //The data is in cdb
			input_rs.q1_data = cdb.rd_data;
			input_rs.rob1_en = 1'b0;
		end
		if(rob_data[input_rs.rob1].ready) begin
			input_rs.q1_data = rob_data[input_rs.rob1].rd_data;
			input_rs.rob1_en = 1'b0;
		end
		if(regf_we && input_rs.rob1 == rob_reg_addr && 
		data.rs1 == rob2reg_addr) begin //data about to write to register
			input_rs.q1_data = rob2reg_data;
			input_rs.rob1_en = 1'b0;
		end
	end else begin //data dependency does not exist. Use register value
		input_rs.q1_data = reg_data[data.rs1];
	end

	/*check r2 dependency*/
	if(data.r2_select == immediate) begin //immediate number used
		input_rs.q2_data = data.imm2;
	end else if(reg_rob_valid[data.rs2]) begin //check for data dependency
		input_rs.rob2_en = 1'b1;
		input_rs.rob2 = reg_rob[data.rs2];
		if(cdb_en && cdb.rob_entry == input_rs.rob2) begin //The data is in cdb
			input_rs.q2_data = cdb.rd_data;
			input_rs.rob2_en = 1'b0;
		end
		if(rob_data[input_rs.rob2].ready) begin
			input_rs.q2_data = rob_data[input_rs.rob2].rd_data;
			input_rs.rob2_en = 1'b0;
		end
		if(regf_we && input_rs.rob2 == rob_reg_addr && 
		data.rs2 == rob2reg_addr) begin //data about to write to register
			input_rs.q2_data = rob2reg_data;
			input_rs.rob2_en = 1'b0;
		end
	end else begin //data dependency does not exist. Use register value
		input_rs.q2_data = reg_data[data.rs2];
	end
end

/*This breaks down output from rs to data struct accepted by arith units*/
always_comb begin:RS_Output
	result.operation = output_rs.operation;
	result.q1_data = output_rs.q1_data;
	result.q2_data = output_rs.q2_data;
	result.rob_dest = output_rs.rob_dest;
end

endmodule
