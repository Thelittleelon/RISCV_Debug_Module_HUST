module dm_rw_mem_ctrl_unit #(
  parameter int unsigned DbgAddressBits = 12
)(
  input  logic                        req_i,
  input  logic                        we_i,
  input  logic [DbgAddressBits-1:0]   addr_i,
  input  logic                        clear_resumeack_i,

  output logic                        wr_halted_en,
  output logic                        wr_going_en,
  output logic                        wr_resuming_en,
  output logic                        wr_exception_en,
  output logic                        wr_data_en,
  output logic [DbgAddressBits-1:0]   wr_data_addr_o,

  output logic                        rd_where_en,
  output logic                        rd_data_en,
  output logic                        rd_prog_en,
  output logic                        rd_abs_cmd_en,
  output logic                        rd_flags_en,
  output logic [DbgAddressBits-1:0]   rd_addr_o,

  output logic                        clear_resumeack_o
);

  // Constants (same as original spec)
  localparam logic [DbgAddressBits-1:0] HaltedAddr         = 'h100;
  localparam logic [DbgAddressBits-1:0] GoingAddr          = 'h108;
  localparam logic [DbgAddressBits-1:0] ResumingAddr       = 'h110;
  localparam logic [DbgAddressBits-1:0] ExceptionAddr      = 'h118;
  localparam logic [DbgAddressBits-1:0] DataBaseAddr       = 'h380;
  localparam logic [DbgAddressBits-1:0] DataEndAddr        = 'h387;
  localparam logic [DbgAddressBits-1:0] WhereToAddr        = 'h300;
  localparam logic [DbgAddressBits-1:0] ProgBufBaseAddr    = 'h340;
  localparam logic [DbgAddressBits-1:0] ProgBufEndAddr     = 'h37F;
  localparam logic [DbgAddressBits-1:0] AbstractCmdBaseAddr= 'h2D8;
  localparam logic [DbgAddressBits-1:0] AbstractCmdEndAddr = 'h2FF;
  localparam logic [DbgAddressBits-1:0] FlagsBaseAddr      = 'h400;
  localparam logic [DbgAddressBits-1:0] FlagsEndAddr       = 'h7FF;

  always_comb begin
    // Default all outputs to zero
    wr_halted_en       = 1'b0;
    wr_going_en        = 1'b0;
    wr_resuming_en     = 1'b0;
    wr_exception_en    = 1'b0;
    wr_data_en         = 1'b0;
    wr_data_addr_o     = '0;

    rd_where_en        = 1'b0;
    rd_data_en         = 1'b0;
    rd_prog_en         = 1'b0;
    rd_abs_cmd_en      = 1'b0;
    rd_flags_en        = 1'b0;
    rd_addr_o          = addr_i;

    clear_resumeack_o  = clear_resumeack_i;

    if (req_i) begin
      if (we_i) begin
        unique case (addr_i)
          HaltedAddr:       wr_halted_en    = 1'b1;
          GoingAddr:        wr_going_en     = 1'b1;
          ResumingAddr:     wr_resuming_en  = 1'b1;
          ExceptionAddr:    wr_exception_en = 1'b1;
          default: begin
            if (addr_i >= DataBaseAddr && addr_i <= DataEndAddr) begin
              wr_data_en     = 1'b1;
              wr_data_addr_o = addr_i;
            end
          end
        endcase
      end else begin
        unique case (addr_i)
          WhereToAddr:      rd_where_en     = 1'b1;
          default: begin
            if (addr_i >= DataBaseAddr && addr_i <= DataEndAddr)
              rd_data_en = 1'b1;
            else if (addr_i >= ProgBufBaseAddr && addr_i <= ProgBufEndAddr)
              rd_prog_en = 1'b1;
            else if (addr_i >= AbstractCmdBaseAddr && addr_i <= AbstractCmdEndAddr)
              rd_abs_cmd_en = 1'b1;
            else if (addr_i >= FlagsBaseAddr && addr_i <= FlagsEndAddr)
              rd_flags_en = 1'b1;
          end
        endcase
      end
    end
  end

endmodule
