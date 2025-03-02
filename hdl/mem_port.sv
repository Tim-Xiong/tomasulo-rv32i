module memport
import rv32i_types::*; 
#(
    parameter int DATA_WIDTH = 256
)
(
  
    input   logic           clk,
    input   logic           rst,
    // from I cache
    input   logic   [31:0]  imem_req_addr,
    input   logic           imem_req_read, 
    // from D cache
    input   logic   [31:0]  dmem_req_addr,
    input   logic           dmem_req_read,
    input   logic           dmem_req_write,
    input   logic   [DATA_WIDTH-1:0]  dmem_req_wdata,

    // from bmem
    input   logic           bmem_ready,
    input   logic   [31:0]  bmem_raddr,
    input   logic   [63:0]  bmem_rdata,
    input   logic           bmem_rvalid,         

    // to I cache
    output  logic           imem_req_resp,
    output  logic  [DATA_WIDTH-1:0]   imem_req_rdata,
    
    // to D cache
    output  logic           dmem_req_resp,
    output  logic  [DATA_WIDTH-1:0]   dmem_req_rdata,

    // to bmem
    output  logic   [31:0]  bmem_addr,
    output  logic           bmem_read,
    output  logic           bmem_write,
    output  logic   [63:0]  bmem_wdata
);

    logic [DATA_WIDTH-1:0]  data_holder;

    /* out regs, these should be high for 1 cycle for each request */
    logic [31:0]            bmem_addr_reg;
    logic                   bmem_read_reg;
    logic                   bmem_write_reg;
    // logic [63:0]            bmem_wdata_reg;
    logic [31:0]            bmem_raddr_reg;
    
    logic                   imem_req_ack; // imem req has been served
    logic                   dmem_req_ack;

    logic data_ready;   // the data holder is filled with data and ready to be sned back
    logic write_ready;  // the write has been served for 4 cycles
    logic data_miss;
    logic [1:0] counter;
    logic [1:0] wcounter;

    always_comb begin: send_resp
        imem_req_resp   = 1'b0;
        imem_req_rdata  = 256'bx;
        dmem_req_resp   = 1'b0;
        dmem_req_rdata  = 256'bx;

        bmem_addr       = bmem_addr_reg;
        bmem_read       = bmem_read_reg;
        // bmem_write      = dmem_req_write;
        bmem_write      = bmem_write_reg;
        // bmem_wdata      = dmem_req_wdata[];
        data_miss       = 1'b0;
        if (data_ready) begin
            if (bmem_raddr_reg == imem_req_addr & imem_req_ack) begin
                imem_req_resp  = 1'b1;
                imem_req_rdata = data_holder;
            end else if (bmem_raddr_reg == dmem_req_addr & dmem_req_ack) begin
                dmem_req_resp  = 1'b1;
                dmem_req_rdata = data_holder;
            end else begin
                data_miss = 1'b1;
            end
        end 
        if (write_ready) begin
            dmem_req_resp = 1'b1;
        end
    end

    always_ff @ (posedge clk) begin: bmem_ops
        if (rst) begin 
            bmem_addr_reg       <= 32'bx;
            bmem_write_reg      <= 1'b0;
            bmem_read_reg       <= 1'b0;
            // bmem_wdata_reg      <= 64'bx;
            bmem_raddr_reg      <= bmem_raddr;
            imem_req_ack        <= 1'b0;
            dmem_req_ack        <= 1'b0;

        end else begin
            bmem_raddr_reg      <= bmem_raddr;
            // bmem_read_reg       <= 1'b0;
            // bmem_write_reg      <= 1'b0;
            // should serve dmem first
            // ---------- WIP --------------
            if (dmem_req_read & bmem_ready & !dmem_req_ack) begin
                if (!dmem_req_ack) begin
                    bmem_read_reg   <= 1'b1;
                    bmem_write_reg  <= 1'b0;
                    bmem_addr_reg   <= dmem_req_addr;
                    dmem_req_ack    <= 1'b1;
                end
            end else if (dmem_req_write & bmem_ready & !dmem_req_ack) begin
                if (!dmem_req_ack) begin
                    bmem_read_reg   <= 1'b0;
                    bmem_write_reg  <= 1'b1;
                    dmem_req_ack    <= 1'b1;
                    bmem_addr_reg   <= dmem_req_addr;
                end
            end else if (imem_req_read & bmem_ready & !imem_req_ack) begin // imem is requsting a read and has not been served yet
                if (!imem_req_ack) begin
                    bmem_read_reg   <= 1'b1;
                    bmem_write_reg  <= 1'b0;
                    bmem_addr_reg   <= imem_req_addr;
                    imem_req_ack    <= 1'b1;
                end
            end else if (bmem_read_reg) begin
                bmem_read_reg   <= 1'b0;
            end 
            else if (bmem_write_reg && wcounter == 3) begin
                bmem_write_reg  <= 1'b0;
            end
        end
        if (imem_req_ack & imem_req_resp || data_miss) begin
            imem_req_ack <= 1'b0;
        end
        if (dmem_req_ack & dmem_req_resp || data_miss) begin
            dmem_req_ack <= 1'b0;
        end
    end

    always_ff @ (posedge clk) begin: data_pack
        if (rst) begin
            data_holder         <= {DATA_WIDTH{1'b0}};
            counter             <= 2'd0;
            data_ready          <= 1'b0;
        end else begin
            if (bmem_rvalid) begin
                data_holder[(counter*64)+:64] <= bmem_rdata;
                counter <= counter + 1'b1;
                if (counter == 3) begin
                    data_ready <= 1'b1;
                    
                end else begin
                    data_ready <= 1'b0;
                end
            end  
            if (data_ready) begin
                data_ready <= 1'b0;
            end    
        end
    end

    always_ff @ (posedge clk) begin: data_unpack
        if (rst) begin
            wcounter             <= 2'd0;
        end else begin
            if (bmem_write) begin
                // bmem_wdata <= dmem_req_wdata[(counter*64)+:64];
                wcounter   <= wcounter + 1'b1;
                if (wcounter == 3) begin
                    write_ready <= 1'b1;
                    
                end else begin
                    write_ready <= 1'b0;
                end
            end else begin
                wcounter <= 2'b0;
                write_ready <= 1'b0;
            end    
        end
    end
    always_comb begin: assign_wdata
        bmem_wdata = dmem_req_wdata[(wcounter*64)+:64];
    end
endmodule