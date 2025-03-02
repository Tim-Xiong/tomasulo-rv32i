module br
import rv32i_types::*;
(
    input   logic           clk,
    input   logic           rst,
    input   rs_br_output_t     data,
    input   logic           cdb_ready,
    input   logic           rs_br_start,

    output  logic           br_ready,
    output  logic           br_result_valid,
    output  cdb_t           result      
);
logic signed   [31:0] as;
logic signed   [31:0] bs;
logic unsigned [31:0] au;
logic unsigned [31:0] bu;
logic          [31:0] rd_data;
logic                 branch;
logic          [31:0] addr;

assign as =   signed'(data.q1_data);
assign bs =   signed'(data.q2_data);
assign au = unsigned'(data.q1_data);
assign bu = unsigned'(data.q2_data);

always_ff @(posedge clk) begin
    if(rst) begin
        br_result_valid <= 1'b0;
        //br_ready <= 1'b1;
    end else begin
        if(rs_br_start) begin
            result.rd_data <= rd_data;
            result.rs1_data <= data.q1_data;
            result.rs2_data <= data.q2_data;
            result.rob_entry <= data.rob_dest;
            br_result_valid <= 1'b1;
            //br_ready <= 1'b0;
        end else if(cdb_ready) begin
            br_result_valid <= 1'b0;
            //br_ready <= 1'b1;
        end
    end
end

always_latch begin
    if(rst) begin
        br_ready <= 1'b1;
    end else begin
        if(rs_br_start) begin
            br_ready <= 1'b0;
        end else if(cdb_ready) begin
            br_ready <= 1'b1;
        end
    end
end

always_comb begin
    branch = 1'b0;
    rd_data = '1;
    unique case (data.operation)
        	br_beq: branch = (as == bs) ? 1'b1 : 1'b0;
		    br_bne: branch = (as != bs) ? 1'b1 : 1'b0;
		    br_blt: branch = (as < bs) ? 1'b1 : 1'b0;
		    br_bge: branch = (as >= bs) ? 1'b1 : 1'b0;
		    br_bltu: branch = (au < bu) ? 1'b1 : 1'b0;
		    br_bgeu: branch = (au >= bu) ? 1'b1 : 1'b0;
        default: branch = 1'b0;
    endcase
    unique case (data.operation)
        br_beq,br_bne,br_blt,br_bge,br_bltu,br_bgeu: begin
            if(branch == logic'(data.bp_prediction)) begin //hit
                rd_data = '1;
            end else begin //miss
                if(branch) begin //suppose to branch,but did not
                    //next pc should be the one in inst
                    rd_data = 32'h0;
                end else begin //suppose to not branch
                    //next pc should be pc+4
                    rd_data = 32'h00000001;
                end
            end
        end
        jalr: begin
            rd_data = data.pc + 32'd4;
        end
        default: begin
        end
    endcase
end

endmodule
