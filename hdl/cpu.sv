module cpu
import rv32i_types::*; 
(
    // Explicit dual port connections when caches are not integrated into design yet (Before CP3)
    input   logic           clk,
    input   logic           rst,

    output  logic   [31:0]  imem_addr,
    output  logic   [3:0]   imem_rmask,
    input   logic   [31:0]  imem_rdata,
    input   logic           imem_resp,

    output  logic   [31:0]  dmem_addr,
    output  logic   [3:0]   dmem_rmask,
    output  logic   [3:0]   dmem_wmask,
    input   logic   [31:0]  dmem_rdata,
    output  logic   [31:0]  dmem_wdata,
    input   logic           dmem_resp

    // Single memory port connection when caches are integrated into design (CP3 and after)
    
    // output logic   [31:0]      bmem_addr,
    // output logic               bmem_read,
    // output logic               bmem_write,
    // output logic   [63:0]      bmem_wdata,
    // input  logic               bmem_ready,

    // input  logic   [31:0]      bmem_raddr,
    // input  logic   [63:0]      bmem_rdata,
    // input  logic               bmem_rvalid
    
);


logic store_on, ls_commit;
logic rob_full, rob_empty; // <UNMAPPED> rob_empty
rob_entry_t rob_vpush, rob_vpop;
rob_entry_t rob_data[ROB_DEPTH];
logic [$clog2(ROB_DEPTH)-1:0] rob_head, rob_tail,rob_reg_addr;
logic reg_valid;

// logic   [31:0]  imem_addr;
// logic   [3:0]   imem_rmask;
// logic   [31:0]  imem_rdata;
// logic           imem_resp;

// logic   [31:0]  dmem_addr;
// logic   [3:0]   dmem_rmask;
// logic   [3:0]   dmem_wmask;
// logic   [31:0]  dmem_rdata;
// logic   [31:0]  dmem_wdata;
// logic           dmem_resp;

// logic 	[31:0]  imem_req_addr;
// logic 	        imem_req_read;

// logic 	        imem_req_resp;
// logic 	[255:0] imem_req_rdata;

// logic 	[31:0]  dmem_req_addr;
// logic 	        dmem_req_read;
// logic 	        dmem_req_write;
// logic 	[255:0] dmem_req_wdata;

// logic 	        dmem_req_resp;
// logic 	[255:0] dmem_req_rdata;
logic			br_flush;
// ============= I Cache =================
// cache cache_i(
// 	.clk(clk),
// 	.rst(rst || br_flush),

//     .ufp_addr(imem_addr),
//     .ufp_rmask(imem_rmask),
//     .ufp_wmask(4'b0),
//     .ufp_rdata(imem_rdata),
//     .ufp_wdata(32'bx),
//     .ufp_resp(imem_resp),

//     .dfp_addr(imem_req_addr),
//     .dfp_read(imem_req_read),
//     .dfp_write(),
//     .dfp_rdata(imem_req_rdata),
//     .dfp_wdata(),
//     .dfp_resp(imem_req_resp)
// );
 // ============ D Cache =================
// cache cache_d(
// 	.clk(clk),
// 	.rst(rst),

//     .ufp_addr(dmem_addr),
//     .ufp_rmask(dmem_rmask),
//     .ufp_wmask(dmem_wmask),
//     .ufp_rdata(dmem_rdata),
//     .ufp_wdata(dmem_wdata),
//     .ufp_resp(dmem_resp),

//     .dfp_addr(dmem_req_addr),
//     .dfp_read(dmem_req_read),
//     .dfp_write(dmem_req_write),
//     .dfp_rdata(dmem_req_rdata),
//     .dfp_wdata(dmem_req_wdata),
//     .dfp_resp(dmem_req_resp)
// );

// ============= MEM port =================
// memport memport(
// 	.clk(clk),
//     .rst(rst),
//     .imem_req_addr(imem_req_addr),
//     .imem_req_read(imem_req_read), 
// 	.dmem_req_addr(dmem_req_addr),
// 	.dmem_req_read(dmem_req_read),
// 	.dmem_req_write(dmem_req_write),
// 	.dmem_req_wdata(dmem_req_wdata),

//     .bmem_ready(bmem_ready),
//     .bmem_raddr(bmem_raddr),
//     .bmem_rdata(bmem_rdata),
//     .bmem_rvalid(bmem_rvalid),         

