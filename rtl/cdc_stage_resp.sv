module cdc_stage_resp (
  input  logic          tck_i,
  input  logic          trst_ni,
  input  dm::dmi_resp_t dmi_resp_i,
  input  logic          dmi_resp_valid_i,
  output logic          dmi_resp_ready_o,

  output dm::dmi_resp_t dmi_resp_o,
  output logic          dmi_resp_valid_o,
  input  logic          dmi_resp_ready_i
);

  dm::dmi_resp_t resp_q;
  logic          valid_q;

  assign dmi_resp_ready_o = ~valid_q || (valid_q && dmi_resp_ready_i);
  assign dmi_resp_o       = resp_q;
  assign dmi_resp_valid_o = valid_q;

  always_ff @(posedge tck_i or negedge trst_ni) begin
    if (!trst_ni) begin
      valid_q <= 1'b0;
      resp_q  <= '0;
    end else begin
      if (dmi_resp_ready_o && dmi_resp_valid_i) begin
        resp_q  <= dmi_resp_i;
        valid_q <= 1'b1;
      end else if (dmi_resp_ready_i && valid_q) begin
        valid_q <= 1'b0;
      end
    end
  end

endmodule
