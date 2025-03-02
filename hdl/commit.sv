module commit
import rv32i_types::*;
(
    input	logic	clk,
	input	logic	rst,
    output  logic   reg_valid,

/*Value from rob, in commit_t struct*/
    input   rob_entry_t    commit_data,
    input   logic   commit_en,

/*Branch flush*/
    output  logic   br_flush,
    output  logic   [31:0]  br_addr,
    output  logic   [63:0]  br_order
);
logic			valid;
logic	[63:0]	order;
logic	[31:0]	inst;
logic	[4:0]	rs1_addr;
logic	[4:0]	rs2_addr;
logic	[31:0]	rs1_data;
logic	[31:0]	rs2_data;
logic	[4:0]	rd_addr;
logic	[31:0]	rd_data;
logic	[31:0]	pc; // pc_rdata
logic	[31:0]	pc_next; // pc_wdata
logic	[31:0]	mem_addr;
logic	[3:0]	mem_rmask;
logic	[3:0]	mem_wmask;
logic	[31:0]	mem_rdata;
logic	[31:0]	mem_wdata;

//branch logic         
logic           br_mispredict;
assign reg_valid = valid;

always_ff @(posedge clk) begin
    valid <= 1'b0;
    if(rst) begin
        valid <= 1'b0;
    end else if(commit_en) begin
        valid <= 1'b1;
        if(br_flush) begin
            valid <= 1'b0;
        end
    end
end

assign br_flush = br_mispredict && valid;


always_comb begin: ROB_Input
    inst = commit_data.inst;
    order = commit_data.order;
    rs1_addr = commit_data.inst[19:15];
	rs2_addr = commit_data.inst[24:20];
    if(inst[6:0] == op_imm) begin //imm instruction should not have rs2
        rs2_addr = '0;
    end else if(inst[6:0] == op_jal)begin
        rs1_addr = '0;
        rs2_addr = '0;
    end else if(inst[6:0] == op_jalr)begin
        rs2_addr = '0;
    end else if(inst[6:0] == op_load)begin
        rs2_addr = '0;
    end else if(inst[6:0] == op_lui)begin
        rs1_addr = '0;
        rs2_addr = '0;
    end else if(inst[6:0] == op_auipc)begin
        rs1_addr = '0;
        rs2_addr = '0;
    end else begin
        rs2_addr = commit_data.inst[24:20];
    end
    rs1_data = commit_data.rs1_data;
    rs2_data = commit_data.rs2_data;
    rd_addr = commit_data.rd_addr;
    rd_data = commit_data.rd_data;
    pc = commit_data.pc;
    pc_next = commit_data.pc_next;
    mem_addr = commit_data.mem_addr;
    mem_rmask = commit_data.mem_rmask;
    mem_wmask = commit_data.mem_wmask;
    mem_rdata = commit_data.mem_rdata;
    mem_wdata = commit_data.mem_wdata;

    br_mispredict = '0;
    br_addr = '0;
    br_order = '0;
    if(inst[6:0] == op_br) begin //branch handling
        if(rd_data != '1) begin//miss
            br_mispredict = '1;
            br_addr = commit_data.pc + 
            {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
            br_order = commit_data.order;
            pc_next = br_addr;
            if(rd_data == 32'h0) begin //suppose to branch,but did not
                br_addr = commit_data.pc + 
                {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
                pc_next = br_addr;
            end else if(rd_data == 32'h00000001) begin //suppose to not branch
                br_addr = pc + 32'd4;
                pc_next = br_addr;
            end
        end
    end
    if(inst[6:0] == op_jalr) begin
        br_addr = rs1_data + rs2_data;
        pc_next = br_addr;
        br_order = commit_data.order;
        br_mispredict = 1'b1;
    end
end

endmodule
