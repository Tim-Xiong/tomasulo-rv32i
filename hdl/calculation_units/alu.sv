module alu
import rv32i_types::*;
(
    input   logic           clk,
    input   logic           rst,
    input   rs_alu_output_t     data,
    input   logic           cdb_ready,
    input   logic           rs_alu_start,

    output  logic           alu_ready,
    output  logic           alu_result_valid,
    output  cdb_t           result
);
logic signed   [31:0] as;
logic signed   [31:0] bs;
logic unsigned [31:0] au;
logic unsigned [31:0] bu;
logic          [31:0] f;

assign as =   signed'(data.q1_data);
assign bs =   signed'(data.q2_data);
assign au = unsigned'(data.q1_data);
assign bu = unsigned'(data.q2_data);

always_ff @(posedge clk) begin
    if(rst) begin
        alu_result_valid <= 1'b0;
    end else begin
        if(rs_alu_start) begin
            result.rd_data <= f;
            result.rs1_data <= data.q1_data;
            result.rs2_data <= data.q2_data;
            result.rob_entry <= data.rob_dest;
            alu_result_valid <= 1'b1;
        end else if(cdb_ready) begin
            alu_result_valid <= 1'b0;
        end
    end
end

always_latch begin
    if(rst) begin
        alu_ready <= 1'b1;
    end else begin
        if(rs_alu_start) begin
            alu_ready <= 1'b0;
        end else if(cdb_ready) begin
            alu_ready <= 1'b1;
        end
    end
end

always_comb begin
    unique case (data.operation)
        reg_add,imm_addi,lui,auipc:    f = au +   bu;
        reg_sll,imm_slli:              f = au <<  bu[4:0];
        reg_sra,imm_srai:              f = unsigned'(as >>> bu[4:0]);
        reg_sub:                        f = au - bu;
        reg_xor,imm_xori:              f = au ^   bu;
        reg_srl,imm_srli:              f = au >>  bu[4:0];
        reg_or, imm_ori:               f = au |   bu;
        reg_and,imm_andi:              f = au &   bu;
        reg_slt,imm_slti:              f = (as < bs) ? 32'h00000001 : 32'b0;
        reg_sltu,imm_sltiu:             f = (au < bu) ? 32'h00000001 : 32'b0;
        jal:                           f = au + 32'd4; //pc+4
        default: f = 'x;
    endcase
end


endmodule : alu