//     .imem_req_resp(imem_req_resp),
//     .imem_req_rdata(imem_req_rdata),
// 	.dmem_req_resp(dmem_req_resp),
// 	.dmem_req_rdata(dmem_req_rdata),

//     .bmem_addr(bmem_addr),
//     .bmem_read(bmem_read),
//     .bmem_write(bmem_write),
//     .bmem_wdata(bmem_wdata)
// );


// ============= end temp code ===============

logic	[31:0]	pc,pc_next;
logic 	[63:0]	order;

logic 			pc_write;
logic			push_fq,pop_fq,empty_fq,full_fq;
fetch_queue_t	data_out_fq;
fetch_queue_t 	fetch_data;

//jal/branch control logic
logic			jal_ready;
logic	[31:0]	jal_addr;
logic	[63:0]	jal_order;

//branch control logic
logic	[31:0]	br_addr;
logic	[63:0]  br_order;

queue #(.ADDR_WIDTH(3)) fetch_queue_i (
	.clk(clk), 				// input
	.rst(rst || jal_ready || br_flush), // input
	.push(pc_write), 		// input
	.pop(pop_fq), 			// input
	.data_in(fetch_data), // inst, pc, pc_next, order	
	.data_out(data_out_fq), // output
	.empty(empty_fq), 		// output
	.full(full_fq) 			// output
);

// ============ Instruction fetch sections =============
fetch fetch_i(
	.clk(clk), 				
	.rst(rst),
	.imem_addr(imem_addr),
    .imem_rmask(imem_rmask),
    .imem_rdata(imem_rdata),
    .imem_resp(imem_resp),
    .full_fq(full_fq),
	.fetch_data(fetch_data),
	.pc_write(pc_write),

	.jal_ready(jal_ready),
	.jal_addr(jal_addr),
	.jal_order(jal_order),

	.br_flush(br_flush),
	.br_addr(br_addr),
	.br_order(br_order)
);


// ============= Read from fetch queue to decode sections ============
logic 			data_in_en;
logic 			alu_rs;
logic 			mem_rs;
logic 			mul_rs;
logic 			div_rs;
logic 			br_rs;
logic 			lsq_avai;
logic 			rob;
logic 			decode_available;
logic 			decode_output_ready;
rs_types_t 		rs_dest;
decode_output_t decode_output;	

cdb_t			cdb;
logic			cdb_en;
cdb_t			alu_cdb,mul_cdb,br_cdb, ls_cdb;


logic 			commit_en;

logic			alu_result_valid,mul_result_valid,br_result_valid,ls_result_valid;
logic 			alu_ack;
logic 			mul_ack;
logic 			div_ack;
logic 			mem_ack;
logic 			br_ack;
logic   		div_ready;
logic 			mem_ready;
cdb_t 			tmp_cdb;

logic			alu_select,mul_select,mem_select,div_select,br_select,lsq_select;

always_comb begin:To_Decode
	if(rst) begin
		pop_fq = '0;
	end else if(!empty_fq && decode_available) begin
		pop_fq = '1;
	end else begin
		pop_fq = '0;
	end
end

// ---------------- tmp code tp avoid warning
assign mem_rs = 1'b0;
assign div_rs = 1'b0;
// ---------------------------------------------

decode decode_i(
	.clk(clk),
	.rst(rst || br_flush),
	.data_in_en(pop_fq),
	.data_in(data_out_fq),
	.alu_rs(alu_rs), 		// 1 if alu rs not full
	.mem_rs(mem_rs),
	.mul_rs(mul_rs),
	.div_rs(div_rs),
	.br_rs(br_rs), 
	.lsq_avai(lsq_avai),
	.rob(!rob_full), 				// 1 if rob not full

	.alu_select(alu_select),
	.mem_select(mem_select),
	.mul_select(mul_select),
	.div_select(div_select),
	.br_select(br_select),
	.lsq_select(lsq_select),
	.decode_available(decode_available),	// 1 when available for decode
	.decode_output_ready(decode_output_ready),
	.rs_dest(rs_dest),
	.result(decode_output),

	.jal_ready(jal_ready),
	.jal_addr(jal_addr),
	.jal_order(jal_order)
);

// =============== Reg File ==================
logic [DATA_WIDTH-1:0]        reg_data[32]; 		// Output data 
logic [$clog2(ROB_DEPTH)-1:0] reg_rob[32];     	// Output data for second read operation
logic                          reg_rob_valid[32];		

