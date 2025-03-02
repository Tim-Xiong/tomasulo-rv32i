module rob
import rv32i_types::*;
#(parameter DEPTH = 16)
(
    input	logic	                      clk,
	input	logic	                      rst,
    input   logic                         issue,
    output  rob_entry_t                   rob_data[DEPTH],

    input   rob_entry_t                   rob_vpush,
    output  rob_entry_t                   rob_vpop,
    
    input   cdb_t                         cdb,
    input   logic                         cdb_en,

    output  logic   [$clog2(DEPTH)-1:0]   rob_head, // read pointer
    output  logic   [$clog2(DEPTH)-1:0]   rob_tail, // write pointer
    output  logic   [$clog2(DEPTH)-1:0]   rob_reg_addr,
    output  logic                         full, empty,
    output  logic                         commit, ls_commit, store_on
);
    /**
     * When issue, a entire rob entry rob_vin will be pushed to rob_array, 
     * while the rob_tail at that cycle will be the corresponding rob nubmer.
     *
     * When read for value, directly index to the output array.
     * 
     * When broadcast, write to a single rob entry at rob_s and mark it as ready. 
     *
     * When the oldest entry at head_ptr is ready, commit will be set to 1.
     * This will happen one cycle after broadcast, use rob_head and rob entry at 
     * rob_head to write to the mapped register. 
    */

    rob_entry_t                      rob_array[DEPTH];
    logic   [$clog2(DEPTH):0]        head_ptr;
    logic   [$clog2(DEPTH):0]        tail_ptr;

    assign rob_head = head_ptr[$clog2(DEPTH)-1:0];
    assign rob_tail = tail_ptr[$clog2(DEPTH)-1:0];
    assign full = (
        (head_ptr[$clog2(DEPTH)-1:0] == tail_ptr[$clog2(DEPTH)-1:0]) &&
        (head_ptr[$clog2(DEPTH)] != tail_ptr[$clog2(DEPTH)])
    );
    assign empty = (head_ptr == tail_ptr);
    assign commit = rob_array[rob_head].ready && !empty;
    assign ls_commit = commit && 
                      (rob_array[rob_head].inst[6:0] == op_load ||
                       rob_array[rob_head].inst[6:0] == op_store);
    assign store_on = rob_array[rob_head].inst[6:0] == op_store;

    rob_entry_t temp; 
    always_ff @(posedge clk) begin
        if (rst) begin
            head_ptr <= '0;
            tail_ptr <= '0;
            for (int i = 0; i < DEPTH; i++) begin
                rob_array[i].ready <= '0;
            end
        end else begin
            if (issue && !full) begin
                rob_array[tail_ptr[$clog2(DEPTH)-1:0]] <= rob_vpush;
                tail_ptr <= tail_ptr + 1'b1;
            end 
            if (commit) begin
                rob_vpop <= rob_array[rob_head];
                rob_reg_addr <= rob_head;
                head_ptr <= head_ptr + 1'b1;
                rob_array[rob_head].ready <= '0;
            end
            if(cdb_en) begin
                rob_array[cdb.rob_entry].rd_data <= cdb.rd_data;
                rob_array[cdb.rob_entry].rs1_data <= cdb.rs1_data;
                rob_array[cdb.rob_entry].rs2_data <= cdb.rs2_data;
                rob_array[cdb.rob_entry].ready <= 1'b1;
                rob_array[cdb.rob_entry].mem_addr <= cdb.mem_addr;
                rob_array[cdb.rob_entry].mem_rmask <= cdb.mem_rmask;
                rob_array[cdb.rob_entry].mem_wmask <= cdb.mem_wmask;
                rob_array[cdb.rob_entry].mem_rdata <= cdb.mem_rdata;
                rob_array[cdb.rob_entry].mem_wdata <= cdb.mem_wdata;
            end
        end
    end

    always_comb begin
        for (int i = 0; i < DEPTH; i++) begin
            rob_data[i] = rob_array[i];
        end
    end

endmodule
