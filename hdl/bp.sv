module bp
import rv32i_types::*;
(
    input   logic           clk,
    input   logic           rst,

    input   logic           update,

    output  bp_t            bp_prediction   
);

bp_t   pred_bit;

always_ff @(posedge clk) begin
    //pred_bit <= taken;
    if(rst) begin
        pred_bit <= taken;
    end else if(update) begin
        pred_bit <= bp_t'(~logic'(pred_bit));
    end
end

assign bp_prediction = pred_bit;

endmodule : bp