register regf(
	.clk(clk),
	.rst(rst),
    
    .rob_we(decode_output_ready),       // If the rob dependency of the rob_rd_addr need to be updated
    .rob_rd_addr(decode_output.rd),  	// This index should come from decode stage
    .decode_rob_entry(rob_tail),    			// the rob entry

    .rd_addr(rob_vpop.rd_addr),      	// Address for write operation, this should come from commit stage
    .rd_data(rob_vpop.rd_data),      	// Data to write
    .commit_rob_entry(rob_reg_addr),
    .regf_we(reg_valid),      	// When an inst in ROB is ready to commit, it should write to the reg file
                                                  // the regf_we is the write enable

    .reg_data(reg_data), 		// Output data 
    .reg_rob(reg_rob),     		// Output data for second read operation
    .reg_rob_valid(reg_rob_valid),
	.br_flush(br_flush)
);

rs_alu_output_t rs_alu_result;
rs_mul_output_t rs_mul_result;
rs_br_output_t  rs_br_result;
logic 			alu_ready,mul_ready,br_ready;
logic 			rs_alu_en,rs_mul_en,rs_br_en;

rs_alu rs_alu_i(
	.clk(clk),
	.rst(rst|| br_flush),
	.operation_bus_valid(decode_output_ready),
	.alu_select(alu_select),
	.data(decode_output),
	.rob_dest(rob_tail),

	.reg_data(reg_data),
	.reg_rob_valid(reg_rob_valid),
	.reg_rob(reg_rob),
	.regf_we(reg_valid),
	.rob2reg_addr(rob_vpop.rd_addr),
	.rob2reg_data(rob_vpop.rd_data),

	.rob_data(rob_data),
	.rob_reg_addr(rob_reg_addr),

	.cdb_en(cdb_en),
	.cdb(cdb),
	.unit_ready(alu_ready),
	.result(rs_alu_result),
	.rs_result_en(rs_alu_en),
	.rs_not_full(alu_rs)
);

rs_mul rs_mul_i(
	.clk(clk),
	.rst(rst|| br_flush),
	.operation_bus_valid(decode_output_ready),
	.mul_select(mul_select),
	.data(decode_output),
	.rob_dest(rob_tail),

	.reg_data(reg_data),
	.reg_rob_valid(reg_rob_valid),
	.reg_rob(reg_rob),
	.regf_we(reg_valid),
	.rob2reg_addr(rob_vpop.rd_addr),
	.rob2reg_data(rob_vpop.rd_data),

	.rob_data(rob_data),
	.rob_reg_addr(rob_reg_addr),

	.cdb_en(cdb_en),
	.cdb(cdb),
	.unit_ready(mul_ready),
	.result(rs_mul_result),
	.rs_result_en(rs_mul_en),
	.rs_not_full(mul_rs)
);

rs_br rs_br_i(
	.clk(clk),
	.rst(rst|| br_flush),
	.operation_bus_valid(decode_output_ready),
	.br_select(br_select),
	.data(decode_output),
	.rob_dest(rob_tail),

	.reg_data(reg_data),
	.reg_rob_valid(reg_rob_valid),
	.reg_rob(reg_rob),
	.regf_we(reg_valid),
	.rob2reg_addr(rob_vpop.rd_addr),
	.rob2reg_data(rob_vpop.rd_data),

	.rob_data(rob_data),
	.rob_reg_addr(rob_reg_addr),

	.cdb_en(cdb_en),
	.cdb(cdb),
	.unit_ready(br_ready),
	.result(rs_br_result),
	.rs_result_en(rs_br_en),
	.rs_not_full(br_rs)
);

alu alu_i(
    .clk(clk),
    .rst(rst|| br_flush),
    .data(rs_alu_result),
    .cdb_ready(alu_ack),
	.rs_alu_start(rs_alu_en),

    .alu_ready(alu_ready),
	.alu_result_valid(alu_result_valid),
    .result(alu_cdb)
);

shift_add_multiplier mul_i(
    .clk(clk),
    .rst(rst|| br_flush),
	.start(rs_mul_en),
	.data(rs_mul_result),
	.result(mul_cdb),
	.cdb_ready(mul_ack),
	.mul_ready(mul_ready),
	.done(mul_result_valid)
);

