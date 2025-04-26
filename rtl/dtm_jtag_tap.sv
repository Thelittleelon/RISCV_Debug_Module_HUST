module dtm_jtag_tap  #(
    parameter [31:0] IdCodeValue = 32'h00000001
)
(
    input logic tck_i,
    input logic tms_i,
    input logic td_i,
    input logic trst_ni,
    output logic td_o,
    output logic tdo_oe_o,

    output logic dmi_clear_o,
    output logic update_o,
    output logic capture_o,
    output logic shift_o,
    output logic tdi_o,
    output logic tck_o,

    output logic dtmcs_select_o,
    input logic dtmcs_tdo_i,

    output logic dmi_select_o,
    input logic dmi_tdo_i
);



typedef enum logic [3:0] {
    TestLogicReset, RunTestIdle, SelectDrScan, CaptureDr, 
    ShiftDr, Exit1Dr, PauseDr, Exit2Dr, UpdateDr, SelectIrScan, 
    CaptureIr, ShiftIr, Exit1Ir, PauseIr, Exit2Ir, UpdateIr
} tap_state_e;

typedef enum logic [4:0] {
    BYPASS0 = 'h0,
    IDCODE = 'h1,
    DTMCSR = 'h10,
    DMIACCESS = 'h11,
    BYPASS1 = 'h1f  
} ir_reg_e;

logic [4:0] jtag_ir_shift_d, jtag_ir_shift_q;
ir_reg_e jtag_ir_d, jtag_ir_q;
logic shift_ir, capture_ir, test_logic_reset, update_ir;
logic bypass_select, idcode_select;

logic shift_dr, capture_dr, update_dr;

logic tdo_sel;

tap_state_e tap_state_d, tap_state_q;

//IR logic
always_comb begin : ir_update
    jtag_ir_shift_d = jtag_ir_shift_q;
    jtag_ir_d = jtag_ir_q;

    if (capture_ir) begin 
        jtag_ir_shift_d = 5'b00101; //reset value to 00101
    end

    if (shift_ir) begin
        jtag_ir_shift_d = {td_i, jtag_ir_shift_q [4:1]}; //shift tdi in
    end

    if (update_ir) begin
        jtag_ir_d = ir_reg_e'(jtag_ir_shift_q); //update ir
    end

    if (test_logic_reset) begin
        jtag_ir_shift_d = '0;
        jtag_ir_d = IDCODE;
    end
end

always_ff @(posedge tck_i or negedge trst_ni) begin
    if(!trst_ni) begin
        jtag_ir_shift_q <= '0;
        jtag_ir_q <= IDCODE;
    end

    else begin
        jtag_ir_shift_q <= jtag_ir_shift_d;
        jtag_ir_q <= jtag_ir_d;
    end
end

//DR logic

//bypass and idcode 
logic [31:0] idcode_d, idcode_q;

logic        bypass_d, bypass_q; 

always_comb begin
  idcode_d = idcode_q;
  bypass_d = bypass_q;

  if (test_logic_reset) begin
    idcode_d = IdCodeValue;
    bypass_d = 1'b0;
  end else begin
    if (capture_dr) begin
      if (idcode_select) idcode_d = IdCodeValue;
      if (bypass_select) bypass_d = 1'b0;
    end

    if (shift_dr) begin
      if (idcode_select)  idcode_d = {td_i, idcode_q[31:1]};
      if (bypass_select)  bypass_d = td_i;
    end
  end
end

//data register selection

always_comb begin: dr_selection
    dtmcs_select_o = 1'b0;
    dmi_select_o = 1'b0;
    bypass_select = 1'b0;
    idcode_select = 1'b0;

    unique case (jtag_ir_q)
        BYPASS0: bypass_select = 1'b1;
        IDCODE: idcode_select  = 1'b1;
        DTMCSR: dtmcs_select_o = 1'b1;
        DMIACCESS: dmi_select_o = 1'b1;
        BYPASS1: bypass_select = 1'b1;
        default: bypass_select = 1'b1;
    endcase
end

//output selection

