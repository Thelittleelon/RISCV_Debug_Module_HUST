module cdc_stage (
  input  logic clk_i,
  input  logic rst_ni,

  // INPUT SIDE (source domain, e.g. TCK domain)
  input  logic        dmi_clear_i,
  input  dm::dmi_req_t        dmi_req_i,
  input  logic        dmi_req_valid_i,
  output logic        dmi_req_ready_o,
  output dm::dmi_resp_t       dmi_resp_o,
  output logic        dmi_resp_valid_o,
  input  logic        dmi_resp_ready_i,

  // OUTPUT SIDE (destination domain, e.g. CLK domain)
  output logic        dmi_clear_o,
  output dm::dmi_req_t        dmi_req_o,
  output logic        dmi_req_valid_o,
  input  logic        dmi_req_ready_i,
  input  dm::dmi_resp_t       dmi_resp_i,
  input  logic        dmi_resp_valid_i,
  output logic        dmi_resp_ready_o
);

  // Internal registers for request path
  dm::dmi_req_t  dmi_req_q;
  logic  dmi_req_valid_q;

  // Internal registers for response path
  dm::dmi_resp_t dmi_resp_q;
  logic  dmi_resp_valid_q;

  // dmi_clear sync
  logic dmi_clear_q;
  always_ff @(posedge clk_i) begin
    if (!rst_ni) dmi_clear_q <= 1'b0;
    else         dmi_clear_q <= dmi_clear_i;
  end
  assign dmi_clear_o = dmi_clear_q;

  // ---------------------
  // Request path (A → B)
  // ---------------------
  assign dmi_req_ready_o = ~dmi_req_valid_q || (dmi_req_valid_q && dmi_req_ready_i);
  assign dmi_req_o       = dmi_req_q;
  assign dmi_req_valid_o = dmi_req_valid_q;

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      dmi_req_valid_q <= 1'b0;
      dmi_req_q       <= '0;
    end else begin
      if (dmi_req_ready_o && dmi_req_valid_i) begin
        dmi_req_q       <= dmi_req_i;
        dmi_req_valid_q <= 1'b1;
      end else if (dmi_req_ready_i && dmi_req_valid_q) begin
        dmi_req_valid_q <= 1'b0;
      end
    end
  end

  // ---------------------
  // Response path (B → A)
  // ---------------------
  assign dmi_resp_ready_o = ~dmi_resp_valid_q || (dmi_resp_valid_q && dmi_resp_ready_i);
  assign dmi_resp_o       = dmi_resp_q;
  assign dmi_resp_valid_o = dmi_resp_valid_q;

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      dmi_resp_valid_q <= 1'b0;
      dmi_resp_q       <= '0;
    end else begin
      if (dmi_resp_ready_o && dmi_resp_valid_i) begin
        dmi_resp_q       <= dmi_resp_i;
        dmi_resp_valid_q <= 1'b1;
      end else if (dmi_resp_ready_i && dmi_resp_valid_q) begin
        dmi_resp_valid_q <= 1'b0;
      end
    end
  end

endmodule