br br_i(
    .clk(clk),
    .rst(rst|| br_flush),
    .data(rs_br_result),
    .cdb_ready(br_ack),
	.rs_br_start(rs_br_en),

    .br_ready(br_ready),
	.br_result_valid(br_result_valid),
    .result(br_cdb)
);

lsq lsq_i(
	.clk(clk),
	.rst(rst || br_flush),
	.operation_bus_valid(decode_output_ready),
	.lsq_select(lsq_select),
	.data(decode_output),
	.rob_dest(rob_tail),
	.reg_data(reg_data),
	.reg_rob_valid(reg_rob_valid),
	.reg_rob(reg_rob),
	.regf_we(reg_valid),
	.rob2reg_addr(rob_vpop.rd_addr),
	.rob2reg_data(rob_vpop.rd_data),
	.rob_data(rob_data),
	.rob_reg_addr(rob_reg_addr),
	.cdb_en(cdb_en), //If cdb has valid data
	.cdb(cdb),	//cdb's data
	.dmem_rdata(dmem_rdata),
    .dmem_resp(dmem_resp),
    .dmem_addr(dmem_addr),
    .dmem_rmask(dmem_rmask),
    .dmem_wmask(dmem_wmask),
    .dmem_wdata(dmem_wdata),
    .store_on(store_on), // rob raise this when store is the oldest
    .ls_commit(ls_commit), // rob raise this when load/store commit
    .lsq_avai(lsq_avai), // lsq is not full
    .ls_result_ready(ls_result_valid),
    .result(ls_cdb)
);

always_comb begin
	rob_vpush.ready = '0;
	rob_vpush.inst = decode_output.inst;
	rob_vpush.pc = decode_output.pc;
	rob_vpush.pc_next = decode_output.pc_next;
	rob_vpush.order = decode_output.order;
	rob_vpush.rd_addr = decode_output.rd;
	rob_vpush.rd_data = cdb_en ? cdb.rd_data : 'x;
	rob_vpush.rs1_data = '0;
	rob_vpush.rs2_data = '0;
	rob_vpush.mem_addr = '0;
	rob_vpush.mem_rmask = '0;
	rob_vpush.mem_wmask = '0;
	rob_vpush.mem_rdata = '0;
	rob_vpush.mem_wdata = '0;
end

rob #(.DEPTH(ROB_DEPTH)) rob_i(
	.clk(clk),
	.rst(rst|| br_flush),
    .issue(decode_output_ready),
    .cdb_en(cdb_en),

	.rob_data(rob_data),

    .rob_vpush(rob_vpush),
    .rob_vpop(rob_vpop),
    .rob_head(rob_head), // read pointer
    .rob_tail(rob_tail), // write pointer
    .full(rob_full),
	.empty(rob_empty),
    .commit(commit_en), // ready to write to register
	.cdb(cdb),
	.rob_reg_addr(rob_reg_addr),
	.store_on(store_on),
	.ls_commit(ls_commit)
);

commit commit_i(
    .clk(clk),
	.rst(rst),
	.reg_valid(reg_valid),
    .commit_data(rob_vpop),
    .commit_en(commit_en),
	.br_flush(br_flush),
    .br_addr(br_addr),
    .br_order(br_order)
);

// ------------ tmp code to avoid warning
always_comb begin
	tmp_cdb.rob_entry = 'b0;
	tmp_cdb.rd_data   = 'b0;
	tmp_cdb.rs1_data  = 'b0;
	tmp_cdb.rs2_data  = 'b0;
	tmp_cdb.mem_addr = 'b0;
	tmp_cdb.mem_rmask = 'b0;
	tmp_cdb.mem_wmask = 'b0;
	tmp_cdb.mem_rdata = 'b0;
	tmp_cdb.mem_wdata = 'b0;
	div_ready = 1'b0;
end
// ---------------------------------
cdb cdb_i(
	.alu_result(alu_cdb),
    .mul_result(mul_cdb),
    .div_result(tmp_cdb),
    .br_result(br_cdb),
	.ls_result(ls_cdb),

    .alu_ready(alu_result_valid),
    .mul_ready(mul_result_valid),
    .div_ready(div_ready),
    .br_ready(br_result_valid),
	.ls_ready(ls_result_valid),

    .cdb_en(cdb_en),
    .cdb_out(cdb),

    .alu_ack(alu_ack),
    .mul_ack(mul_ack),
    .div_ack(div_ack),
    .mem_ack(mem_ack),
    .br_ack(br_ack)
);

endmodule : cpu
