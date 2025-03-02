module register
import rv32i_types::*;
#(
    parameter DATA_WIDTH = 32,    // Width of data
    parameter REGF_SIZE  = 32,    // how many regs we have
    parameter ROB_LENGTH = 8,
    parameter ADDR_WIDTH = $clog2(REGF_SIZE),
    parameter ROB_WIDTH = $clog2(ROB_LENGTH)
)
(
    input	logic	                clk,
	input	logic	                rst,
    // input   logic [ADDR_WIDTH-1:0]  rs1_addr,     // Address for first read operation
    // input   logic [ADDR_WIDTH-1:0]  rs2_addr,     // Address for second read operation
    
    input   logic                   rob_we,       // If the rob dependency of the rob_rd_addr need to be updated
    input   logic [ADDR_WIDTH-1:0]  rob_rd_addr,  // This index should come from decode stage
    input   logic [ROB_WIDTH-1:0]   decode_rob_entry,    // the rob entry

    input   logic [ADDR_WIDTH-1:0]  rd_addr,      // Address for write operation, this should come from commit stage
    input   logic [DATA_WIDTH-1:0]  rd_data,      // Data to write
    input   logic [ROB_WIDTH-1:0]   commit_rob_entry,
    input   logic                   regf_we,      // When an inst in ROB is ready to commit, it should write to the reg file
                                                  // the regf_we is the write enable

    output  logic [DATA_WIDTH-1:0]  reg_data[REGF_SIZE],    // Output data 
    output  logic [ROB_WIDTH-1:0]   reg_rob[REGF_SIZE],     // Output data for second read operation
    output  logic                   reg_rob_valid[REGF_SIZE],

    input   logic                   br_flush
);



    logic   [DATA_WIDTH-1:0]    data[REGF_SIZE];
    logic   [ROB_WIDTH-1:0]     ROB[REGF_SIZE];        // the msb is used to identify if there is an ROB entry writing it. If 0, no dependency, 1 otherwise
    logic                       rob_valid[REGF_SIZE];

    always_ff @(posedge clk) begin
        if (rst) begin
            for (int i = 0; i < REGF_SIZE; i++) begin
                data[i] <= '0;
                ROB[i]  <= '0;
                rob_valid[i]  <= '0;
            end
        end else if(br_flush) begin
            for (int i = 0; i < REGF_SIZE; i++) begin
                rob_valid[i]  <= '0;
            end
            //This takes care of jalr stuff
            if (regf_we && (rd_addr != 5'd0)) begin
                data[rd_addr] <= rd_data;
                rob_valid[rd_addr]  <= 1'b0;
            end
        end else begin
            if (regf_we && (rd_addr != 5'd0)) begin
                data[rd_addr] <= rd_data;
                // only clears the dependency if the updating rob is the newest dependency
                if (ROB[rd_addr] == commit_rob_entry) begin  
                    rob_valid[rd_addr]  <= 1'b0;
                end
            end 
            if (rob_we && (rob_rd_addr != 5'd0)) begin
                ROB[rob_rd_addr]        <= decode_rob_entry;
                rob_valid[rob_rd_addr]  <= 1'b1;
            end
        end
    end

    always_comb begin
        for (int i = 0; i < REGF_SIZE; i++) begin
            reg_data[i]      = data[i];
            reg_rob[i]       = ROB[i];
            reg_rob_valid[i] = rob_valid[i];
        end
    end

endmodule
