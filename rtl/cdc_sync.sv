module cdc_sync (
  input  logic clk_i,
  input  logic rst_ni,

  input  logic        valid_i,
  input  logic        ready_i,
  input  logic [31:0] data_i,

  output logic        valid_o,
  output logic        ready_o,
  output logic [31:0] data_o
);

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      valid_o <= 0;
      ready_o <= 0;
      data_o  <= 0;
    end else begin
      valid_o <= valid_i;
      ready_o <= ready_i;
      data_o  <= data_i;
    end
  end

endmodule
