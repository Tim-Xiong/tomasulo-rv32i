module compare_tag #(
    parameter int WAYS = 4,
    parameter int TAG_WIDTH = 23
)
(
    input   logic                   csb0,   // al
    input   logic [TAG_WIDTH-1:0]   input_tag,
    input   logic [TAG_WIDTH:0]     tag_array[WAYS], // include dirty bit
    input   logic                   valid_array[WAYS],

    output  logic                   hit,
    output  logic [1:0]             hit_way
    
);

    always_comb begin
        hit = 1'b0;
        hit_way = 2'bx; 
        
        for (int unsigned i = 0; i < WAYS; i++) begin
            if (input_tag == tag_array[i][TAG_WIDTH-1:0] && valid_array[i] && !csb0) begin
                hit = 1'b1;
                hit_way = i[1:0]; 
                break; 
            end
        end
    end
endmodule