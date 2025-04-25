module tb_dtm_jtag_tap;
  // Declare signals
  logic tck_i;
  logic tms_i;
  logic td_i;
  logic trst_ni;
  logic td_o;
  logic tdo_oe_o;

  logic dmi_clear_o;
  logic update_o;
  logic capture_o;
  logic shift_o;
  logic tdi_o;
  logic tck_o;

  logic dtmcs_select_o;
  logic dtmcs_tdo_i;
  logic dmi_select_o;
  logic dmi_tdo_i;

  // Instantiate DUT
  jtag_tap #(
    .IdCodeValue(32'hDEAD_BEEF)
  ) dut (
    .tck_i(tck_i),
    .tms_i(tms_i),
    .td_i(td_i),
    .trst_ni(trst_ni),
    .td_o(td_o),
    .tdo_oe_o(tdo_oe_o),
    .dmi_clear_o(dmi_clear_o),
    .update_o(update_o),
    .capture_o(capture_o),
    .shift_o(shift_o),
    .tdi_o(tdi_o),
    .tck_o(tck_o),
    .dtmcs_select_o(dtmcs_select_o),
    .dtmcs_tdo_i(dtmcs_tdo_i),
    .dmi_select_o(dmi_select_o),
    .dmi_tdo_i(dmi_tdo_i)
  );

  // Simple backend for tdo inputs
  initial begin
    dtmcs_tdo_i = 1'b0;
    dmi_tdo_i   = 1'b0;
  end

  // Generate clock
  initial begin
    tck_i = 0;
    forever #20 tck_i = ~tck_i;
  end

  // Generate reset
  initial begin
    trst_ni = 0;
    #40 trst_ni = 1;
  end

  // JTAG task: drive TMS to scan IR
  task automatic scan_ir(input [4:0] ir_val);
    begin
      // IR path: Go to ShiftIR state
      tms_i = 1; #40; // TestLogicReset
      tms_i = 0; #40; // RunTestIdle
      tms_i = 1; #40; // SelectDR
      tms_i = 1; #40; // SelectIR
      tms_i = 0; #40; // CaptureIR
      tms_i = 0; #40;// ShiftIR
      
      // Shift 5-bit IR, LSB first
      for (int i = 0; i < 5; i++) begin
        td_i = ir_val[i];
        #40;
      end
      

      tms_i = 1; #40; // Exit1IR
      tms_i = 1; #40; // UpdateIR
      tms_i = 0; #40; // RunTestIdle
    end
  endtask

  // JTAG task: shift in DR (41 bits)
  task automatic scan_dr(input [40:0] dr_val);
    begin
      tms_i = 1; #40; // SelectDR
      tms_i = 0; #40; // CaptureDR
      tms_i = 0; #40; // ShiftDR
      
      // Shift DR, LSB first
      for (int i = 0; i < 41; i++) begin
        td_i = dr_val[i];
        #40;
      end

      tms_i = 1; #40; // Exit1DR
      tms_i = 1; #40; // UpdateDR
      tms_i = 0; #40; // RunTestIdle
    end
  endtask

  // Main stimulus
  initial begin
    // Wait for reset
    td_i = 0;
    tms_i = 1;
    #100;

    // Scan IR = 5'b10000 => DTMCSR (IR opcode 0x10)
    scan_ir(5'b10001);

    // Scan DR = 0x0401FFFFF06 → 41 bits LSB-first
    scan_dr(41'b00100000000011111111111111111111100000110);

    #200 $finish;
  end

  // Dump waveform
  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, tb_dtm_jtag_tap);
  end

endmodule
