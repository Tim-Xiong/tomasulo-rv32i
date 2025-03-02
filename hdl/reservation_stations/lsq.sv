module lsq
import rv32i_types::*;
(
    input	logic	clk,
	input	logic	rst,

/*Operation Bus Inputs*/
	input	logic	operation_bus_valid, //If the decode modules output is valid
    input	logic 	lsq_select,
	input   decode_output_t data,	//Data from decode module
	input	logic	[$clog2(ROB_DEPTH)-1:0]	rob_dest, //The rob entry of the inst on oper_bus

/*register Inputs*/
	input	logic	[31:0]	reg_data[32], //Data of register
	input	logic			reg_rob_valid[32], //If the dependency is valid
	input	logic	[$clog2(ROB_DEPTH)-1:0]	reg_rob[32], //The dependency itself
	input	logic			regf_we,
    input   logic [4:0]  rob2reg_addr,      // Address for write operation, this should come from commit stage
    input   logic [31:0]  rob2reg_data,

/*ROB Inputs*/
/*Check rob if the data requested was already broadcasted*/
/*Two ports for two possible requests*/
	input	rob_entry_t		rob_data[ROB_DEPTH],
    input	logic	[$clog2(ROB_DEPTH)-1:0]   rob_reg_addr,

/*Common Data Bus inputs*/
	input 	logic	cdb_en, //If cdb has valid data
	input 	cdb_t	cdb,	//cdb's data

    input   logic   [31:0]  dmem_rdata,
    input   logic           dmem_resp,
    output  logic   [31:0]  dmem_addr,
    output  logic   [3:0]   dmem_rmask,
    output  logic   [3:0]   dmem_wmask,
    output  logic   [31:0]  dmem_wdata,

    // input   logic   [$clog2(ROB_DEPTH)-1:0]   ls_rob_id, // rob_head
    input   logic           store_on, // rob raise this when store is the oldest
    input   logic           ls_commit, // rob raise this when load/store commit
    output  logic           lsq_avai, // lsq is not full
    output  logic           ls_result_ready,
    output  cdb_t           result
);


lsq_entry_t lsq_data;
lsq_entry_t lsq_input;
logic [2:0] funct3;
logic [6:0] opcode;
logic [31:0] byte_addr;
logic [31:0] i_imm, s_imm;
assign funct3 = lsq_data.inst[14:12];
assign opcode = lsq_data.inst[6:0];
assign i_imm  = {{21{data.inst[31]}}, data.inst[30:20]};
assign s_imm  = {{21{data.inst[31]}}, data.inst[30:25], data.inst[11:7]};
assign byte_addr = lsq_data.base + lsq_data.offset;

