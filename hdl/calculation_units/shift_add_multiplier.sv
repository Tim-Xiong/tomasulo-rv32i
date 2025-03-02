module shift_add_multiplier
import rv32i_types::*;
#(
    parameter int OPERAND_WIDTH = 32
)
(
    input logic clk,
    input logic rst,
    // Start must be reset after the done flag is set before another multiplication can execute
    input logic start,

    // Use this input to select what type of multiplication you are performing
    // 0 = Multiply two unsigned numbers
    // 1 = Multiply two signed numbers
    // 2 = Multiply a signed number and unsigned number
    //      a = signed
    //      b = unsigned
    input rs_mul_output_t data,
    input  logic cdb_ready,

    output  cdb_t   result,
    output  logic   mul_ready,
    output  logic   done
);

    // Constants for multiplication case readability
    `define UNSIGNED_UNSIGNED_MUL 2'b00
    `define SIGNED_SIGNED_MUL     2'b01
    `define SIGNED_UNSIGNED_MUL   2'b10

    enum int unsigned {IDLE, SHIFT, ADD, DONE} curr_state, next_state;
    localparam int OP_WIDTH_LOG = $clog2(OPERAND_WIDTH);
    logic [OP_WIDTH_LOG-1:0] counter;
    logic [OPERAND_WIDTH-1:0] b_reg;
    logic [2*OPERAND_WIDTH-1:0] accumulator, a_reg; // a_reg needs to be 2 times wide since it is shifted left
    logic neg_result;

    logic   [1:0] mul_type;
    logic   [2*OPERAND_WIDTH-1:0] p;
    logic   [OPERAND_WIDTH-1:0] a;
    logic   [OPERAND_WIDTH-1:0] b;



    always_comb begin
        a = data.q2_data;
        b = data.q1_data;
        unique case(data.operation)
            reg_mul: begin
                result.rd_data = p[31:0];
                mul_type = 2'b00;
            end
		    reg_mulh: begin
                result.rd_data = p[63:32];
                mul_type = 2'b01;
            end
		    reg_mulsu: begin
                result.rd_data = p[63:32];
                mul_type = 2'b10;
            end
		    reg_mulhu: begin
                result.rd_data = p[63:32];
                mul_type = 2'b00;
            end
            default: begin
                result.rd_data = p[63:32];
                mul_type = 2'b00;
            end
        endcase
    end

always_ff @(posedge clk) begin
    if(rst) begin
    end else begin
        if(start) begin
            result.rs1_data <= data.q1_data;
            result.rs2_data <= data.q2_data;
            result.rob_entry <= data.rob_dest;
        end else if(cdb_ready) begin
        end
    end
end

always_latch begin
    if(rst) begin
        mul_ready <= 1'b1;
    end else begin
        if(start) begin
            mul_ready <= 1'b0;
        end else if(cdb_ready) begin
            mul_ready <= 1'b1;
        end
    end
end

    always_comb
    begin : state_transition
        next_state = curr_state;
        unique case (curr_state)
            IDLE:    next_state = start ? ADD : IDLE;
            ADD:     next_state = SHIFT;
            SHIFT:   next_state = (counter == (OP_WIDTH_LOG)'(OPERAND_WIDTH-1'b1)) ? DONE : ADD;
            DONE:    next_state = start ? DONE : IDLE;
            default: next_state = curr_state;
        endcase
    end : state_transition

    always_comb
    begin : state_outputs
        done = '0;
        p = '0;
        unique case (curr_state)
            DONE:
            begin
                done = 1'b1;
                unique case (mul_type)
                    `UNSIGNED_UNSIGNED_MUL: p = accumulator[2*OPERAND_WIDTH-1:0];
                    `SIGNED_SIGNED_MUL,
                    `SIGNED_UNSIGNED_MUL: p = neg_result ? (~accumulator[2*OPERAND_WIDTH-1-1:0])+1'b1 : accumulator;
                    default: ;
                endcase
            end
            default: ;
        endcase
    end : state_outputs

    always_ff @ (posedge clk)
    begin
        if (rst)
        begin
            curr_state <= IDLE;
            a_reg <= '0;
            b_reg <= '0;
            accumulator <= '0;
            counter <= '0;
            neg_result <= '0;
        end

        else
        begin
            curr_state <= next_state;
            unique case (curr_state)
                IDLE:
                begin
                    if (start)
                    begin
                        accumulator <= '0;
                        unique case (mul_type)
                            `UNSIGNED_UNSIGNED_MUL:
                            begin
                                neg_result <= '0;   // Not used in case of unsigned mul, but just cuz . . .
                                a_reg <= {{OPERAND_WIDTH{1'b0}}, a};
                                b_reg <= b;
                            end
                            `SIGNED_SIGNED_MUL:
                            begin
                                // A -*+ or +*- results in a negative number unless the "positive" number is 0
                                neg_result <= (a[OPERAND_WIDTH-1] ^ b[OPERAND_WIDTH-1]) && ((a != '0) && (b != '0));
                                // If operands negative, make positive
                                a_reg <= (a[OPERAND_WIDTH-1]) ? {OPERAND_WIDTH*{1'b0}, (~a + 1'b1)} : a;
                                b_reg <= (b[OPERAND_WIDTH-1]) ? {(~b + 1'b1)} : b;
                            end
                            `SIGNED_UNSIGNED_MUL:
                            begin
                                neg_result <= a[OPERAND_WIDTH-1];
                                a_reg <= (a[OPERAND_WIDTH-1]) ? {OPERAND_WIDTH*{1'b0}, (~a + 1'b1)} : a;
                                b_reg <= b;
                            end
                            default:;
                        endcase
                    end
                end
                ADD: if (b_reg[0]) accumulator <= accumulator + a_reg;
                SHIFT:
                begin
                    a_reg <= a_reg<<1;
                    b_reg <= b_reg>>1;
                    counter <= counter + 1'b1;
                end
                DONE: counter <= '0;
                default: ;
            endcase
        end
    end


    // ====== for test ======
    // initial begin
    //     $fsdbDumpfile("dump.fsdb");
    //     $fsdbDumpvars(0, "+all");
    // end
    // ======================


endmodule
