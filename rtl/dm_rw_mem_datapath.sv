module dm_rw_mem_datapath #(
  parameter int unsigned DbgAddressBits = 12,
  parameter int unsigned DataCount = 2  
)(
  input  logic                        clk_i,
  input  logic                        rst_ni,

  // Control signals
  input  logic                        wr_halted_en,
  input  logic                        wr_going_en,
  input  logic                        wr_resuming_en,
  input  logic                        wr_exception_en,
  input  logic                        wr_data_en,
  input  logic [DbgAddressBits-1:0]   wr_data_addr_i,

  input  logic                        rd_where_en,
  input  logic                        rd_data_en,
  input  logic                        rd_prog_en,
  input  logic                        rd_abs_cmd_en,
  input  logic                        rd_flags_en,
  input  logic [DbgAddressBits-1:0]   rd_addr_i,

  // Interface signals
  input  logic [31:0]                 wdata_i,
  input  logic [3:0]                  be_i,

  input  logic [31:0]                 progbuf_i[0:DataCount-1],
  input  logic [63:0]                 abs_cmd_i[0:1],
  input  logic [63:0]                 flags_i,

  output logic [31:0]                 data_o[0:DataCount-1],
  output logic                        data_valid_o,

  output logic [63:0]                 rdata_o,

  // States
  output logic                        halted_o,
  output logic                        resuming_o
);

  logic [31:0] data_regs [0:DataCount-1];

  // HALTED & RESUMING flags
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      halted_o   <= 1'b0;
      resuming_o <= 1'b0;
    end else begin
      if (wr_halted_en)
        halted_o <= 1'b1;
      if (wr_resuming_en) begin
        halted_o   <= 1'b0;
        resuming_o <= 1'b1;
      end
    end
  end

  // Write in data register with reset
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      for (int i = 0; i < DataCount; i++) begin
        data_regs[i] <= 32'h0;
      end
    end else if (wr_data_en) begin
      automatic int sel = (wr_data_addr_i - 12'h380) >> 2;
      for (int i = 0; i < 4; i++) begin
        if (be_i[i]) begin
          data_regs[sel][i*8 +: 8] <= wdata_i[i*8 +: 8];
        end
      end
    end
  end

  assign data_valid_o = wr_data_en;
  assign data_o = data_regs;

  // Read data logic
  always_comb begin
    rdata_o = 64'd0;

    if (rd_where_en) begin
      rdata_o = 64'h00000000_0000006F;  // jal x0, 0
    end else if (rd_data_en) begin
      automatic int idx = ((rd_addr_i - 12'h380) >> 3);
      if ((idx + 1) < DataCount)
        rdata_o = {data_regs[idx + 1], data_regs[idx]};
    end else if (rd_prog_en) begin
      automatic int idx = ((rd_addr_i - 12'h340) >> 3);
      rdata_o = {32'h0, progbuf_i[idx]};
    end else if (rd_abs_cmd_en) begin
      automatic int idx = ((rd_addr_i - 12'h2D8) >> 3);
      rdata_o = abs_cmd_i[idx];
    end else if (rd_flags_en) begin
      rdata_o = flags_i;
    end
  end

endmodule
