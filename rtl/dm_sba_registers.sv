module dm_sba_registers (
  input  logic              clk_i,
  input  logic              rst_ni,

  // DMI request
  input  logic [31:0]       dmi_req_data_i,
  input  logic [6:0]        dmi_req_addr_i,
  input  logic [1:0]        dmi_req_op_i,

  // Outputs to SBA controller
  output logic [31:0]       sbaddress_o,
  input  logic [31:0]       sbaddress_i,

  input  logic [31:0]       sbdata_i,
  output logic [31:0]       sbdata_o,

  input  logic              sbdata_valid_i,
  input  logic              sberror_valid_i,

  output logic              sbautoincrement_o,
  output logic              sbreadondata_o,
  output logic              sbreadonaddress_o,
  output logic [2:0]        sbaccess_o,

  input  logic              sbbusy_i,
  input  logic [2:0]        sberror_i,

  output logic              sbaddress_write_valid_o,
  output logic              sbdata_read_valid_o,
  output logic              sbdata_write_valid_o,

  output dm::dmi_resp_t     sba_dmi_resp_o
);

  // Internal registers
  dm::sbcs_t sbcs_d, sbcs_q;
  logic [63:0] sbdata_d, sbdata_q;
  logic [63:0] sbaddr_d, sbaddr_q;
  logic read_data;

  // Decode op and CSR address
  dm::dtm_op_e  dmi_op;
  dm::dm_csr_e  dm_csr_addr;
  dm::sbcs_t    sbcs;  

  assign dmi_op = dm::dtm_op_e'(dmi_req_op_i);  
  assign dm_csr_addr  = dm::dm_csr_e'({1'b0, dmi_req_addr_i});  


  // Outputs
  assign sbautoincrement_o = sbcs_q.sbautoincrement;
  assign sbreadondata_o    = sbcs_q.sbreadondata;
  assign sbreadonaddress_o = sbcs_q.sbreadonaddr;
  assign sbaccess_o        = sbcs_q.sbaccess;

  assign sbdata_o          = sbdata_q[31:0];
  assign sbaddress_o       = sbaddr_q[31:0];

  // FSM
  always_comb begin
    // Default assignments
    sbcs_d                  = sbcs_q;
    sbaddr_d                = sbaddr_q;
    if (!read_data)
    sbdata_d                = sbdata_q;

    sbaddress_write_valid_o = 1'b0;
    sbdata_read_valid_o     = 1'b0;
    sbdata_write_valid_o    = 1'b0;
    read_data = 1'b0;

    sba_dmi_resp_o.data     = '0;
    sba_dmi_resp_o.resp     = dm::DTM_SUCCESS;

    sbcs = '0;

    // Read
    if (dmi_op == dm::DTM_READ) begin
      unique case (dm_csr_addr)
        dm::SBCS:      sba_dmi_resp_o.data = sbcs_q;
        dm::SBAddress0: sba_dmi_resp_o.data = sbaddr_q[31:0];
        dm::SBAddress1: sba_dmi_resp_o.data = sbaddr_q[63:32];
        dm::SBData0: begin
          if (sbbusy_i) begin
            sbcs_d.sbbusyerror = 1'b1;
            sba_dmi_resp_o.resp = dm::DTM_BUSY;
          end else begin
            sba_dmi_resp_o.data = sbdata_q[31:0];
            sbdata_read_valid_o = (sbcs_q.sberror == 3'b000);
            read_data = 1'b1;
          end
        end
        dm::SBData1: begin
          if (sbbusy_i) begin
            sbcs_d.sbbusyerror = 1'b1;
            sba_dmi_resp_o.resp = dm::DTM_BUSY;
          end else begin
            sba_dmi_resp_o.data = sbdata_q[63:32];
          end
        end
        default:;
      endcase
    end

    // Write
    if (dmi_op == dm::DTM_WRITE) begin
      unique case (dm_csr_addr)
        dm::SBCS: begin
          if (sbbusy_i) begin
            sbcs_d.sbbusyerror = 1'b1;
            sba_dmi_resp_o.resp = dm::DTM_BUSY;
          end else begin
            sbcs = dm::sbcs_t'(dmi_req_data_i);
            sbcs_d = sbcs;
            sbcs_d.sbbusyerror = sbcs_q.sbbusyerror & ~sbcs.sbbusyerror;
            sbcs_d.sberror     = (|sbcs.sberror) ? 3'b000 : sbcs_q.sberror; //questionable
          end
        end
        dm::SBAddress0: begin
          if (sbbusy_i) begin
            sbcs_d.sbbusyerror = 1'b1;
            sba_dmi_resp_o.resp = dm::DTM_BUSY;
          end else begin
            sbaddr_d[31:0] = dmi_req_data_i;
            sbaddress_write_valid_o = (sbcs_q.sberror == 3'b000);
          end
        end
        dm::SBAddress1: begin
          if (sbbusy_i) begin
            sbcs_d.sbbusyerror = 1'b1;
            sba_dmi_resp_o.resp = dm::DTM_BUSY;
          end else begin
            sbaddr_d[63:32] = dmi_req_data_i;
          end
        end

        dm::SBData0: begin
          if (sbbusy_i) begin
            sbcs_d.sbbusyerror = 1'b1;
            sba_dmi_resp_o.resp = dm::DTM_BUSY;
          end else begin
            sbdata_d[31:0] = dmi_req_data_i;
            sbdata_write_valid_o = (sbcs_q.sberror == 3'b000);
          end
        end
        dm::SBData1: begin
          if (sbbusy_i) begin
            sbcs_d.sbbusyerror = 1'b1;
            sba_dmi_resp_o.resp = dm::DTM_BUSY;
          end else begin
            sbdata_d[63:32] = dmi_req_data_i;
          end
        end
        default:;
      endcase
    end

    // Error update
    if (sberror_valid_i) begin
      sbcs_d.sberror = sberror_i;
    end

    // Data update from bus
    if (sbdata_valid_i) begin
      sbdata_d = {32'h0, sbdata_i};  // Extend to 64-bit, if needed
    end 

  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      sbcs_q   <= '0;
      sbaddr_q <= '0;
      sbdata_q <= '0;
    end else begin
      sbcs_q   <= sbcs_d;
      sbaddr_q <= sbaddr_d;
      sbdata_q <= sbdata_d;
    end
  end

endmodule