always_ff @(posedge clk) begin
    if (rst) begin
        lsq_data <= '0;
        lsq_avai <= '1;
        ls_result_ready <= '0;
    end else begin
        if (operation_bus_valid && lsq_select) begin
            lsq_data <= lsq_input;
            lsq_avai <= '0;
        end
        if (cdb_en) begin
            if (lsq_data.rob1_en && lsq_data.rob1 == cdb.rob_entry) begin
                lsq_data.base <= cdb.rd_data;
                lsq_data.rob1_en <= '0;
            end
            if (lsq_data.rob2_en && lsq_data.rob2 == cdb.rob_entry) begin
                lsq_data.data <= cdb.rd_data;
                lsq_data.rob2_en <= '0;
            end
        end
        if (dmem_resp && !lsq_avai) begin
            ls_result_ready <= '1;
            if (opcode == op_load) begin
                lsq_data.mem_rdata <= dmem_rdata;
                unique case (funct3)
                    lb : lsq_data.rd_data <= {{24{dmem_rdata[7 +8 *byte_addr[1:0]]}}, dmem_rdata[8 *byte_addr[1:0] +: 8 ]};
                    lbu: lsq_data.rd_data <= {{24{1'b0}}                            , dmem_rdata[8 *byte_addr[1:0] +: 8 ]};
                    lh : lsq_data.rd_data <= {{16{dmem_rdata[15+16*byte_addr[1]  ]}}, dmem_rdata[16*byte_addr[1]   +: 16]};
                    lhu: lsq_data.rd_data <= {{16{1'b0}}                            , dmem_rdata[16*byte_addr[1]   +: 16]};
                    lw : lsq_data.rd_data <= dmem_rdata;
                    default: lsq_data.rd_data <= 'x;
                endcase
            end
        end
        if (ls_commit) begin // free lsq entry
            lsq_avai <= '1;
            ls_result_ready <= '0;
        end
        // if all operands are avaliable
        if (lsq_data.rob1_en == '0 && !dmem_resp &&
            lsq_data.rob2_en == '0 && lsq_avai != '1) begin
            lsq_data.mem_addr <= byte_addr;
            case (opcode)
                op_load: begin
                    // start memory operation
                    unique case (funct3)
                        lb, lbu: lsq_data.mem_rmask <= 4'b0001 << byte_addr[1:0];
                        lh, lhu: lsq_data.mem_rmask <= 4'b0011 << byte_addr[1:0];
                        lw:      lsq_data.mem_rmask <= 4'b1111;
                        default: lsq_data.mem_rmask <= '0;
                    endcase
                end
                op_store: begin
                    // do nothing util store become the oldest
                    if (store_on) begin
                        unique case (funct3)
                            sb: lsq_data.mem_wmask <= 4'b0001 << byte_addr[1:0];
                            sh: lsq_data.mem_wmask <= 4'b0011 << byte_addr[1:0];
                            sw: lsq_data.mem_wmask <= 4'b1111;
                            default: lsq_data.mem_wmask <= '0;
                        endcase
                        unique case (funct3)
                            sb: lsq_data.mem_wdata[8 *byte_addr[1:0] +: 8 ] <= lsq_data.data[7 :0];
                            sh: lsq_data.mem_wdata[16*byte_addr[1]   +: 16] <= lsq_data.data[15:0];
                            sw: lsq_data.mem_wdata <= lsq_data.data;
                            default: lsq_data.mem_wdata <= '0;
                        endcase
                    end
                end
            endcase
        end
    end
end


always_comb begin
    lsq_input.inst = data.inst;
    lsq_input.seq = '0;
    lsq_input.offset = '0;
    lsq_input.rob1 = '0;
    lsq_input.base = '0;
    lsq_input.rob1_en = '0;
    lsq_input.rob2 = '0;
    lsq_input.data = '0;
    lsq_input.rob2_en = '0;
    lsq_input.rob_dest = rob_dest;
    lsq_input.rd_data = '0;
    lsq_input.mem_addr = '0;
	lsq_input.mem_rmask = '0;
	lsq_input.mem_wmask = '0;
	lsq_input.mem_rdata = '0;
	lsq_input.mem_wdata = '0;

    if (reg_rob_valid[data.rs1]) begin
        lsq_input.rob1_en = '1;
        lsq_input.rob1 = reg_rob[data.rs1];
        if (cdb_en && cdb.rob_entry == lsq_input.rob1) begin
            lsq_input.base = cdb.rd_data;
            lsq_input.rob1_en = '0;
        end
        if(rob_data[lsq_input.rob1].ready) begin
            lsq_input.base = rob_data[lsq_input.rob1].rd_data;
            lsq_input.rob1_en = '0;
        end
        if(regf_we && lsq_input.rob1 == rob_reg_addr && 
		data.rs1 == rob2reg_addr) begin //data about to write to register
			lsq_input.base = rob2reg_data;
			lsq_input.rob1_en = 1'b0;
		end
    end else begin
        lsq_input.base = reg_data[data.rs1];
    end

	case (lsq_input.inst[6:0])
        op_load: begin
            lsq_input.offset = i_imm;
        end
        op_store: begin
            lsq_input.offset = s_imm;
            if (reg_rob_valid[data.rs2]) begin
                lsq_input.rob2_en = '1;
                lsq_input.rob2 = reg_rob[data.rs2];
                if (cdb_en && cdb.rob_entry == lsq_input.rob2) begin
                    lsq_input.data = cdb.rd_data;
                    lsq_input.rob2_en = '0;
                end
                if (rob_data[lsq_input.rob2].ready) begin
                    lsq_input.data = rob_data[lsq_input.rob2].rd_data;
                    lsq_input.rob2_en = '0;
                end
                if(regf_we && lsq_input.rob2 == rob_reg_addr && 
		        data.rs2 == rob2reg_addr) begin //data about to write to register
			    lsq_input.data = rob2reg_data;
			    lsq_input.rob2_en = 1'b0;
		    end
            end else begin
                lsq_input.data = reg_data[data.rs2];
            end
        end
    endcase
end

logic mem_op_en;
always_comb begin: memory_operation
    mem_op_en = ls_result_ready || lsq_avai;
    dmem_addr = {byte_addr[31:2], 2'b00};
    dmem_wdata = lsq_data.mem_wdata;
    dmem_rmask = mem_op_en ? '0 : lsq_data.mem_rmask;
    dmem_wmask = mem_op_en ? '0 : lsq_data.mem_wmask;
end


always_comb begin: write_to_cdb
    result = '0;
    if (ls_result_ready) begin
        result.rs1_data = lsq_data.base;
        result.rs2_data = lsq_data.data;
        result.rd_data = lsq_data.rd_data;
        result.rob_entry = lsq_data.rob_dest;
        result.mem_addr = lsq_data.mem_addr;
        result.mem_rmask = lsq_data.mem_rmask;
        result.mem_wmask = lsq_data.mem_wmask;
        result.mem_rdata = lsq_data.mem_rdata;
        result.mem_wdata = lsq_data.mem_wdata;
    end
end


endmodule
