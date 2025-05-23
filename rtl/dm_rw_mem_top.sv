module dm_rw_mem_top #(
  parameter int unsigned DbgAddressBits = 12,
  parameter int unsigned DataCount = 2
)(
  input  logic                        clk_i,
  input  logic                        rst_ni,

  // Bus interface
  input  logic                        req_i,
  input  logic                        we_i,
  input  logic [DbgAddressBits-1:0]   addr_i,
  input  logic [31:0]                 wdata_i,
  input  logic [3:0]                  be_i,

  // Control for resume acknowledge
  input  logic                        clear_resumeack_i,

  // Inputs for read operations
  input  logic [31:0]                 progbuf_i[0:DataCount-1],
  input  logic [63:0]                 abs_cmd_i[0:1],
  input  logic [63:0]                 flags_i,

  // Outputs
  output logic [31:0]                 data_o[0:DataCount-1],
  output logic                        data_valid_o,
  output logic [63:0]                 rdata_o,
  output logic                        halted_o,
  output logic                        resuming_o
);

  // Control signals
  logic wr_halted_en, wr_going_en, wr_resuming_en, wr_exception_en, wr_data_en;
  logic [DbgAddressBits-1:0] wr_data_addr;
  logic rd_where_en, rd_data_en, rd_prog_en, rd_abs_cmd_en, rd_flags_en;
  logic [DbgAddressBits-1:0] rd_addr;
  logic clear_resumeack;

  // Control unit
  dm_rw_mem_ctrl_unit #(
    .DbgAddressBits(DbgAddressBits)
  ) u_ctrl (
    .req_i              (req_i),
    .we_i               (we_i),
    .addr_i             (addr_i),
    .clear_resumeack_i  (clear_resumeack_i),

    .wr_halted_en       (wr_halted_en),
    .wr_going_en        (wr_going_en),
    .wr_resuming_en     (wr_resuming_en),
    .wr_exception_en    (wr_exception_en),
    .wr_data_en         (wr_data_en),
    .wr_data_addr_o     (wr_data_addr),

    .rd_where_en        (rd_where_en),
    .rd_data_en         (rd_data_en),
    .rd_prog_en         (rd_prog_en),
    .rd_abs_cmd_en      (rd_abs_cmd_en),
    .rd_flags_en        (rd_flags_en),
    .rd_addr_o          (rd_addr),

    .clear_resumeack_o  (clear_resumeack)
  );

  // Datapath
  dm_rw_mem_datapath #(
    .DbgAddressBits(DbgAddressBits),
    .DataCount(DataCount)
  ) u_datapath (
    .clk_i              (clk_i),
    .rst_ni             (rst_ni),

    .wr_halted_en       (wr_halted_en),
    .wr_going_en        (wr_going_en),
    .wr_resuming_en     (wr_resuming_en),
    .wr_exception_en    (wr_exception_en),
    .wr_data_en         (wr_data_en),
    .wr_data_addr_i     (wr_data_addr),

    .rd_where_en        (rd_where_en),
    .rd_data_en         (rd_data_en),
    .rd_prog_en         (rd_prog_en),
    .rd_abs_cmd_en      (rd_abs_cmd_en),
    .rd_flags_en        (rd_flags_en),
    .rd_addr_i          (rd_addr),

    .wdata_i            (wdata_i),
    .be_i               (be_i),

    .progbuf_i          (progbuf_i),
    .abs_cmd_i          (abs_cmd_i),
    .flags_i            (flags_i),

    .data_o             (data_o),
    .data_valid_o       (data_valid_o),
    .rdata_o            (rdata_o),
    .halted_o           (halted_o),
    .resuming_o         (resuming_o)
  );

endmodule
