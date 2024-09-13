module pec_streamer_sink
    import pec_reg_pkg::pec_reg2hw_t;
    import hwpe_stream_package::*;
    import pec_package::*;
(
    input logic clk_i,
    input logic rst_ni,
    input logic test_mode_i,
    input pec_reg2hw_t              reg_file_to_ip_i,
    hwpe_stream_intf_tcdm.master    hwpe_tcdm[0:0],
    input logic [15:0][15:0]        pixel_i,
    input pec_ctrl_fsm_state_t      ctrl_fsm_state_i,
    output pec_snk_fsm_state_t      snk_fsm_state_o
);

    // ***Setup sink stream*** //
    ctrl_sourcesink_t   sink_ctrl;
    flags_sourcesink_t  sink_flags;

    hwpe_stream_intf_stream #(
        .DATA_WIDTH(32)
    ) i_pixel_stream (
        .clk(clk_i)
    );

    hwpe_stream_intf_stream #(
        .DATA_WIDTH(32)
    ) i_pixel_stream_postfifo (
        .clk(clk_i)
    );

    hwpe_stream_fifo #(
        .DATA_WIDTH( 32 ),
        .FIFO_DEPTH( 2  ),
        .LATCH_FIFO( 0  )
    ) i_pixel_fifo (
        .clk_i   ( clk_i             ),
        .rst_ni  ( rst_ni            ),
        .clear_i ( 1'b0              ),
        .push_i  ( i_pixel_stream.sink            ),
        .pop_o   ( i_pixel_stream_postfifo.source ),
        .flags_o (                   )
    );

    hwpe_stream_sink #(
        .DATA_WIDTH (32),
        .TCDM_FIFO_DEPTH (0)
    ) i_pixel_sink (
        .clk_i              (clk_i),
        .rst_ni             (rst_ni),
        .test_mode_i        (test_mode_i),
        .clear_i            (1'b0),
        .tcdm               (hwpe_tcdm[0:0]),
        .stream             (i_pixel_stream_postfifo.sink),
        .ctrl_i             (sink_ctrl),
        .flags_o            (sink_flags)
    );

    // ***Addresses generation assignment*** //
    logic [7:0]  ft_sz, in_sz, wg_sz, el_sz;
    assign ft_sz = reg_file_to_ip_i.layer_size.ft_sz.q == 0 ? 1 : reg_file_to_ip_i.layer_size.ft_sz.q;
    assign in_sz = reg_file_to_ip_i.layer_size.in_sz.q == 0 ? 1 : reg_file_to_ip_i.layer_size.in_sz.q;
    assign wg_sz = reg_file_to_ip_i.layer_size.wg_sz.q == 0 ? 1 : reg_file_to_ip_i.layer_size.wg_sz.q;
    assign el_sz = in_sz - ((wg_sz / 2) * 2);    //element size = root(# of mac computation)

    logic [7:0]  compr_ch_sz;                //channel size after compression
    logic [15:0] el_off, el_cnt, n_el_cnt;   //stored elements counter (for output)
    assign compr_ch_sz  = (ft_sz + 1) / 2;   //each register fit 2x16bit input channels
    assign el_off       = (((el_cnt / el_sz) * el_sz + (el_cnt % el_sz)) * compr_ch_sz) * 4; //4 bytes

    ctrl_addressgen_t out_addr_gen;
    // Addresses generation for output
    assign out_addr_gen.base_addr             = reg_file_to_ip_i.pixel_addr.q + el_off;
    assign out_addr_gen.trans_size            = compr_ch_sz;
    assign out_addr_gen.line_stride           = 0;
    assign out_addr_gen.line_length           = compr_ch_sz;
    assign out_addr_gen.feat_stride           = 0;
    assign out_addr_gen.feat_length           = 0;
    assign out_addr_gen.feat_roll             = 0;
    assign out_addr_gen.loop_outer            = 0;
    assign out_addr_gen.realign_type          = 0;
    assign out_addr_gen.line_length_remainder = 0;

    // ***FSM of the sink stream*** //
    logic [1:0] wait_cnt, n_wait_cnt;       //wait accelerator to output pixel
    logic [15:0][15:0]  pixel_buff;         //buffer to save pixel result
    logic [7:0] storing_cnt, n_storing_cnt; //transactions storing counter

    // Update current state
    always_ff @(posedge clk_i, negedge rst_ni) begin
        if (~rst_ni)
            snk_fsm_state_o.curr_state <= SNK_READY;
        else
            snk_fsm_state_o.curr_state <= snk_fsm_state_o.next_state;
    end

    // Next state logic
    always_comb begin
        snk_fsm_state_o.next_state = snk_fsm_state_o.curr_state;
        case(snk_fsm_state_o.curr_state)
            SNK_READY: begin
                if (ctrl_fsm_state_i.curr_state == CTRL_STORE_OUTPUT)
                    snk_fsm_state_o.next_state = SNK_BUFF_OUTPUT;
            end
            SNK_BUSY: begin
                if (ctrl_fsm_state_i.curr_state == CTRL_STORE_OUTPUT)
                    snk_fsm_state_o.next_state = SNK_BUFF_OUTPUT;
            end
            SNK_BUFF_OUTPUT: begin
                if (wait_cnt == 2)
                    snk_fsm_state_o.next_state = SNK_STORE_OUTPUT;
            end
            SNK_STORE_OUTPUT: begin
                if (storing_cnt == compr_ch_sz) begin
                    if (el_cnt < (el_sz * el_sz) - 1)
                        snk_fsm_state_o.next_state = SNK_BUSY;
                    else
                        snk_fsm_state_o.next_state = SNK_READY;
                end
            end
        endcase
    end

    // Current state calculations
    always_comb begin
        n_wait_cnt                  = wait_cnt;
        n_storing_cnt               = 0;
        n_el_cnt                    = el_cnt;
        sink_ctrl.req_start         = 0;
        i_pixel_stream.valid        = 0;
        i_pixel_stream.strb         = 4'b1111;
        sink_ctrl.addressgen_ctrl   = out_addr_gen;
        
        
        i_pixel_stream.data[15:0]   = pixel_buff[(storing_cnt * 2)];
        i_pixel_stream.data[31:16]  = pixel_buff[(storing_cnt * 2) + 1];

        case(snk_fsm_state_o.curr_state)
            SNK_READY: begin
                n_wait_cnt = 0;
                n_el_cnt = 0;
            end
            SNK_BUSY: begin
                n_wait_cnt = 0;
            end
            SNK_BUFF_OUTPUT: begin
                n_wait_cnt = wait_cnt + 1;
                if (snk_fsm_state_o.next_state == SNK_STORE_OUTPUT)
                    sink_ctrl.req_start = 1;
            end
            SNK_STORE_OUTPUT: begin
                i_pixel_stream.valid = 1;
                if (i_pixel_stream.ready) begin // One more data stored
                    if (storing_cnt == compr_ch_sz)
                        i_pixel_stream.valid = 0;
                    else
                        n_storing_cnt = storing_cnt + 1;
                end
                if (storing_cnt == compr_ch_sz) begin
                    n_el_cnt = el_cnt + 1;
                end
            end
        endcase
    end

    // Current FF outputs
    always_ff @(posedge clk_i, negedge rst_ni) begin
        if (~rst_ni) begin
            wait_cnt    <= 0;
            storing_cnt <= 0;
            el_cnt      <= 0;
            pixel_buff  <= 0;
        end else begin
            wait_cnt    <= n_wait_cnt;
            storing_cnt <= n_storing_cnt;
            el_cnt      <= n_el_cnt;
            if ((snk_fsm_state_o.curr_state == SNK_BUFF_OUTPUT) &&
                (snk_fsm_state_o.next_state == SNK_STORE_OUTPUT))
            begin
                pixel_buff <= pixel_i;
            end
        end
    end

endmodule