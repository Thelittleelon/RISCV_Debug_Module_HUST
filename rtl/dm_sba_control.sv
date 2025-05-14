module dm_sba_control(
    input logic clk_i,
    input logic rst_ni,
    input logic dmactive_i,

    output logic master_req_o,
    output logic [31:0] master_add_o,
    output logic master_we_o,
    output logic [31:0] master_wdata_o,
    output logic [3:0] master_be_o,
    input  logic master_gnt_i,
    input  logic master_r_valid_i,
    input  logic master_r_err_i,
    input  logic master_r_other_err_i, // *other_err_i has priority over *err_i
    input  logic [31:0] master_r_rdata_i,

    input  logic [31:0] sbaddress_i,
    input  logic sbaddress_write_valid_i,
    // control signals in
    input  logic                   sbreadonaddr_i,
    output logic [31:0]    sbaddress_o,
    input  logic                   sbautoincrement_i,
    input  logic [2:0]             sbaccess_i,
    // data in
    input  logic                   sbreadondata_i,
    input  logic [31:0]   sbdata_i,
    input  logic                   sbdata_read_valid_i,
    input  logic                   sbdata_write_valid_i,
    
    // read data out
    output logic [31:0]   sbdata_o,
    output logic                   sbdata_valid_o,

    // control signals
    output logic                   sbbusy_o,
    output logic                   sberror_valid_o, // bus error occurred
    output logic [2:0]             sberror_o // bus error occurred
);

localparam int BeIdxWidth = 2;
dm::sba_state_e state_d, state_q;

logic [31:0] address;
logic req;
logic gnt;
logic we;
logic [3:0] be;
logic [3:0] be_mask;
logic [1:0] be_idx;

assign sbbusy_o = logic'(state_q != dm::Idle);

always_comb begin : p_be_mask
    be_mask = '0;

    // generate byte enable mask
    unique case (sbaccess_i)
        3'b000: begin
            be_mask[be_idx] = '1;
        end
        3'b001: begin
            // be_mask[int'({be_idx[$high(be_idx):1], 1'b0}) +: 2] = '1;
            if (be_idx[1] == 1'b1) begin
                be_mask[3:2] = 2'b11;
            end

            else begin
                be_mask[1:0] = 2'b11;        
            end
        end
        3'b010: begin
            be_mask = '1;
        end
        // 3'b011: be_mask = '1;
        default: ;
    endcase
end

logic [31:0] sbaccess_mask;
assign sbaccess_mask = {32{1'b1}} << sbaccess_i;

logic addr_incr_en;
logic [31:0] addr_incr;
assign addr_incr = (addr_incr_en) ? (32'(1'b1) << sbaccess_i) : '0;
assign sbaddress_o = sbaddress_i + addr_incr;


endmodule