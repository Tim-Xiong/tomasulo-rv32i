/////////////////////////////////////////////////////////////
//  Maybe use some of your types from mp_pipeline here?    //
//    Note you may not need to use your stage structs      //
/////////////////////////////////////////////////////////////

package rv32i_types;

	// define constant parameter here, use it as macro
	localparam int ROB_DEPTH = 8;
	localparam int DATA_WIDTH = 32;
	localparam int SEQ_WIDTH = 32;

	typedef enum logic [6:0] {
		op_lui   = 7'b0110111, // U load upper immediate 
		op_auipc = 7'b0010111, // U add upper immediate PC 
		op_jal   = 7'b1101111, // J jump and link 
		op_jalr  = 7'b1100111, // I jump and link register 
		op_br    = 7'b1100011, // B branch 
		op_load  = 7'b0000011, // I load 
		op_store = 7'b0100011, // S store 
		op_imm   = 7'b0010011, // I arith ops with register/immediate operands 
		op_reg   = 7'b0110011 // R arith ops with register operands  
	} rv32i_op_t;

//-------------------------------------------------------
//funct3 definitions
//-------------------------------------------------------

	//op_br's funct3
	typedef enum bit [2:0] {
		beq  = 3'b000,
		bne  = 3'b001,
		blt  = 3'b100,
		bge  = 3'b101,
		bltu = 3'b110,
		bgeu = 3'b111
	} branch_funct3_t;

	//op_load's funct3
	typedef enum bit [2:0] {
		lb  = 3'b000,
		lh  = 3'b001,
		lw  = 3'b010,
		lbu = 3'b100,
		lhu = 3'b101
	} load_funct3_t;

	//op_store's funct3
	typedef enum bit [2:0] {
		sb = 3'b000,
		sh = 3'b001,
		sw = 3'b010
	} store_funct3_t;

	//arith's funct3
	typedef enum bit [2:0] {
		add  = 3'b000, //check bit 30 for sub if op_reg opcode
		sll  = 3'b001,
		slt  = 3'b010,
		sltu = 3'b011,
		axor = 3'b100,
		sr   = 3'b101, //check bit 30 for logical/arithmetic
		aor  = 3'b110,
		aand = 3'b111
	} arith_funct3_t;

//Operation section for alu reservation stations
	typedef enum logic [5:0] {
		reg_add		= 6'b000000,
		reg_sub		= 6'b000001,
		reg_sll		= 6'b000010,
		reg_xor		= 6'b000101,
		reg_srl		= 6'b000110,
		reg_sra		= 6'b000111,
		reg_or		= 6'b001000,
		reg_and		= 6'b001001,
		imm_addi	= 6'b001110,
		imm_xori	= 6'b010001,
		imm_ori		= 6'b010010,
		imm_andi	= 6'b010011,
		imm_slli	= 6'b010100,
		imm_srli	= 6'b010101,
		imm_srai	= 6'b010110,
		lui			= 6'b010111,
		auipc 		= 6'b011000,
		//mul
		reg_mul		= 6'b001010,
		reg_mulh	= 6'b001011,
		reg_mulsu	= 6'b001100,
		reg_mulhu	= 6'b001101,
		//cmp
		imm_slti	= 6'b001111,
		imm_sltiu	= 6'b010000,
		reg_slt		= 6'b000011,
		reg_sltu	= 6'b000100,
		//jal
		jal 		= 6'b011001,
		jalr 		= 6'b011010,
		//branch
		br_beq		= 6'b011011,
		br_bne		= 6'b011100,
		br_blt		= 6'b011101,
		br_bge		= 6'b011110,
		br_bltu		= 6'b011111,
		br_bgeu		= 6'b100000
	}operation_t;

	typedef enum logic [1:0]{
		register    = 2'b0,
		immediate   = 2'b01,
		pc			= 2'b10,
		zero		= 2'b11
	}source_t;

	typedef enum logic [2:0]{
		alu    = 3'b000,
		mul    = 3'b001,
		mem    = 3'b010,
		div    = 3'b011,
		branch = 3'b100,
		ldst   = 3'b101,
		invalid= 3'b111
	}rs_types_t;

	typedef enum logic {
		taken  = 1'b1,
		not_taken = 1'b0
	}bp_t;

