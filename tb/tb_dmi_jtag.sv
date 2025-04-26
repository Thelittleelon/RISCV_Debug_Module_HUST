//Testbench for DTM top module
module tb_dmi_jtag;
  // Declare signals
  logic tck_i;
  logic tms_i;
  logic td_i;
  logic trst_ni;
  logic td_o;
  logic tdo_oe_o;

  logic dmi_clear_o;
  dm::dmi_req_t dmi_req_o;
  logic dmi_req_valid_o;
  logic dmi_req_ready_i;
  
  dm::dmi_resp_t dmi_resp_i;
  logic dmi_resp_ready_o;
  logic dmi_resp_valid_i;

  // Instantiate DUT
  dmi_jtag dut (
    .tck_i(tck_i),
    .tms_i(tms_i),
    .td_i(td_i),
    .trst_ni(trst_ni),
    .td_o(td_o),
    .tdo_oe_o(tdo_oe_o),
    .dmi_clear_o(dmi_clear_o),
    .dmi_req_o (dmi_req_o),
    .dmi_req_valid_o (dmi_req_valid_o),
    .dmi_req_ready_i (dmi_req_ready_i),
    .dmi_resp_i (dmi_resp_i),
    .dmi_resp_ready_o (dmi_resp_ready_o),
    .dmi_resp_valid_i (dmi_resp_valid_i)
  );


  initial begin
    dmi_resp_ready_o = 1'b1;
    dmi_req_ready_i = 1'b1;
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
        if (i == 4) tms_i = 1; //Exit1IR
        td_i = ir_val[i];
        #40;
      end
      

      tms_i = 1; #40; // UpdateIR
      tms_i = 0; #40; // RunTestIdle
    end
  endtask

  // JTAG task: shift in DR (41 bits)
  task automatic scan_dr(input [40:0] dr_val);
    begin
      tms_i = 1; #40; // SelectDR
      tms_i = 0; #40; // CaptureDR
      tms_i = 0; #40;// ShiftDR
      
      // Shift DR, LSB first
      for (int i = 0; i < 41; i++) begin
        if (i == 40) tms_i = 1; //Exit1DR
        td_i = dr_val[i];
        #40;
      end

      //tms_i = 1; #40; // Exit1DR
      tms_i = 1; #40; // UpdateDR
      tms_i = 0; #40; // RunTestIdle
    end
  endtask


// Main stimulus
initial begin
    // Reset all input
    td_i = 0;
    tms_i = 1;
    dmi_resp_i = '0;
    dmi_req_ready_i = 1;
    dmi_resp_valid_i = 0; // Ban đầu chưa có response

    #100;

    // Scan IR: Select DMIACCESS instruction
    scan_ir(5'b10001);

    // Scan DR: Write data to DMI
    scan_dr(41'b00100000000011111111111111111111100000110);

    #160;
    
    // Simulate a DMI response
    dmi_resp_i.data = 32'h00000000;
    dmi_resp_i.resp = dm::DTM_SUCCESS;
    dmi_resp_valid_i = 1;

    #100;
    dmi_resp_valid_i = 0;

    scan_dr (41'h04000000001);

    #160;
    
    // Simulate a DMI response
    dmi_resp_i.data = 32'h00000004;
    dmi_resp_i.resp = dm::DTM_SUCCESS;
    dmi_resp_valid_i = 1;

    #100;
    dmi_resp_valid_i = 0;

    #40;

    tms_i = 1; #40; // SelectDR
    tms_i = 0; #40; // CaptureDR 
    tms_i = 0; #40;// ShiftDR

    #100 $finish;
end


  // Dump waveform
  /*initial begin
    $dumpfile("wave_dmi_jtag.vcd");
    $dumpvars(0, tb_dmi_jtag);
  end*/

endmodule
