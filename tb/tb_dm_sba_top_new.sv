
`timescale 1ns/1ps

module tb_dm_sba_top_new;

  logic clk;
  logic rst_n;

  // DMI Interface
  logic [31:0] dmi_req_data;
  logic [6:0]  dmi_req_addr;
  logic [1:0]  dmi_req_op;
  dm::dmi_resp_t dmi_resp;

  // Dummy signals from SBA controller
  logic [31:0] sbaddress;
  logic [31:0] sbdata_in;
  logic [31:0] sbdata_out;

  logic sbdata_valid;
  logic sberror_valid;

  logic sbautoincrement;
  logic sbreadondata;
  logic sbreadonaddress;
  logic [2:0] sbaccess;

  logic sbbusy;
  logic [2:0] sberror;

  logic sbaddress_write_valid;
  logic sbdata_read_valid;
  logic sbdata_write_valid;

  // Instantiate DUT
  dm_sba_top dut (
    .clk_i(clk),
    .rst_ni(rst_n),
    .dmi_req_data_i(dmi_req_data),
    .dmi_req_addr_i(dmi_req_addr),
    .dmi_req_op_i(dmi_req_op),
    .sba_dmi_resp_o(dmi_resp),
    .sbaddress_o(sbaddress),
    .sbdata_i(sbdata_in),
    .sbdata_o(sbdata_out),
    .sbdata_valid_i(sbdata_valid),
    .sberror_valid_i(sberror_valid),
    .sbautoincrement_o(sbautoincrement),
    .sbreadondata_o(sbreadondata),
    .sbreadonaddr_o(sbreadonaddress),
    .sbaccess_o(sbaccess),
    .sbbusy_i(sbbusy),
    .sberror_i(sberror),
    .sbaddress_write_valid_o(sbaddress_write_valid),
    .sbdata_read_valid_o(sbdata_read_valid),
    .sbdata_write_valid_o(sbdata_write_valid)
  );

  // Clock generation
  always #5 clk = ~clk;

  initial begin
    clk = 0;
    rst_n = 0;
    #20;
    rst_n = 1;

    // Write SBCS to enable autoincrement, readondata, access=word
    dmi_req_op = 2'b10; // WRITE
    dmi_req_addr = 7'h38; // SBCS
    dmi_req_data = 32'h00038204; // sbautoincrement=1, sbreadondata=1, sbaccess=010
    #10;

    // Write SBAddress0
    dmi_req_addr = 7'h39;
    dmi_req_data = 32'h00100000;
    #10;

    // Write SBData0
    dmi_req_addr = 7'h3C;
    dmi_req_data = 32'hAABBCCDD;
    #10;

    // Now simulate a valid data returned from memory
    sbdata_in = 32'h11223344;
    sbdata_valid = 1;
    sberror_valid = 0;
    sbbusy = 0;
    sberror = 0;
    #10;
    sbdata_valid = 0;

    // Read SBData0
    dmi_req_op = 2'b01; // READ
    dmi_req_addr = 7'h3C; // SBData0
    #10;

    $display("Read SBData0 = %h", dmi_resp.data);

    $finish;
  end

endmodule
