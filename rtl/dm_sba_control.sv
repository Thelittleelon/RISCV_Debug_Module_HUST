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


logic [31:0] address;
logic req;
logic gnt;
logic we;
logic [3:0] be;
logic [3:0] be_mask;
logic [1:0] be_idx;



endmodule