
// Testbench for dm_sba_top
`timescale 1ns/1ps

module tb_dm_sba_top;

  // Clock and reset
  logic clk;
  logic rst_n;

  // DMI request
  logic [31:0] dmi_req_data;
  logic [6:0]  dmi_req_addr;
  logic [1:0] dmi_req_op;

  // DMI response
  dm::dmi_resp_t dmi_resp_o;

  // Bus interface
  logic        master_req;
  logic [31:0] master_addr;
  logic        master_we;
  logic [31:0] master_wdata;
  logic [3:0]  master_be;
  logic        master_gnt;
  logic        master_rvalid;
  logic        master_rerr;
  logic        master_rother_err;
  logic [31:0] master_rdata;

  // Internal bus simulation memory
  logic [31:0] memory [0:255];

  // Instantiate DUT
  dm_sba_top u_dm_sba_top (
    .clk_i               (clk),
    .rst_ni              (rst_n),
    .dmi_req_data_i      (dmi_req_data),
    .dmi_req_addr_i      (dmi_req_addr),
    .dmi_req_op_i        (dmi_req_op),
    .sba_dmi_resp_o      (dmi_resp_o),
    .master_req_o        (master_req),
    .master_add_o        (master_addr),
    .master_we_o         (master_we),
    .master_wdata_o      (master_wdata),
    .master_be_o         (master_be),
    .master_gnt_i        (master_gnt),
    .master_r_valid_i    (master_rvalid),
    .master_r_err_i      (master_rerr),
    .master_r_other_err_i(master_rother_err),
    .master_r_rdata_i    (master_rdata)
  );

  // Clock generator
  always #5 clk = ~clk;

  // Test logic
  initial begin
    $display("Start SBA Top Testbench");
    clk = 0;
    rst_n = 0;
    dmi_req_data = 0;
    dmi_req_addr = 0;
    dmi_req_op = '0;
    master_gnt = 1;
    master_rvalid = 0;
    master_rdata = 0;
    master_rerr = 0;
    master_rother_err = 0;

    #20 rst_n = 1;

    // Set sbcs
    dmi_req_op = 2'b10; // Write
    dmi_req_addr = 7'h38; // SBCS
    dmi_req_data = 32'h00030204; //sbaccess = 010, sbautoincrement, sbasize = 001000(32), sbaccess32
    #10;

    // Write sbaddress0
    dmi_req_addr = 7'h39;
    dmi_req_data = 32'h00000010;
    #10;

    // Write sbdata0
    dmi_req_addr = 7'h3c;
    dmi_req_data = 32'habcdabcd;
    #20;

    master_rvalid = 1;
    //master_rdata = 32'hdeadbeef;
    #10;
    master_rvalid = 0;
    #10;

    // Set sbcs
    dmi_req_op = 2'b10; // Write
    dmi_req_addr = 7'h38; // SBCS
    dmi_req_data = 32'h00030204; // sbreadondata, sbaccess = 010, sbautoincrement, sbasize = 001000(32), sbaccess32
    //dmi_req_data = 32'h01610004; // sbreadondata, sbaccess = 010, sbautoincrement, sbasize = 001000(32), sbaccess32    
    #10;    

    // Write sbaddress0
    dmi_req_addr = 7'h39;
    dmi_req_data = 32'h00000011;
    #10;

    // Read sbdata0
    dmi_req_op = 2'b01; // Read
    dmi_req_addr = 7'h3c; // SBData0
    dmi_req_data = 32'h00000000;
    #10;

    master_rvalid = 1;
    master_rdata = 32'h12345678;

    #10;
    master_rvalid = 0;
    #20;

    // // Set sbcs
    // dmi_req_op = 2'b10; // Write
    // dmi_req_addr = 7'h38; // SBCS
    // dmi_req_data = 32'h00030204; //sbaccess = 010, sbautoincrement, sbasize = 001000(32), sbaccess32
    // #10;

    // // Write sbdata0
    // dmi_req_addr = 7'h3c;
    // dmi_req_data = 32'hdeadbeef;
    // #20;

    // master_rvalid = 1;
    // //master_rdata = 32'hdeadbeef;
    // #10;
    // master_rvalid = 0;
    // #10;



    $display("End of Testbench");
    $finish;
  end

endmodule