always_comb begin: output_selection
    if (shift_ir) begin
        tdo_sel = jtag_ir_shift_q [0];
    end

    else begin
        unique case (jtag_ir_q)
            IDCODE: tdo_sel = idcode_q[0];
            DTMCSR: tdo_sel = dtmcs_tdo_i;
            DMIACCESS: tdo_sel = dmi_tdo_i;
            default: tdo_sel = bypass_q;
        endcase
    end

end

always_ff @(posedge tck_i, negedge trst_ni) begin : tdo_regs
    if (!trst_ni) begin
      td_o     <= 1'b0;
      tdo_oe_o <= 1'b0;
    end else begin
      td_o     <= tdo_sel;
      tdo_oe_o <= (shift_ir | shift_dr);
    end
end

//TAP FSM

always_comb begin: tap_fsm
    test_logic_reset = 1'b0;
    
    update_ir = 1'b0;
    shift_ir = 1'b0;
    capture_ir = 1'b0;

    update_dr = 1'b0;
    shift_dr = 1'b0;
    capture_dr = 1'b0;


    unique case (tap_state_q)
      TestLogicReset: begin
        tap_state_d = (tms_i) ? TestLogicReset : RunTestIdle;
        test_logic_reset = 1'b1;
      end
      RunTestIdle: begin
        tap_state_d = (tms_i) ? SelectDrScan : RunTestIdle;
      end
      // DR Path
      SelectDrScan: begin
        tap_state_d = (tms_i) ? SelectIrScan : CaptureDr;
      end
      CaptureDr: begin
        capture_dr = 1'b1;
        tap_state_d = (tms_i) ? Exit1Dr : ShiftDr;
      end
      ShiftDr: begin
        shift_dr = 1'b1;
        tap_state_d = (tms_i) ? Exit1Dr : ShiftDr;
      end
      Exit1Dr: begin
        tap_state_d = (tms_i) ? UpdateDr : PauseDr;
      end
      PauseDr: begin
        tap_state_d = (tms_i) ? Exit2Dr : PauseDr;
      end
      Exit2Dr: begin
        tap_state_d = (tms_i) ? UpdateDr : ShiftDr;
      end
      UpdateDr: begin
        update_dr = 1'b1;
        tap_state_d = (tms_i) ? SelectDrScan : RunTestIdle;
      end
      // IR Path
      SelectIrScan: begin
        tap_state_d = (tms_i) ? TestLogicReset : CaptureIr;
      end

      CaptureIr: begin
        capture_ir = 1'b1;
        tap_state_d = (tms_i) ? Exit1Ir : ShiftIr;
      end

      ShiftIr: begin
        shift_ir = 1'b1;
        tap_state_d = (tms_i) ? Exit1Ir : ShiftIr;
      end
      Exit1Ir: begin
        tap_state_d = (tms_i) ? UpdateIr : PauseIr;
      end
      PauseIr: begin
        // pause_ir = 1'b1; // unused
        tap_state_d = (tms_i) ? Exit2Ir : PauseIr;
      end
      Exit2Ir: begin
        tap_state_d = (tms_i) ? UpdateIr : ShiftIr;
      end

      UpdateIr: begin
        update_ir = 1'b1;
        tap_state_d = (tms_i) ? SelectDrScan : RunTestIdle;
      end
      default: ; // can't actually happen since case is full
    endcase
end

always_ff @(posedge tck_i or negedge trst_ni) begin : update_value 
    if (!trst_ni) begin
      tap_state_q <= TestLogicReset;
      idcode_q    <= IdCodeValue;
      bypass_q    <= 1'b0;
    end else begin
      tap_state_q <= tap_state_d;
      idcode_q    <= idcode_d;
      bypass_q    <= bypass_d;
    end
end

  // Pass through JTAG signals to debug custom DR logic.
  // In case of a single TAP those are just feed-through.
assign tck_o = tck_i;
assign tdi_o = td_i;
assign update_o = update_dr;
assign shift_o = shift_dr;
assign capture_o = capture_dr;
assign dmi_clear_o = test_logic_reset;

endmodule
