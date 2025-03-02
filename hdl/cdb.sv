module cdb 
import rv32i_types::*; 
(   
    // input   logic   rst,
    input   cdb_t   alu_result,
    input   cdb_t   mul_result,
    input   cdb_t   div_result,
    input   cdb_t   br_result,
    input   cdb_t   ls_result,

    input   logic   alu_ready,
    input   logic   mul_ready,
    input   logic   div_ready,
    input   logic   br_ready,
    input   logic   ls_ready,

    output  logic   cdb_en,
    output  cdb_t   cdb_out,

    output  logic   alu_ack,
    output  logic   mul_ack,
    output  logic   div_ack,
    output  logic   mem_ack,
    output  logic   br_ack
);

    always_comb begin:U_CDB
        cdb_out.rob_entry   = 'x;
        cdb_out.rd_data     = 'x;
        cdb_out.rs1_data    = 'x;
        cdb_out.rs2_data    = 'x;
        cdb_en              = 1'b0;
        alu_ack             = 1'b0;
        mul_ack             = 1'b0;
        div_ack             = 1'b0;
        mem_ack             = 1'b0;
        br_ack              = 1'b0;
        alu_ack             = 1'b0;
        mul_ack             = 1'b0;
        div_ack             = 1'b0;
        mem_ack             = 1'b0;
        br_ack              = 1'b0;
        cdb_out             = 'x;
        if (br_ready) begin
            cdb_en  = 1'b1;
            cdb_out = br_result;
            cdb_out.mem_rmask = '0;
            cdb_out.mem_wmask = '0;
            br_ack = 1'b1;
        end else if (div_ready) begin
            cdb_en  = 1'b1;
            cdb_out = div_result;
            cdb_out.mem_rmask = '0;
            cdb_out.mem_wmask = '0;
            div_ack = 1'b1;
        end else if (mul_ready) begin
            cdb_en  = 1'b1;
            cdb_out = mul_result;
            cdb_out.mem_rmask = '0;
            cdb_out.mem_wmask = '0;
            mul_ack  = 1'b1;
        end else if (alu_ready) begin
            cdb_en  = 1'b1;
            cdb_out = alu_result;
            cdb_out.mem_rmask = '0;
            cdb_out.mem_wmask = '0;
            alu_ack = 1'b1;
        end else if (ls_ready) begin
            cdb_en  = 1'b1;
            cdb_out = ls_result;
            mem_ack = 1'b1;
        end 
    end 
endmodule

