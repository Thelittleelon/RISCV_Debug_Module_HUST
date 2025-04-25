module dmi_jtag #(
      parameter logic [31:0] IdcodeValue = 32'h00000DB3
)
(
    input logic clk_i,

    //JTAG signal
    input logic tck_i,
    input logic tms_i,
    input logic trst_ni,
    input logic td_i,
    output logic td_o,

    output dm::dmi_req_t dmi_req_o,
    output logic dmi_req_valid_o,
    input logic dmi_req_ready_i,

    input dm::dmi_resp_t dmi_resp_i,
    output logic dmi_resp_ready_o,
    input logic dmi_resp_valid_i

    output logic clk 
);

dtm_registers i_dtm_registers (
    .tck_i, 
    .trst_ni,
    .update,
    .capture,
    .shift,
    .tdi (td_i),
    .dmi_select,
    .dtmcs_select,
    .dmi_tdo,
    .dtmcs_tdo
);

  dtm_jtag_tap #(
    .IdcodeValue(IdcodeValue)
  ) i_dtm_jtag_tap (
    .tck_i,
    .tms_i,
    .trst_ni,
    .td_i,
    .td_o,
    .tdo_oe_o,
    .testmode_i,
    .tck_o          ( tck              ),
    .dmi_clear_o    ( jtag_dmi_clear   ),
    .update_o       ( update           ),
    .capture_o      ( capture          ),
    .shift_o        ( shift            ),
    .tdi_o          ( tdi              ),
    .dtmcs_select_o ( dtmcs_select     ),
    .dtmcs_tdo_i    ( dtmcs_q[0]       ),
    .dmi_select_o   ( dmi_select       ),
    .dmi_tdo_i      ( dmi_tdo          )
  );



endmodule