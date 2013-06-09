module usb_ep(
    input clk,

    input direction_in,
    input setup,
    input success,
    input[6:0] cnt,

    output reg toggle,
    output reg[1:0] handshake,
    output bank,
    output in_data_valid,

    input ctrl_dir_in,
    output reg[15:0] ctrl_rd_data,
    input[15:0] ctrl_wr_data,
    input ctrl_wr_strobe
    );

localparam
    hs_ack = 2'b00,
    hs_none = 2'b01,
    hs_nak = 2'b10,
    hs_stall = 2'b11;

reg ep_setup;
reg ep_out_full;
reg ep_in_full;
reg ep_out_stall;
reg ep_in_stall;
reg ep_out_toggle;
reg ep_in_toggle;
reg[6:0] ep_in_cnt;
reg[6:0] ep_out_cnt;

assign bank = 1'b0;
assign in_data_valid = (cnt != ep_in_cnt);

always @(*) begin
    if (!direction_in && setup)
        toggle = 1'b0;
    else if (ep_setup)
        toggle = 1'b1;
    else if (direction_in)
        toggle = ep_in_toggle;
    else
        toggle = ep_out_toggle;
end

always @(*) begin
    if (direction_in) begin
        if (!ep_in_stall && !ep_setup && ep_in_full) begin
            handshake = hs_ack;
        end else if (!ep_setup && ep_in_stall) begin
            handshake = hs_stall;
        end else begin
            handshake = hs_nak;
        end
    end else begin
        if (setup || (!ep_out_stall && !ep_setup && !ep_out_full)) begin
            handshake = hs_ack;
        end else if (!ep_setup && ep_out_stall) begin
            handshake = hs_stall;
        end else begin
            handshake = hs_nak;
        end
    end
end

always @(*) begin
    if (ctrl_dir_in)
        ctrl_rd_data = { 1'b0, ep_in_full,  ep_in_cnt,  2'b0, ep_in_toggle,  ep_in_stall,  1'b0, ep_setup, 1'b0, ep_in_full  };
    else
        ctrl_rd_data = { 1'b0, ep_out_full, ep_out_cnt, 2'b0, ep_out_toggle, ep_out_stall, 1'b0, ep_setup, 1'b0, ep_out_full };
end

always @(posedge clk) begin
    if (success) begin
        if (direction_in) begin
            ep_in_toggle <= !ep_in_toggle;
            ep_in_full <= 1'b0;
        end else begin
            if (setup)
                ep_setup <= 1'b1;

            ep_out_toggle <= !ep_out_toggle;
            ep_out_full <= 1'b1;
            ep_out_cnt <= cnt;
        end
    end

    if (ctrl_wr_strobe && ctrl_dir_in) begin
        ep_in_cnt <= ctrl_wr_data[14:8];
        if (ctrl_wr_data[7])
            ep_in_toggle <= 1'b0;
        if (ctrl_wr_data[6])
            ep_in_toggle <= 1'b1;
        ep_in_stall <= ctrl_wr_data[4];
        if (ctrl_wr_data[15] || ctrl_wr_data[1])
            ep_in_full <= 1'b0;
        if (ctrl_wr_data[14] || ctrl_wr_data[0])
            ep_in_full <= 1'b1;
    end

    if (ctrl_wr_strobe && !ctrl_dir_in) begin
        if (ctrl_wr_data[7])
            ep_out_toggle <= 1'b0;
        if (ctrl_wr_data[6])
            ep_out_toggle <= 1'b1;
        ep_out_stall <= ctrl_wr_data[4];
        if (ctrl_wr_data[3])
            ep_setup <= 1'b0;
        if (ctrl_wr_data[15] || ctrl_wr_data[1])
            ep_out_full <= 1'b0;
        if (ctrl_wr_data[14] || ctrl_wr_data[0])
            ep_out_full <= 1'b1;
    end
end

endmodule
