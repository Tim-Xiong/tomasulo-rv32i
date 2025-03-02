module cache #(
    parameter int WAYS = 4,             // 4 ways
    parameter int DATA_WIDTH = 256,     // 32 bytes,
    parameter int SETS = 16,  
    parameter int TAG_WIDTH = 23,
    parameter int INDEX_WIDTH = 4,
    parameter int OFFSET_WIDTH = 5,
    parameter int MASK_WIDTH = DATA_WIDTH / 8  
)
(
    input   logic           clk,
    input   logic           rst,

    // cpu side signals, ufp -> upward facing port
    input   logic   [31:0]  ufp_addr,
    input   logic   [3:0]   ufp_rmask,
    input   logic   [3:0]   ufp_wmask,
    output  logic   [31:0]  ufp_rdata,
    input   logic   [31:0]  ufp_wdata,
    output  logic           ufp_resp,

    // memory side signals, dfp -> downward facing port
    output  logic   [31:0]  dfp_addr,
    output  logic           dfp_read,
    output  logic           dfp_write,
    input   logic   [255:0] dfp_rdata,
    output  logic   [255:0] dfp_wdata,
    input   logic           dfp_resp
);

    /* data from addr */
    logic   [31:0]              addr_reg;
    logic   [TAG_WIDTH-1:0]     tag;
    logic   [INDEX_WIDTH-1:0]   index;
    logic   [OFFSET_WIDTH-1:0]  offset;

    logic                       read, read_next;   // if the ufp wants to read
    logic                       write, write_next;  // if the ufp wants to write

    /* data for internal arrays */
    // data into arrays
    logic   [TAG_WIDTH:0]       tag_in;         // include MSB dirty bit
    logic   [DATA_WIDTH-1:0]    cache_data_in;
    logic                       dirty_in;       // dirty bit, concate with tag to write into arrays
    logic                       valid;          // valid in
    logic   [MASK_WIDTH-1:0]    wmask;
    logic                       data_web[WAYS];
    logic                       tag_web[WAYS];
    logic                       valid_web[WAYS];// write enable for each of the ways at index
                                                // active low
    logic                       csb;  
    logic   [DATA_WIDTH-1:0]    cache_data_write;    // the data that has been changed by DH, in write cycle

    // data from arrays
    logic   [DATA_WIDTH-1:0]    data_out[WAYS]; // data stored in each ways at index
    logic   [TAG_WIDTH:0]       tag_out[WAYS];  // tags of the ways at index, include dirty bit
    logic                       valid_out[WAYS];// valid bit of the ways at index
    logic                       dirty_out;      // dirty bit of the way that is going to be replaced

    /* plru */
    logic   [1:0]               replace;        // which way to replace

    /* compare tag */
    logic                       hit;            // if tag hits
    logic   [1:0]               hit_way;        // the way that hits

    /* data handler */
    logic   [MASK_WIDTH-1:0]    wmask_dh;

    
    generate for (genvar i = 0; i < WAYS; i++) begin : arrays
        mp_cache_data_array data_array (
            .clk0       (clk),
            .csb0       (csb),
            .web0       (data_web[i]),
            .wmask0     (wmask),
            .addr0      (index),
            .din0       (cache_data_in),
            .dout0      (data_out[i])
        );
        mp_cache_tag_array tag_array (
            .clk0       (clk),
            .csb0       (csb),
            .web0       (tag_web[i]),
            .addr0      (index),
            .din0       (tag_in),
            .dout0      (tag_out[i])
        );
        ff_array #(.WIDTH(1)) valid_array (
            .clk0       (clk),
            .rst0       (rst),
            .csb0       (csb),
            .web0       (valid_web[i]),
            .addr0      (index),
            .din0       (1'b1),
            .dout0      (valid_out[i])
        );
    end endgenerate

    enum int unsigned {
        s_idle, s_compare, s_allocate,
        s_memready, s_writeback
    } state, state_next;

    // compare_tag #(
    //     .WAYS(WAYS),
    //     .TAG_WIDTH(TAG_WIDTH)
    // ) 
    compare_tag ct (
        .csb0(~(read | write)),
        .input_tag(tag),
        .tag_array(tag_out),
        .valid_array(valid_out),
        .hit(hit),
        .hit_way(hit_way)
    );

    data_handler #(
        .WAYS(WAYS),
        .DATA_WIDTH(DATA_WIDTH),
        .OFFSET_WIDTH(OFFSET_WIDTH)
    ) dh (
        .cache_data(data_out[hit_way]),
        .ufp_wdata(ufp_wdata),
        .offset(offset),
        .ufp_wmask(ufp_wmask),
        .read(read),
        .write(write),
        .hit(hit),
        .wmask(wmask_dh),
        .ufp_resp(ufp_resp),
        .ufp_rdata(ufp_rdata),
        .cache_data_write(cache_data_write)
    );

    plru_array #(
        .WAYS(WAYS),
        .SETS(SETS)
    ) pa (
        .clk(clk),
        .rst(rst),
        .index(index),
        .hit(hit),
        .hit_way(hit_way),
        .replace(replace)
    );

    always_ff @( posedge clk ) begin
        if (rst) begin
            state <= s_idle;
            read  <= 1'b0;
            write <= 1'b0;
            addr_reg <= 'bx;
        end else begin
            state <= state_next;
            read  <= read_next;
            write <= write_next;
            addr_reg <= ufp_addr;
        end
    end

    always_comb begin
        state_next = state;
        read_next  = read;
        write_next = write;

        tag        = addr_reg[31:9];
        index      = ufp_addr[8:5];
        offset     = {addr_reg[4:2], 2'b00};

        dirty_in   = 1'b0;
        tag_in     = {dirty_in, tag};
        cache_data_in = cache_data_write;
        csb        = 1'b1; 
        valid      = 1'b0;
        dirty_out  = tag_out[replace][TAG_WIDTH]; 
        wmask      = wmask_dh; // data array wmask;

        dfp_addr   = addr_reg & 32'hffffffe0;
        dfp_read   = 1'b0;
        dfp_write  = 1'b0;
        dfp_wdata  = 256'bx;
        for (int i = 0; i < WAYS; i++) begin
            data_web[i]  = 1'b1;
            tag_web[i]   = 1'b1;
            valid_web[i] = 1'b1;
        end

        unique case (state)
            s_idle: begin
                
                if (ufp_rmask != 0) begin
                    read_next  = 1'b1;
                    state_next = s_compare;
                end else if (ufp_wmask != 0) begin
                    write_next = 1'b1;
                    state_next = s_compare;
                end
                csb = !(read_next ^ write_next); // if there is a r/w happen next cycle, enable the arrays and reads the data
            end
            s_compare: begin
                csb = 1'b0;
                state_next = s_idle;
                read_next  = 1'b0;
                write_next = 1'b0;
                
                if (read) begin
                    if (!hit) begin
                        read_next  = 1'b1;
                        if (dirty_out & valid_out[replace]) begin
                            // dirty and valid, move to write back
                            // --------WIP---------
                            dfp_wdata  = data_out[replace];
                            state_next = s_writeback;
                        end else begin
                            // spare ways or not dirty
                            state_next = s_allocate;
                        end
                    end
                end else if (write) begin
                    if (!hit) begin
                        write_next = 1'b1;
                        if (dirty_out & valid_out[replace]) begin
                            // dirty and valid, move to write back
                            // --------WIP---------
                            dfp_wdata  = data_out[replace];
                            state_next = s_writeback;
                        end else begin
                            // spare ways or not dirty
                            state_next = s_allocate;
                        end
                    end else begin
                        dirty_in          = 1'b1;
                        data_web[hit_way] = 1'b0;
                        tag_web[hit_way]  = 1'b0;
                        tag_in     = {dirty_in, tag};
                    end
                end 
            end
            s_allocate: begin
                read_next   = read;
                write_next  = write;
                dfp_read    = 1'b1;
                
                state_next  = s_allocate;
                if (dfp_resp) begin
                    // write data and tag and valid
                    csb = 1'b0;
                    data_web[replace]   = 1'b0;
                    tag_web[replace]    = 1'b0;
                    valid_web[replace]  = 1'b0;
                    valid               = 1'b1;
                    wmask               = {MASK_WIDTH{1'b1}};
                    tag_in              = {1'b0, tag};
                    cache_data_in       = dfp_rdata;
                    state_next          = s_memready;
                end
            end
            s_memready: begin
                csb        = 1'b0;
                dfp_read   = 1'b0;
                dfp_write  = 1'b0;
                state_next = s_compare;
            end
            s_writeback: begin
                csb        = 1'b0;
                dfp_write  = 1'b1;
                dfp_addr   = {tag_out[replace][22:0], index, 5'b0};
                dfp_wdata  = data_out[replace];
                state_next = s_writeback;
                if (dfp_resp) begin
                    state_next = s_allocate;
                end
            end
            default: begin
                state_next = s_idle;
            end
        endcase

    end
endmodule
