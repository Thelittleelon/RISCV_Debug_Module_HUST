module cdc_stage_req (
  input  logic         clk_i,
  input  logic         rst_ni,
  input  dm::dmi_req_t dmi_req_i,
  input  logic         dmi_req_valid_i,
  output logic         dmi_req_ready_o,

  output dm::dmi_req_t dmi_req_o,
  output logic         dmi_req_valid_o,
  input  logic         dmi_req_ready_i
);

  dm::dmi_req_t req_q;
  logic         valid_q;

  assign dmi_req_ready_o = ~valid_q || (valid_q && dmi_req_ready_i);
  assign dmi_req_o       = req_q;
  assign dmi_req_valid_o = valid_q;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      valid_q <= 1'b0;
      req_q   <= '0;
    end else begin
      if (dmi_req_ready_o && dmi_req_valid_i) begin
        req_q   <= dmi_req_i;
        valid_q <= 1'b1;
      end else if (dmi_req_ready_i && valid_q) begin
        valid_q <= 1'b0;
      end
    end
  end

endmodule
