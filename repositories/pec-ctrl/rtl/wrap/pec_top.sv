module pec_top
    import pec_reg_pkg::*;
    import pec_package::*;  
#(
    parameter int unsigned AXI_ADDR_WIDTH   = 32,
    localparam int unsigned AXI_DATA_WIDTH  = 32,
    parameter int unsigned AXI_ID_WIDTH     = -1,
    parameter int unsigned AXI_USER_WIDTH   = -1,
    localparam int unsigned SEG_ROW = 16,
    localparam int unsigned SEG_COL = 8
) (
    input logic             clk_i,
    input logic             rst_ni,
    input logic             test_mode_i,
    AXI_BUS.Slave           slv,
    XBAR_TCDM_BUS.Master    tcdm[1:0]
);

    // Signals for AXI <=> controller & streamer
    pec_hw2reg_t ip_to_reg_file;
    pec_reg2hw_t reg_file_to_ip;

    // Signals for controller <=> streamer
    pec_ctrl_fsm_state_t    ctrl_fsm_state;
    pec_src_fsm_state_t     src_fsm_state;
    pec_snk_fsm_state_t     snk_fsm_state;
    logic [15:0][8:0][3:0]  in_bit_buff;

    // Signals for controller & streamer <=> accellerator
    logic               trigger_acc;
    logic               clear_acc;
    logic [15:0][8:0]   in_bit;
    logic [SEG_ROW-1:0] wl;
    logic [SEG_COL-1:0] bl;
    logic [15:0][15:0]  write_col_sels;
    logic [15:0][15:0]  bias;
    logic [15:0][15:0]  pixel;
    
    pec_axi_to_ip #(
        .AXI_ADDR_WIDTH (AXI_ADDR_WIDTH),
        .AXI_DATA_WIDTH (AXI_DATA_WIDTH),
        .AXI_ID_WIDTH   (AXI_ID_WIDTH),
        .AXI_USER_WIDTH (AXI_USER_WIDTH)
    ) pec_axi_to_ip_i (
        .clk_i              (clk_i),
        .rst_ni             (rst_ni),
        .test_mode_i        (test_mode_i),
        .ip_to_reg_file_i   (ip_to_reg_file),
        .slv                (slv),
        .reg_file_to_ip_o   (reg_file_to_ip)
    );

    pec_streamer_top pec_streamer_top_i (
        .clk_i              (clk_i),
        .rst_ni             (rst_ni),
        .test_mode_i        (test_mode_i),
        .tcdm               (tcdm),
        .reg_file_to_ip_i   (reg_file_to_ip),
        .pixel_i            (pixel),
        .ctrl_fsm_state_i   (ctrl_fsm_state),
        .src_fsm_state_o    (src_fsm_state),
        .snk_fsm_state_o    (snk_fsm_state),
        .in_bit_buff_o      (in_bit_buff),
        .bias_o             (bias)
    );

    pec_controller #(
        .SEG_ROW    (SEG_ROW),
        .SEG_COL    (SEG_COL)
    ) pec_controller_i (
        .clk_i              (clk_i),
        .rst_ni             (rst_ni),
        .reg_file_to_ip_i   (reg_file_to_ip),
        .in_bit_buff_i      (in_bit_buff),
        .src_fsm_state_i    (src_fsm_state),
        .snk_fsm_state_i    (snk_fsm_state),
        .ctrl_fsm_state_o   (ctrl_fsm_state),
        .ip_to_reg_file_o   (ip_to_reg_file),
        .trigger_acc_o      (trigger_acc),
        .clear_acc_o        (clear_acc),
        .in_bit_o           (in_bit),
        .wl_o               (wl),
        .bl_o               (bl),
        .write_col_sels_o   (write_col_sels)
    );

    PEC pec_accellerator_i (
        .clk            (clk_i),
        .rst            (clear_acc),
        .start          (trigger_acc),
        .bias           (bias),
        .in_bit         (in_bit),
        .wl             (wl),
        .bl             (bl),
        .write_col_sels (write_col_sels),
        .pixel          (pixel)
    );

endmodule