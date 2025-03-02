module data_handler #(
    parameter int WAYS = 4,     // 4 ways
    parameter int DATA_WIDTH = 256,  // 32 bytes
    parameter int OFFSET_WIDTH = 5,
    parameter int MASK_WIDTH = DATA_WIDTH / 8  
)
(
    input   logic [DATA_WIDTH-1:0]      cache_data, // original cache data
	input	logic [31:0]				ufp_wdata,	// the data to write
    input   logic [OFFSET_WIDTH-1:0]    offset,
    input   logic [3:0]                	ufp_wmask,
	input 	logic 						read,
	input 	logic 						write,
	input 	logic 						hit,
	
	output  logic [MASK_WIDTH-1:0]      wmask,
	output  logic           			ufp_resp,
	output  logic [31:0]  				ufp_rdata, 
	output	logic [DATA_WIDTH-1:0]		cache_data_write
);

	// logic [MASK_WIDTH-1:0] 	tmp_wmask;

	always_comb begin
		ufp_resp			= 1'b0;
		ufp_rdata 			= 32'bx;
		wmask 				= 'b0;
		cache_data_write	= cache_data;
		if (hit && read) begin
			ufp_rdata = cache_data[offset*8 +:32]; // return entire word
			ufp_resp  = 1'b1;
		end else if (hit && write) begin
			wmask = {MASK_WIDTH{1'b1}};
			for (int unsigned i = 0; i < 4; ++i) begin
				if (ufp_wmask[i]) begin
					cache_data_write[(offset+i)*8+:8] = ufp_wdata[i*8+:8]; 
				end
			end
			ufp_resp  = 1'b1;
		end
	end
endmodule