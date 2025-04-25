module dtm_registers_old(
//Signals interacting with TAP
    input logic tck_i,
    input logic trst_ni,
    input logic update,
    input logic capture,
    input logic shift,
    input logic tdi,
    input logic dmi_select,
    input logic dtmcs_select,
    input logic jtag_dmi_clear,
    output logic dmi_tdo,

//Signals interacting with CDC
    output logic tck_o,
    output logic dmi_clear,
    output dm::dmi_req_t dmi_req_o,
    input logic dmi_req_ready,
    output logic dmi_req_valid,
    input dm::dmi_resp_t dmi_resp,
    output logic dmi_resp_ready,
    input dmi_resp_valid
);

typedef enum logic [1:0] {
    DMINoError = 2'h0, DMIReservedError = 2'h1,
    DMIOPFailed = 2'h2, DMIBusy = 2'h3
  } dmi_error_e;

typedef enum logic [2:0] { Idle, Read, WaitReadValid, Write, WaitWriteValid } state_e;


dmi_error_e error_d, error_q;

dm::dtmcs_t dtmcs_d, dtmcs_q;

logic [40:0] dmiaccess_d, dmiaccess_q;

assign dmi_clear = jtag_dmi_clear || (dtmcs_select && update && dtmcs_q.dmihardreset);

assign dmi_resp_ready = 1'b1;

state_e state_d, state_q;
logic [6:0] address_d, address_q;
logic [31:0] data_d, data_q;
dm::dtm_op_e op_d, op_q;
logic error_dmi_busy, error_dmi_op_failed

typedef struct packed {
    logic [6:0] address,
    logic [31:0] data,
    logic [1:0] op
} dmi_t; 

// DTMCS Selection

always_comb begin
    dtmcs_d = dtmcs_q;
    if (dtmcs_select && capture) begin
        dtmcs_d = '{
                    zero1: '0,
                    dmihardreset: 1'b0,
                    dmireset: 1'b0,
                    zero0: '0,
                    idle: 3'd1,
                    dmistat: error_q,
                    abits: 6'd7,
                    version: 4'd1
        };
    end

    else if (dtmcs_select && shift) begin
        dtmcs_d = {tdi, dtmcs_q[31:1]};        
    end    
end



always_ff @(posedge tck_i or negedge trst_ni) begin
    if (!trst_ni) begin
        dtmcs_q <= '0;
    end
    else begin
        dtmcs_q <= dtmcs_d;
    end
end

// DMIACCESS Selection
assign dmi = dmi_t'(dmiaccess_q); //Read the value from Data Register DMIACCESS
assign dmi_req.address = address_q;
assign dmi_req.data = data_q;
assign dmi_req.op = op_q;

always_comb begin: p_fsm
    error_dmi_busy = 1'b0;
    error_dmi_op_failed = 1'b0;

    address_d = address_q;
    data_d = data_q;
    state_d = state_q;
    op_d = op_q;
    error_d = error_q;

    if(dmi_clear) begin
        address_d = 7'h00;
        data_d = 32'h0000;
        state_d = Idle;
        error_d = DMINoError; 
    end

    else begin 
        unique case (state_q)
            Idle: begin
                if(dmi_select && update && (error_q == DMINoError)) begin
                    address_d = dmi.address;
                    data_d = dmi.data;
                    op_d = dtm_op_e'(dmi.op);

                    if (op_d == dm::DTM_READ) begin
                        state_d = Read;
                    end
                    else if (op_d == dm::DTM_WRITE) begin
                        state_d = Write;
                    end
                end
            end

            Read: begin
                dmi_req_valid = 1'b1;
                if (dmi_req_ready) begin
                    state_d = WaitReadValid;
                end 
            end 

            WaitReadValid: begin
            if(dmi_resp_valid) begin
                unique case (dmi_resp.resp)
                    dm::DTM_SUCCESS: begin
                        data_d = dmi_resp.data;
                    end

                    dm::DTM_BUSY: begin
                        data_d = 32'hDEADBEEF;
                        error_dmi_busy = 1'b1;
                    end

                    dm::DTM_ERR: begin
                        data_d = 32'hB051B051;
                        error_dmi_op_failed = 1'b1;
                    end

                    default: begin
                        data_d = 32'hBAADCODE;
                    end
                endcase
                state_d = Idle;
            end
            end 

            Write: begin
                dmi_req_valid = 1'b1;
                if (dmi_req_ready) begin
                    state_d = WaitWriteValid;
                end                 
            end


            WaitWriteValid: begin
            if(dmi_resp_valid) begin
                unique case (dmi_resp.resp)
                    dm::DTM_BUSY: begin
                        data_d = 32'hDEADBEEF;
                        error_dmi_busy = 1'b1;
                    end

                    dm::DTM_ERR: begin
                        data_d = 32'hB051B051;
                        error_dmi_op_failed = 1'b1;
                    end

                    default: ;
                endcase
                state_d = Idle;
            end
            end 

        endcase
    end

    if (update && state_q != Idle && error_q == DMINoError) begin
        error_dmi_busy = 1'b1;
    end

    if (update && ((state_q == Read) | (state_q == WaitReadValid)) && error_q == DMINoError) begin
        error_dmi_busy = 1'b1;
    end

    if (error_dmi_busy) begin
        error_d = DMIBusy;
    end

    if(error_dmi_op_failed) begin
        error_d = DMIOPFailed;
    end

end 


assign dmi_tdo = dmiaccess_q[0];

// Shift logic
always_comb begin
    dmiaccess_d = dmiaccess_q;
    if (dmi_clear) begin
        dmiaccess_d = '0;
    end else if (capture && dmi_select) begin
        dmiaccess_d = {address_q, data_q, error_q};
    end else if (shift && dmi_select) begin
        dmiaccess_d = {tdi, dmiaccess_q[40:1]};
    end
end


always_ff @(posedge tck_i or negedge trst_ni) begin
    if (!trst_ni) begin
        dmiaccess_q <= '0;
        address_q <= '0;
        data_q <= '0;
        op_q <= dm::DTM_READ;
        error_q <= DMINoError;
    end
    
    else begin
        dmiaccess_q <= '0;
        address_q <= address_d;
        data_q <= data_d;
        op_q <= op_d;
        error_q <= error_d;
    end
end



endmodule