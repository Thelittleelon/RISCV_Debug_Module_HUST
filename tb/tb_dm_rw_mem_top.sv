
`timescale 1ns/1ps

module tb_dm_rw_mem_top;

  parameter DbgAddressBits = 12;
  parameter DataCount = 2;

  logic clk_i;
  logic rst_ni;

  // Bus signals
  logic req_i;
  logic we_i;
  logic [DbgAddressBits-1:0] addr_i;
  logic [31:0] wdata_i;
  logic [3:0] be_i;

  // Resume clear
  logic clear_resumeack_i;

  // ROM contents
  logic [31:0] progbuf_i[0:DataCount-1];
  logic [63:0] abs_cmd_i[0:1];
  logic [63:0] flags_i;

  // Outputs
  logic [31:0] data_o[0:DataCount-1];
  logic data_valid_o;
  logic [63:0] rdata_o;
  logic halted_o;
  logic resuming_o;

  dm_rw_mem_top #(
    .DbgAddressBits(DbgAddressBits),
    .DataCount(DataCount)
  ) dut (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .req_i(req_i),
    .we_i(we_i),
    .addr_i(addr_i),
    .wdata_i(wdata_i),
    .be_i(be_i),
    .clear_resumeack_i(clear_resumeack_i),
    .progbuf_i(progbuf_i),
    .abs_cmd_i(abs_cmd_i),
    .flags_i(flags_i),
    .data_o(data_o),
    .data_valid_o(data_valid_o),
    .rdata_o(rdata_o),
    .halted_o(halted_o),
    .resuming_o(resuming_o)
  );

  // Clock generation
  initial clk_i = 0;
  always #5 clk_i = ~clk_i;

  task reset();
    rst_ni = 0;
    req_i = 0;
    we_i = 0;
    addr_i = 0;
    wdata_i = 0;
    be_i = 0;
    clear_resumeack_i = 0;
    #20;
    rst_ni = 1;
    #10;
  endtask

  task write_mem(input [11:0] addr, input [31:0] data, input [3:0] be);
    @(posedge clk_i);
    req_i = 1;
    we_i = 1;
    addr_i = addr;
    wdata_i = data;
    be_i = be;
    @(posedge clk_i);
    req_i = 0;
    we_i = 0;
    be_i = 0;
  endtask

  task read_mem(input [11:0] addr);
    @(posedge clk_i);
    req_i = 1;
    we_i = 0;
    addr_i = addr;
    @(posedge clk_i);
    req_i = 0;
  endtask

  initial begin
    reset();

    // Test write HALTED
    write_mem(12'h100, 32'hDEAD_BEEF, 4'b1111);

    // Test write RESUMING
    write_mem(12'h110, 32'hBEEF_CAFE, 4'b1111);

    // Test write DATA register 0
    write_mem(12'h380, 32'h11223344, 4'b1111);

    // Test write DATA register 1
    write_mem(12'h384, 32'h55667788, 4'b1111);

    // Test read DATA
    read_mem(12'h380);

    // Read WHERE instruction
    read_mem(12'h300);

    // Set progbuf
    progbuf_i[0] = 32'h12345678;
    progbuf_i[1] = 32'h9ABCDEF0;

    // Read progbuf
    read_mem(12'h340);
    read_mem(12'h344);

    // Set abs_cmd
    abs_cmd_i[0] = 64'hCAFEBABEDEADBEEF;
    abs_cmd_i[1] = 64'h12345678ABCDEF90;

    // Read abstract command
    read_mem(12'h2D8);
    read_mem(12'h2E0);

    // Set flags
    flags_i = 64'hFACEFACE12341234;

    // Read flags
    read_mem(12'h400);

    // End test
    #50;
    $display("TEST FINISHED");
    $finish;
  end
endmodule