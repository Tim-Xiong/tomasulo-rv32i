module queue
import rv32i_types::*;
#(
	parameter	ADDR_WIDTH = 4
)
(
	input	logic	clk,
	input	logic	rst,
	input	logic	push,
	input   fetch_queue_t	data_in,

	input	logic	pop,
	output	fetch_queue_t	data_out,
	output	logic	empty,
	output	logic	full
);

/*	This is a queue with first-in first-out. Push can not happen
*	when queue is full, and the output data should be ignored when
*	it is empty.
*	When pushing a new data, data_in should have valid data.
*	Poping a value from the queue reflects the change in the next cycle.
*/

localparam QUEUE_DEPTH = 1 << ADDR_WIDTH;
fetch_queue_t	mem[0:QUEUE_DEPTH-1];
logic	[ADDR_WIDTH:0]		read_ptr,write_ptr;


assign empty = read_ptr == write_ptr;

assign full  = ((read_ptr[ADDR_WIDTH-1:0] == write_ptr[ADDR_WIDTH-1:0]) &&
				(read_ptr[ADDR_WIDTH] != write_ptr[ADDR_WIDTH]));

always_ff @(posedge clk) begin: Push
	if(rst) begin
		read_ptr <= '0;
		write_ptr <= '0; 
	end else begin
		if(push && !full) begin
			mem[write_ptr[ADDR_WIDTH-1:0]] <= data_in;
			write_ptr <= (write_ptr + 1'b1); // would overflow if exceed the lim
		end 

		if(pop && !empty) begin
			read_ptr <= (read_ptr + 1'b1);
		end
	end
end

always_comb begin: Output
	data_out = mem[read_ptr[ADDR_WIDTH-1:0]];
end

endmodule
