module dtm_cdc (
  input  logic         tck,
  input  logic         trst_ni,
  input  logic         clk,
  input  logic         rst_ni,

  // JTAG domain
  input  logic             jtag_dmi_clear_i,
  input  dm::dmi_req_t     jtag_dmi_req_i,
  input  logic             jtag_dmi_req_valid_i,
  output logic             jtag_dmi_req_ready_o,

  output dm::dmi_resp_t    jtag_dmi_resp_o,
  input  logic             jtag_dmi_resp_ready_i,
  output logic             jtag_dmi_resp_valid_o,

  // Debug domain
  output logic             dbg_dmi_clear_o,
  output dm::dmi_req_t     dbg_dmi_req_o,
  output logic             dbg_dmi_req_valid_o,
  input  logic             dbg_dmi_req_ready_i,

  input  dm::dmi_resp_t    dbg_dmi_resp_i,
  output logic             dbg_dmi_resp_ready_o,
  input  logic             dbg_dmi_resp_valid_i
);

  // ---------------------------------------------------------------------------
  // Synchronize dmi_clear signal (JTAG -> System domain)
  // ---------------------------------------------------------------------------
  logic [1:0] dmi_clear_sync;
  always_ff @(posedge clk or negedge rst_ni) begin
    if (!rst_ni)
      dmi_clear_sync <= 2'b00;
    else
      dmi_clear_sync <= {dmi_clear_sync[0], jtag_dmi_clear_i};
  end
  assign dbg_dmi_clear_o = dmi_clear_sync[1];

  // ---------------------------------------------------------------------------
  // Internal intermediate wires
  // ---------------------------------------------------------------------------
  // Request path
  dm::dmi_req_t dmi_req_mid;
  logic         dmi_req_valid_mid, dmi_req_ready_mid;

  // Response path
  dm::dmi_resp_t dmi_resp_mid_1, dmi_resp_mid_2;
  logic          dmi_resp_valid_mid_1, dmi_resp_ready_mid_1;
  logic          dmi_resp_valid_mid_2, dmi_resp_ready_mid_2;

  // ---------------------------------------------------------------------------
  // Request Synchronization (TCK → CLK)
  // ---------------------------------------------------------------------------
  cdc_stage_req stage_req_0 (
    .clk_i           (clk),
    .rst_ni          (rst_ni),
    .dmi_req_i       (jtag_dmi_req_i),
    .dmi_req_valid_i (jtag_dmi_req_valid_i),
    .dmi_req_ready_o (jtag_dmi_req_ready_o),
    .dmi_req_o       (dmi_req_mid),
    .dmi_req_valid_o (dmi_req_valid_mid),
    .dmi_req_ready_i (dmi_req_ready_mid)
  );

  cdc_stage_req stage_req_1 (
    .clk_i           (clk),
    .rst_ni          (rst_ni),
    .dmi_req_i       (dmi_req_mid),
    .dmi_req_valid_i (dmi_req_valid_mid),
    .dmi_req_ready_o (dmi_req_ready_mid),
    .dmi_req_o       (dbg_dmi_req_o),
    .dmi_req_valid_o (dbg_dmi_req_valid_o),
    .dmi_req_ready_i (dbg_dmi_req_ready_i)
  );

  // ---------------------------------------------------------------------------
  // Response Synchronization (CLK → TCK)
  // ---------------------------------------------------------------------------
  cdc_stage_resp stage_resp_0 (
    .tck_i            (tck),
    .trst_ni          (trst_ni),
    .dmi_resp_i       (dbg_dmi_resp_i),
    .dmi_resp_valid_i (dbg_dmi_resp_valid_i),
    .dmi_resp_ready_o (dbg_dmi_resp_ready_o),
    .dmi_resp_o       (dmi_resp_mid_1),
    .dmi_resp_valid_o (dmi_resp_valid_mid_1),
    .dmi_resp_ready_i (dmi_resp_ready_mid_1)
  );

  cdc_stage_resp stage_resp_1 (
    .tck_i            (tck),
    .trst_ni          (trst_ni),
    .dmi_resp_i       (dmi_resp_mid_1),
    .dmi_resp_valid_i (dmi_resp_valid_mid_1),
    .dmi_resp_ready_o (dmi_resp_ready_mid_1),
    .dmi_resp_o       (dmi_resp_mid_2),
    .dmi_resp_valid_o (dmi_resp_valid_mid_2),
    .dmi_resp_ready_i (dmi_resp_ready_mid_2)
  );

  cdc_stage_resp stage_resp_2 (
    .tck_i            (tck),
    .trst_ni          (trst_ni),
    .dmi_resp_i       (dmi_resp_mid_2),
    .dmi_resp_valid_i (dmi_resp_valid_mid_2),
    .dmi_resp_ready_o (dmi_resp_ready_mid_2),
    .dmi_resp_o       (jtag_dmi_resp_o),
    .dmi_resp_valid_o (jtag_dmi_resp_valid_o),
    .dmi_resp_ready_i (jtag_dmi_resp_ready_i)
  );

endmodule