//Bus structs
	/*
	The operation bus exits from decode and goes to reservation
	stations and reorder buffer.
	Load/store uses a different struct
	*/
	typedef struct packed {
		logic	[31:0]	inst;
		logic	[31:0]	pc;
		logic 	[31:0]	pc_next;
		logic	[63:0]	order;
	} fetch_queue_t;

	typedef struct packed{
		logic   [63:0]  order;
		logic	[31:0]	inst;	//32 bit instruction for rob
		logic   [31:0]  pc;
		logic   [31:0]  pc_next;
		operation_t	operation;//operations to perform
		//source of R1
		logic   [4:0]   rs1;
		source_t        r1_select;
		//source of R2, could be a imm number
		logic   [4:0]   rs2;
		logic   [31:0]  imm2;
		source_t        r2_select;

		//branch instruction-taken or not taken
		bp_t			bp_prediction;

		//dest
		logic   [4:0]   rd;
	}decode_output_t;

	typedef struct packed{
		operation_t	operation;
		//q1
		logic           rob1_en; //is it waiting for rob data? 1 is yes
		logic   [$clog2(ROB_DEPTH)-1:0]   rob1;
		logic   [31:0]  q1_data;
		//q2
		logic           rob2_en; //is it waiting for rob data? 1 is yes
		logic   [$clog2(ROB_DEPTH)-1:0]   rob2;
		logic   [31:0]  q2_data;
		//dest
		logic   [$clog2(ROB_DEPTH)-1:0]   rob_dest;
	}rs_t;

	typedef struct packed{
		operation_t	operation;
		//q1
		logic           rob1_en; //is it waiting for rob data? 1 is yes
		logic   [$clog2(ROB_DEPTH)-1:0]   rob1;
		logic   [31:0]  q1_data;
		//q2
		logic           rob2_en; //is it waiting for rob data? 1 is yes
		logic   [$clog2(ROB_DEPTH)-1:0]   rob2;
		logic   [31:0]  q2_data;
		//dest
		logic   [$clog2(ROB_DEPTH)-1:0]   rob_dest;
		//pc(branch only)
		logic	[31:0]	pc;
		bp_t			bp_prediction;
	}rs_br_t;

	typedef struct packed{
		operation_t	operation;
		//q1
		logic   [31:0]  q1_data;
		//q2
		logic   [31:0]  q2_data;
		//dest
		logic   [$clog2(ROB_DEPTH)-1:0]   rob_dest;
	}rs_alu_output_t;

	typedef struct packed{
		operation_t	operation;
		//q1
		logic   [31:0]  q1_data;
		//q2
		logic   [31:0]  q2_data;
		//dest
		logic   [$clog2(ROB_DEPTH)-1:0]   rob_dest;
	}rs_mul_output_t;

	typedef struct packed{
		operation_t	operation;
		//q1
		logic   [31:0]  q1_data;
		//q2
		logic   [31:0]  q2_data;
		//dest
		logic   [$clog2(ROB_DEPTH)-1:0]   rob_dest;
		//pc
		logic   [31:0]   pc;
		bp_t			 bp_prediction;
	}rs_br_output_t;

	/*
	Common Data Bus. Used for communication between calculation units,
	reorder buffer, and reservation stations. Only one active instruction at a given time.
	*/
	typedef struct packed{
		logic	[$clog2(ROB_DEPTH)-1:0]	 rob_entry;
		logic	[31:0]	rd_data;
		logic	[31:0]	rs1_data;
		logic	[31:0]	rs2_data;
		logic	[31:0]	mem_addr;
		logic 	[3:0]	mem_rmask;
		logic 	[3:0]	mem_wmask;
		logic 	[31:0]	mem_rdata;
		logic	[31:0]	mem_wdata;
	}cdb_t;

	typedef struct packed {
		logic 			ready;
		logic	[31:0]	inst;
		logic	[31:0]	pc;
		logic 	[31:0]	pc_next;
		logic	[63:0]	order;
		logic 	[4:0]	rd_addr;
		logic	[31:0]	rd_data;
		logic	[31:0]	rs1_data;
		logic	[31:0]	rs2_data;
		logic	[31:0]	mem_addr;
		logic 	[3:0]	mem_rmask;
		logic 	[3:0]	mem_wmask;
		logic 	[31:0]	mem_rdata;
		logic	[31:0]	mem_wdata;
	} rob_entry_t;

	typedef struct packed {
		logic 	[31:0]						inst;
		logic 	[SEQ_WIDTH-1:0]				seq;		// sequence number, track program order

		logic 	[31:0]						offset;     // sign-extended imm
		logic   [$clog2(ROB_DEPTH)-1:0]   	rob1;		// base rob entry number
		logic	[31:0]						base;		// base operand data
		logic								rob1_en;

		logic   [$clog2(ROB_DEPTH)-1:0]   	rob2;		// src rob entry number, store only
		logic 	[31:0]						data;		// data to write to memory, store only
		logic								rob2_en;

		logic   [$clog2(ROB_DEPTH)-1:0]   	rob_dest;   // destination rob entry, load only
		logic 	[31:0]						rd_data;

		logic	[31:0]						mem_addr;
		logic 	[3:0]						mem_rmask;
		logic 	[3:0]						mem_wmask;
		logic 	[31:0]						mem_rdata;
		logic	[31:0]						mem_wdata;
	} lsq_entry_t;

endpackage
