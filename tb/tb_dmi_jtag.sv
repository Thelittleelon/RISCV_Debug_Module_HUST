`timescale 1ns/1ps

module tb_dmi_jtag;

  // Clock and reset
  logic tck_i, clk;
  logic trst_ni, rst_ni;

  // JTAG signals
  logic tms_i, td_i;
  logic td_o, tdo_oe_o;

  // Debug-side interface (after CDC)
  dm::dmi_req_t     dbg_dmi_req_o;
  logic             dbg_dmi_req_valid_o;
  logic             dbg_dmi_req_ready_i;

  dm::dmi_resp_t    dbg_dmi_resp_i;
  logic             dbg_dmi_resp_ready_o;
  logic             dbg_dmi_resp_valid_i;

  logic dbg_dmi_clear_o;

  // Clock generation
  initial begin
    tck_i = 0;
    forever #20 tck_i = ~tck_i; // 25 MHz
  end

  initial begin
    clk = 0;
    forever #10 clk = ~clk; // 50 MHz
  end

  // Reset generation
  initial begin
    trst_ni = 0;
    rst_ni = 0;
    #40;
    trst_ni = 1;
    #40;
    rst_ni = 1;
  end

  // Instantiate DUT
  dmi_jtag dut (
    .tck_i(tck_i),
    .tms_i(tms_i),
    .td_i(td_i),
    .trst_ni(trst_ni),
    .td_o(td_o),
    .tdo_oe_o(tdo_oe_o),

    .clk(clk),
    .rst_ni(rst_ni),

    .dbg_dmi_clear_o(dbg_dmi_clear_o),
    .dbg_dmi_req_o(dbg_dmi_req_o),
    .dbg_dmi_req_valid_o(dbg_dmi_req_valid_o),
    .dbg_dmi_req_ready_i(dbg_dmi_req_ready_i),
    .dbg_dmi_resp_i(dbg_dmi_resp_i),
    .dbg_dmi_resp_ready_o(dbg_dmi_resp_ready_o),
    .dbg_dmi_resp_valid_i(dbg_dmi_resp_valid_i)
  );

  // Default debug-side behavior
  initial begin
    dbg_dmi_resp_i = '0;
    dbg_dmi_resp_valid_i = 0;
    dbg_dmi_req_ready_i = 1;
  end

  // JTAG task: scan IR
  task automatic scan_ir(input [4:0] ir_val);
    begin
      tms_i = 1; #40; // TestLogicReset
      tms_i = 0; #40; // RunTestIdle
      tms_i = 1; #40; // SelectDR
      tms_i = 1; #40; // SelectIR
      tms_i = 0; #40; // CaptureIR
      tms_i = 0; #40; // ShiftIR
      for (int i = 0; i < 5; i++) begin
        if (i == 4) tms_i = 1; // Exit1IR
        td_i = ir_val[i];
        #40;
      end
      tms_i = 1; #40; // UpdateIR
      tms_i = 0; #40; // RunTestIdle
    end
  endtask

  // JTAG task: scan DR (41 bits)
  task automatic scan_dr(input [40:0] dr_val);
    begin
      tms_i = 1; #40; // SelectDR
      tms_i = 0; #40; // CaptureDR
      tms_i = 0; #40; // ShiftDR
      for (int i = 0; i < 41; i++) begin
        if (i == 40) tms_i = 1; // Exit1DR
        td_i = dr_val[i];
        #40;
      end
      tms_i = 1; #40; // UpdateDR
      tms_i = 0; #40; // RunTestIdle
    end
  endtask

  // Monitor DMI requests/responses
  always @(posedge clk) begin
    if (dbg_dmi_req_valid_o && dbg_dmi_req_ready_i)
      $display("[%0t] DMI_REQ → addr=%h data=%h op=%0d", $time,
        dbg_dmi_req_o.addr, dbg_dmi_req_o.data, dbg_dmi_req_o.op);
    if (dbg_dmi_resp_ready_o && dbg_dmi_resp_valid_i)
      $display("[%0t] DMI_RESP ← data=%h resp=%0d", $time,
        dbg_dmi_resp_i.data, dbg_dmi_resp_i.resp);
  end

  // Main stimulus
  initial begin
    td_i = 0;
    tms_i = 1;

    #200;

    scan_ir(5'b10001); // DMIACCESS

    // First DMI: Write 0x07FFFFC1 to 0x10
    scan_dr(41'h0401FFFFF06);
    #200;

    dbg_dmi_resp_i.data = 32'h00000000;
    dbg_dmi_resp_i.resp = dm::DTM_SUCCESS;
    dbg_dmi_resp_valid_i = 1;
    #100;
    dbg_dmi_resp_valid_i = 0;

    // Second DMI: Read from 0x10
    scan_dr(41'h04000000001);
    #200;

    dbg_dmi_resp_i.data = 32'hCAFEBABE;
    dbg_dmi_resp_i.resp = dm::DTM_SUCCESS;
    dbg_dmi_resp_valid_i = 1;
    #100;
    dbg_dmi_resp_valid_i = 0;

    #40;

    tms_i = 1; #40; // SelectDR
    tms_i = 0; #40; // CaptureDR 
    tms_i = 0; #40;// ShiftDR


    #200 $finish;
  end

  // Dump waveform
  /*initial begin
    $dumpfile("wave_dmi_jtag.vcd");
    $dumpvars(0, tb_dmi_jtag);
  end*/

endmodule
