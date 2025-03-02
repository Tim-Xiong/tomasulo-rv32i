module plru_array #(
    parameter int SETS = 16, // Number of sets
    parameter int WAYS = 4 
)
(   
    input   logic           clk,
    input   logic           rst,        // reset
    input   logic [3:0]     index,      // which way is accessing
    input   logic           hit,        // if the CT hits, 
    input   logic [1:0]     hit_way,    // and which way it hits
    
    output  logic [1:0]     replace     // the way 0-3 to be replace
);

    logic [SETS-1:0]    hits;
    logic [1:0]         replace_array[SETS];
    // Instantiate
    generate
        for (genvar i = 0; i < SETS; i++) begin : plru_units
            plru #(
                .WAYS(WAYS)
            ) unit (
                .clk(clk),
                .rst(rst),
                .hit(hits[i]),
                .hit_way(hit_way), // Select 2 bits for each accessed_way
                .replace(replace_array[i]) // Output 2 bits for each plru_way
            );
        end
    endgenerate

    always_comb begin
        hits = {SETS{1'b0}};
        replace = 2'b0;
        if (!rst) begin
            hits[index] = hit;
            replace = replace_array[index];
        end
    end


endmodule

module plru #(
    parameter int WAYS = 4 
)
(
    input   logic           clk,
    input   logic           rst,
    input   logic           hit, 
    input   logic [1:0]     hit_way, 

    output  logic [1:0]     replace 
);

    // PLRU state bits
    logic [WAYS-2:0] state; // stores MRU, but returns its negate

    // Update PLRU state on hit
    always_ff @(posedge clk) begin
        if (rst) begin
            state <= 3'b0;
        end else if (hit) begin
            case (hit_way)
                2'b00: state <= {1'b0, state[1], 1'b0};
                2'b01: state <= {1'b1, state[1], 1'b0};
                2'b10: state <= {state[2], 1'b0, 1'b1};
                2'b11: state <= {state[2], 1'b1, 1'b1};
            endcase
        end
    end

    // Decide which way to replace based on PLRU state
    always_comb begin
        case (state)
            3'b000, 3'b100: replace = 2'b11;
            3'b010, 3'b110: replace = 2'b10;
            3'b001, 3'b011: replace = 2'b01;
            3'b111, 3'b101: replace = 2'b00; // Covers 3'b110 and 3'b111
        endcase
    end

endmodule