// DTM Top Module with full CDC chain
module dmi_jtag (
  input  logic         tck_i,
  input  logic         tms_i,
  input  logic         td_i,
  input  logic         trst_ni,
  output logic         td_o,
  output logic         tdo_oe_o,

  input  logic         clk,         // debug clock domain
  input  logic         rst_ni,  // reset for debug domain

  // CDC output interface to Debug Module
  output logic         dbg_dmi_clear_o,
  output dm::dmi_req_t dbg_dmi_req_o,
  output logic         dbg_dmi_req_valid_o,
  input  logic         dbg_dmi_req_ready_i,
  input  dm::dmi_resp_t dbg_dmi_resp_i,
  output logic         dbg_dmi_resp_ready_o,
  input  logic         dbg_dmi_resp_valid_i
);

  // Internal wires
  logic update, capture, shift;
  logic dmi_select, dtmcs_select;
  logic dmi_tdo, dtmcs_tdo;
  logic tdi;
  logic tck;

  // Intermediate signals between TAP and DTM registers
  logic jtag_dmi_clear;
  dm::dmi_req_t jtag_dmi_req;
  logic jtag_dmi_req_valid;
  logic jtag_dmi_req_ready;
  dm::dmi_resp_t jtag_dmi_resp;
  logic jtag_dmi_resp_ready;
  logic jtag_dmi_resp_valid;

  // TAP Controller
  dtm_jtag_tap #(
    .IdCodeValue(32'hDEAD_BEEF)
  ) i_tap (
    .tck_i,
    .tms_i,
    .td_i,
    .trst_ni,
    .td_o,
    .tdo_oe_o,

    .dmi_clear_o(jtag_dmi_clear),
    .update_o(update),
    .capture_o(capture),
    .shift_o(shift),
    .tdi_o(tdi),
    .tck_o(tck),

    .dtmcs_select_o(dtmcs_select),
    .dtmcs_tdo_i(dtmcs_tdo),
    .dmi_select_o(dmi_select),
    .dmi_tdo_i(dmi_tdo)
  );

  // DTM Registers (FSM + CSRs)
  dtm_registers i_dtm_regs (
    .tck_i(tck),
    .trst_ni,
    .update(update),
    .capture(capture),
    .shift(shift),
    .tdi(tdi),
    .dmi_select(dmi_select),
    .dtmcs_select(dtmcs_select),
    .jtag_dmi_clear(jtag_dmi_clear),
    .dmi_tdo(dmi_tdo),
    .dtmcs_tdo(dtmcs_tdo),

    .tck_o(),

    .dmi_clear(),
    .dmi_req_o(jtag_dmi_req),
    .dmi_req_ready(jtag_dmi_req_ready),
    .dmi_req_valid(jtag_dmi_req_valid),
    .dmi_resp(jtag_dmi_resp),
    .dmi_resp_ready(jtag_dmi_resp_ready),
    .dmi_resp_valid(jtag_dmi_resp_valid)
  );

  // CDC Chain (3-stage) for synchronizing between tck domain and clk domain
  dtm_cdc i_dtm_cdc (
    .tck(tck),
    .trst_ni(trst_ni),
    .clk(clk),
    .rst_ni(rst_ni),

    .jtag_dmi_clear_i(jtag_dmi_clear),
    .jtag_dmi_req_i(jtag_dmi_req),
    .jtag_dmi_req_valid_i(jtag_dmi_req_valid),
    .jtag_dmi_req_ready_o(jtag_dmi_req_ready),

    .jtag_dmi_resp_o(jtag_dmi_resp),
    .jtag_dmi_resp_ready_i(jtag_dmi_resp_ready),
    .jtag_dmi_resp_valid_o(jtag_dmi_resp_valid),

    .dbg_dmi_clear_o(dbg_dmi_clear_o),
    .dbg_dmi_req_o(dbg_dmi_req_o),
    .dbg_dmi_req_valid_o(dbg_dmi_req_valid_o),
    .dbg_dmi_req_ready_i(dbg_dmi_req_ready_i),

    .dbg_dmi_resp_i(dbg_dmi_resp_i),
    .dbg_dmi_resp_ready_o(dbg_dmi_resp_ready_o),
    .dbg_dmi_resp_valid_i(dbg_dmi_resp_valid_i)
  );

endmodule
