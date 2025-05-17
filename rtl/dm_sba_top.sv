module dm_sba_top (
  input  logic              clk_i,
  input  logic              rst_ni,
  input  logic              dmactive_i,

  // DMI interface
  input  logic [31:0]       dmi_req_data_i,
  input  logic [6:0]        dmi_req_addr_i,
  input  logic [1:0]        dmi_req_op_i,
  output dm::dmi_resp_t     sba_dmi_resp_o,

  // System Bus interface
  output logic              master_req_o,
  output logic [31:0]       master_add_o,
  output logic              master_we_o,
  output logic [31:0]       master_wdata_o,
  output logic [3:0]        master_be_o,
  input  logic              master_gnt_i,
  input  logic              master_r_valid_i,
  input  logic              master_r_err_i,
  input  logic              master_r_other_err_i,
  input  logic [31:0]       master_r_rdata_i
);

  // Internal wires
  logic [31:0] sbaddress_ctrl, sbaddress_regs;
  logic [31:0] sbdata_regs, sbdata_ctrl;
  logic [2:0]  sbaccess;
  logic        sbautoincrement, sbreadondata, sbreadonaddress;
  logic        sbdata_valid, sbaddress_write_valid;
  logic        sbdata_read_valid, sbdata_write_valid;
  logic        sbbusy, sberror_valid;
  logic [2:0]  sberror;

  // SBA Control
  dm_sba_control u_sba_ctrl (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .dmactive_i(dmactive_i),

    .master_req_o(master_req_o),
    .master_add_o(master_add_o),
    .master_we_o(master_we_o),
    .master_wdata_o(master_wdata_o),
    .master_be_o(master_be_o),
    .master_gnt_i(master_gnt_i),
    .master_r_valid_i(master_r_valid_i),
    .master_r_err_i(master_r_err_i),
    .master_r_other_err_i(master_r_other_err_i),
    .master_r_rdata_i(master_r_rdata_i),

    .sbaddress_i(sbaddress_regs),
    .sbaddress_write_valid_i(sbaddress_write_valid),
    .sbreadonaddr_i(sbreadonaddress),
    .sbaddress_o(sbaddress_ctrl),
    .sbautoincrement_i(sbautoincrement),
    .sbaccess_i(sbaccess),

    .sbreadondata_i(sbreadondata),
    .sbdata_i(sbdata_regs),
    .sbdata_read_valid_i(sbdata_read_valid),
    .sbdata_write_valid_i(sbdata_write_valid),

    .sbdata_o(sbdata_ctrl),
    .sbdata_valid_o(sbdata_valid),

    .sbbusy_o(sbbusy),
    .sberror_valid_o(sberror_valid),
    .sberror_o(sberror)
  );

  // SBA Registers
  dm_sba_registers u_sba_regs (
    .clk_i(clk_i),
    .rst_ni(rst_ni),

    .dmi_req_data_i(dmi_req_data_i),
    .dmi_req_addr_i(dmi_req_addr_i),
    .dmi_req_op_i(dmi_req_op_i),
    .sba_dmi_resp_o(dmi_resp_o),

    .sbaddress_o(sbaddress_regs),
    .sbaddress_i(sbaddress_ctrl),

    .sbdata_i(sbdata_ctrl),
    .sbdata_o(sbdata_regs),

    .sbdata_valid_i(sbdata_valid),
    .sberror_valid_i(sberror_valid),

    .sbautoincrement_o(sbautoincrement),
    .sbreadondata_o(sbreadondata),
    .sbreadonaddress_o(sbreadonaddress),
    .sbaccess_o(sbaccess),

    .sbbusy_i(sbbusy),
    .sberror_i(sberror),

    .sbaddress_write_valid_o(sbaddress_write_valid),
    .sbdata_read_valid_o(sbdata_read_valid),
    .sbdata_write_valid_o(sbdata_write_valid)
  );

endmodule