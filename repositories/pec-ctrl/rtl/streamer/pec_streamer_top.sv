module pec_streamer_top
    import pec_reg_pkg::pec_reg2hw_t;
    import hwpe_stream_package::*;
    import pec_package::*;
(
    input logic clk_i,
    input logic rst_ni,
    input logic test_mode_i,
    XBAR_TCDM_BUS.Master            tcdm[1:0],
    input pec_reg2hw_t              reg_file_to_ip_i,
    input logic [15:0][15:0]        pixel_i,
    input pec_ctrl_fsm_state_t      ctrl_fsm_state_i,
    output pec_src_fsm_state_t      src_fsm_state_o,
    output pec_snk_fsm_state_t      snk_fsm_state_o,
    output logic[15:0][8:0][3:0]    in_bit_buff_o,
    output logic[15:0][15:0]        bias_o
);
    // ***Bind XBAR TCDM interface with HWPE TCDM interface*** //
    hwpe_stream_intf_tcdm hwpe_tcdm[1:0] (
        .clk(clk_i)
    );

    generate
        for(genvar ii = 0; ii < 2; ii++) begin: tcdm_binding
            assign tcdm[ii].req = hwpe_tcdm[ii].req;
            assign tcdm[ii].add = hwpe_tcdm[ii].add;
            assign tcdm[ii].wen = hwpe_tcdm[ii].wen;
            assign tcdm[ii].be  = hwpe_tcdm[ii].be;
            assign tcdm[ii].wdata = hwpe_tcdm[ii].data;
            assign hwpe_tcdm[ii].gnt     = tcdm[ii].gnt;
            assign hwpe_tcdm[ii].r_data  = tcdm[ii].r_rdata;
            assign hwpe_tcdm[ii].r_valid = tcdm[ii].r_valid;
        end
    endgenerate

    // ***Source module for loading from memory*** ///
    pec_streamer_source pec_streamer_source_i (
        .clk_i              (clk_i),
        .rst_ni             (rst_ni),
        .test_mode_i        (test_mode_i),
        .reg_file_to_ip_i   (reg_file_to_ip_i),
        .hwpe_tcdm          (hwpe_tcdm[0:0]),
        .ctrl_fsm_state_i   (ctrl_fsm_state_i),
        .src_fsm_state_o    (src_fsm_state_o),
        .in_bit_buff_o      (in_bit_buff_o),
        .bias_o             (bias_o)
    );

    pec_streamer_sink pec_streamer_sink_i (
        .clk_i              (clk_i),
        .rst_ni             (rst_ni),
        .test_mode_i        (test_mode_i),
        .reg_file_to_ip_i   (reg_file_to_ip_i),
        .hwpe_tcdm          (hwpe_tcdm[1:1]),
        .pixel_i            (pixel_i),
        .ctrl_fsm_state_i   (ctrl_fsm_state_i),
        .snk_fsm_state_o    (snk_fsm_state_o)
    );

endmodule