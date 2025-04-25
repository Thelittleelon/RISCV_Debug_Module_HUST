//This is the DTM top module
module dmi_jtag (
  input  logic         tck_i,
  input  logic         tms_i,
  input  logic         td_i,
  input  logic         trst_ni,
  output logic         td_o,
  output logic         tdo_oe_o,

  // CDC interface to Debug Module
  output logic         dmi_clear_o,
  output dm::dmi_req_t dmi_req_o,
  output logic         dmi_req_valid_o,
  input  logic         dmi_req_ready_i,
  input  dm::dmi_resp_t dmi_resp_i,
  output logic         dmi_resp_ready_o,
  input  logic         dmi_resp_valid_i
);

  // Internal wires
  logic update, capture, shift;
  logic dmi_select, dtmcs_select;
  logic dmi_tdo, dtmcs_tdo;
  logic tdi;
  logic tck;

  // Instantiate TAP controller
  dtm_jtag_tap #(
    .IdCodeValue(32'hDEAD_BEEF)
  ) i_tap (
    .tck_i,
    .tms_i,
    .td_i,
    .trst_ni,
    .td_o,
    .tdo_oe_o,

    .dmi_clear_o,       // output
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

  // Instantiate DTM Registers (FSM + CSR)
  dtm_registers i_dtm_regs (
    .tck_i(tck),
    .trst_ni,
    .update(update),
    .capture(capture),
    .shift(shift),
    .tdi(tdi),
    .dmi_select(dmi_select),
    .dtmcs_select(dtmcs_select),
    .jtag_dmi_clear(dmi_clear_o),
    .dmi_tdo(dmi_tdo),
    .dtmcs_tdo(dtmcs_tdo),

    .tck_o(), // optional, ignore if unused

    .dmi_clear(), // already driven by TAP
    .dmi_req_o(dmi_req_o),
    .dmi_req_ready(dmi_req_ready_i),
    .dmi_req_valid(dmi_req_valid_o),
    .dmi_resp(dmi_resp_i),
    .dmi_resp_ready(dmi_resp_ready_o),
    .dmi_resp_valid(dmi_resp_valid_i)
  );

endmodule
