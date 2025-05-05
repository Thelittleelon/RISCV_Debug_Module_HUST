module dtm_cdc (
    //DTM Side
    input logic tck_i,
    input logic trst_ni,
    input dm:dmi_req_t jtag_dmi_req_i,
    output logic jtag_dmi_ready_o,
    input logic jtag_dmi_valid_i,
    input logic jtag_dmi_cdc_clear_i,

    output dm:dmi_resp_t jtag_dmi_resp_o,
    output logic jtag_dmi_valid_o,
    input logic jtag_dmi_ready_i

    //DM Side
    input logic clk_i,
    input logic rst_ni,

    output logic dbg_dmi_rst_no,
    output dm:dmi_req_t dbg_dmi_req_o,
    output logic dbg_dmi_valid_o,
    input logic dbg_dmi_ready_i,

    input dm:dmi_resp_t dbg_dmi_ready_i,
    output logic dbg_dmi_ready_o,
    input logic dbg_dmi_valid_i
);



endmodule