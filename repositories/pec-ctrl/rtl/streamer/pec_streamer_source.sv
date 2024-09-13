module pec_streamer_source
    import pec_reg_pkg::pec_reg2hw_t;
    import hwpe_stream_package::*;
    import pec_package::*;
(
    input logic clk_i,
    input logic rst_ni,
    input logic test_mode_i,
    input pec_reg2hw_t              reg_file_to_ip_i,
    hwpe_stream_intf_tcdm.master    hwpe_tcdm[0:0],
    input pec_ctrl_fsm_state_t      ctrl_fsm_state_i,
    output pec_src_fsm_state_t      src_fsm_state_o,
    output logic [15:0][8:0][3:0]   in_bit_buff_o,
    output logic [15:0][15:0]       bias_o
);

    // ***Setup source stream*** //
    ctrl_sourcesink_t   source_ctrl;
    flags_sourcesink_t  source_flags;

    hwpe_stream_intf_stream #(
        .DATA_WIDTH(32)
    ) i_in_bit_stream (
        .clk(clk_i)
    );

    hwpe_stream_source #(
        .DATA_WIDTH (32),
        .DECOUPLED  (0)
    ) i_in_bit_source (
        .clk_i              (clk_i),
        .rst_ni             (rst_ni),
        .test_mode_i        (test_mode_i),
        .clear_i            (1'b0),
        .tcdm               (hwpe_tcdm[0:0]),
        .stream             (i_in_bit_stream.source),
        .tcdm_fifo_ready_o  (),
        .ctrl_i             (source_ctrl),
        .flags_o            (source_flags)
    );

    // ***Addresses generation assignment*** //
    logic [7:0]  ft_sz, in_sz, wg_sz, ch_sz, el_sz;
    assign ft_sz = reg_file_to_ip_i.layer_size.ft_sz.q == 0 ? 1 : reg_file_to_ip_i.layer_size.ft_sz.q;
    assign in_sz = reg_file_to_ip_i.layer_size.in_sz.q == 0 ? 1 : reg_file_to_ip_i.layer_size.in_sz.q;
    assign wg_sz = reg_file_to_ip_i.layer_size.wg_sz.q == 0 ? 1 : reg_file_to_ip_i.layer_size.wg_sz.q;
    assign ch_sz = reg_file_to_ip_i.layer_size.ch_sz.q == 0 ? 1 : reg_file_to_ip_i.layer_size.ch_sz.q;
    assign el_sz = in_sz - ((wg_sz / 2) * 2);    //element size = root(# of mac computation)

    logic [7:0] compr_ch_sz;                //channel size after compression
    logic [15:0] ft_off, ft_cnt, n_ft_cnt;  //fetched features counter (for weights)
    logic [15:0] el_off, el_cnt, n_el_cnt;  //fetched elements counter (for input)
    assign compr_ch_sz  = (ch_sz + 7) / 8;  //each register fit 8x4bit input channels
    assign ft_off       = ft_cnt * wg_sz * wg_sz * compr_ch_sz * 4;    //feature offset of base_addr
    assign el_off       = (((el_cnt / el_sz) * in_sz + (el_cnt % el_sz)) * compr_ch_sz) * 4; //4 bytes

    ctrl_addressgen_t wg_addr_gen, bs_addr_gen, in_addr_gen;
    // Addresses generation for weight
    assign wg_addr_gen.base_addr             = reg_file_to_ip_i.in_bit_addr.q + ft_off;
    assign wg_addr_gen.trans_size            = wg_sz * wg_sz * compr_ch_sz;
    assign wg_addr_gen.line_stride           = compr_ch_sz * 4; //4 bytes
    assign wg_addr_gen.line_length           = compr_ch_sz;
    assign wg_addr_gen.feat_stride           = 0;
    assign wg_addr_gen.feat_length           = wg_sz * wg_sz;
    assign wg_addr_gen.feat_roll             = 0;
    assign wg_addr_gen.loop_outer            = 0;
    assign wg_addr_gen.realign_type          = 0;
    assign wg_addr_gen.line_length_remainder = 0;
    // Addresses generation for bias
    assign bs_addr_gen.base_addr             = reg_file_to_ip_i.bias_addr.q;
    assign bs_addr_gen.trans_size            = (ft_sz + 1) / 2;
    assign bs_addr_gen.line_stride           = 0;
    assign bs_addr_gen.line_length           = (ft_sz + 1) / 2; //each register fit 2x16bit bias
    assign bs_addr_gen.feat_stride           = 0;
    assign bs_addr_gen.feat_length           = 0;
    assign bs_addr_gen.feat_roll             = 0;
    assign bs_addr_gen.loop_outer            = 0;
    assign bs_addr_gen.realign_type          = 0;
    assign bs_addr_gen.line_length_remainder = 0;
    // Addressed generation for input
    assign in_addr_gen.base_addr             = reg_file_to_ip_i.in_bit_addr.q + el_off;
    assign in_addr_gen.trans_size            = wg_sz * wg_sz * compr_ch_sz;
    assign in_addr_gen.line_stride           = compr_ch_sz * 4; //4 bytes
    assign in_addr_gen.line_length           = compr_ch_sz;
    assign in_addr_gen.feat_stride           = in_sz * compr_ch_sz * 4; //4 bytes
    assign in_addr_gen.feat_length           = wg_sz;
    assign in_addr_gen.feat_roll             = wg_sz;
    assign in_addr_gen.loop_outer            = 0;
    assign in_addr_gen.realign_type          = 0;
    assign in_addr_gen.line_length_remainder = 0;
    
    // ***FSM of the source stream*** //
    pec_operations_e curr_op;
    logic [7:0] fetching_cnt, n_fetching_cnt;   //transactions fetching counter
    logic [7:0] in_bit_ch_idx, in_bit_in_idx;

    // Update current state
    always_ff @(posedge clk_i, negedge rst_ni) begin
        if (~rst_ni)
            src_fsm_state_o.curr_state <= SRC_READY;
        else
            src_fsm_state_o.curr_state <= src_fsm_state_o.next_state;
    end

    // Next state logic
    always_comb begin
        curr_op = pec_operations_e'(reg_file_to_ip_i.ctrl.operation.q);
        src_fsm_state_o.next_state = src_fsm_state_o.curr_state;
        case(src_fsm_state_o.curr_state)
            SRC_READY: begin
                if  (source_flags.ready_start) begin
                    // Transition to fetch weights
                    if (ctrl_fsm_state_i.curr_state == CTRL_FETCH_WEIGHTS)
                        src_fsm_state_o.next_state = SRC_FETCH_WEIGHTS;
                    // Transition to fetch bias
                    else if (ctrl_fsm_state_i.curr_state == CTRL_FETCH_BIAS)
                        src_fsm_state_o.next_state = SRC_FETCH_BIAS;
                    // Transition to fetch input
                    else if (ctrl_fsm_state_i.curr_state == CTRL_FETCH_INPUT)
                        src_fsm_state_o.next_state = SRC_FETCH_INPUT;
                end
            end
            SRC_BUSY: begin
                if  (source_flags.ready_start) begin
                    // Burst transition to fetch weights
                    if ((curr_op == OP_LD_WEIGHTS) &&
                        (ctrl_fsm_state_i.curr_state == CTRL_BUSY))
                    begin
                        src_fsm_state_o.next_state = SRC_FETCH_WEIGHTS;
                    end
                    // Burst transition to fetch input
                    else if ((curr_op == OP_COMPUTE) &&
                             (ctrl_fsm_state_i.curr_state == CTRL_BUSY))
                    begin
                        src_fsm_state_o.next_state = SRC_FETCH_INPUT;
                    end
                end
            end
            SRC_FETCH_WEIGHTS: begin
                if (source_flags.done) begin    // Fetching finished
                    if (ft_cnt < ft_sz - 1)
                        src_fsm_state_o.next_state = SRC_BUSY;
                    else
                        src_fsm_state_o.next_state = SRC_READY;
                end
            end
            SRC_FETCH_BIAS: begin
                if (source_flags.done)        // Fetching finished
                    src_fsm_state_o.next_state = SRC_READY;
            end
            SRC_FETCH_INPUT: begin
                if (source_flags.done) begin        // Fetching finished
                    if (el_cnt < (el_sz * el_sz) - 1)
                        src_fsm_state_o.next_state = SRC_BUSY;
                    else
                        src_fsm_state_o.next_state = SRC_READY;
                end
            end
        endcase
    end

    // Current state calculations
    always_comb begin
        n_fetching_cnt          = 0;
        n_ft_cnt                = ft_cnt;
        n_el_cnt                = el_cnt;
        source_ctrl.req_start   = 0;
        i_in_bit_stream.ready   = 1;
        source_ctrl.addressgen_ctrl = 0;

        case(src_fsm_state_o.curr_state)
            SRC_READY: begin
                if (src_fsm_state_o.next_state == SRC_FETCH_WEIGHTS) begin
                    source_ctrl.addressgen_ctrl = wg_addr_gen;
                    source_ctrl.req_start = 1;  //trigger memory loads
                end else if (src_fsm_state_o.next_state == SRC_FETCH_BIAS) begin
                    source_ctrl.addressgen_ctrl = bs_addr_gen;
                    source_ctrl.req_start = 1;  //trigger memory loads
                end else if (src_fsm_state_o.next_state == SRC_FETCH_INPUT) begin
                    source_ctrl.addressgen_ctrl = in_addr_gen;
                    source_ctrl.req_start = 1;  //trigger memory loads
                end           
                n_ft_cnt = 0;   //reset feature counter
                n_el_cnt = 0;   //reset element counter
            end
            SRC_BUSY: begin
                if (src_fsm_state_o.next_state == SRC_FETCH_WEIGHTS) begin
                    source_ctrl.addressgen_ctrl = wg_addr_gen;
                    source_ctrl.req_start = 1;  //trigger memory loads
                end else if (src_fsm_state_o.next_state == SRC_FETCH_BIAS) begin
                    source_ctrl.addressgen_ctrl = bs_addr_gen;
                    source_ctrl.req_start = 1;  //trigger memory loads
                end else if (src_fsm_state_o.next_state == SRC_FETCH_INPUT) begin
                    source_ctrl.addressgen_ctrl = in_addr_gen;
                    source_ctrl.req_start = 1;  //trigger memory loads
                end 
            end
            SRC_FETCH_WEIGHTS: begin
                source_ctrl.addressgen_ctrl = wg_addr_gen;
                if (i_in_bit_stream.valid) // One more valid data load
                    n_fetching_cnt = fetching_cnt + 1;

                if (source_flags.done) begin
                    n_ft_cnt = ft_cnt + 1;
                end
            end
            SRC_FETCH_BIAS: begin
                source_ctrl.addressgen_ctrl = bs_addr_gen;
                if (i_in_bit_stream.valid) // One more valid data load
                    n_fetching_cnt = fetching_cnt + 1;
            end
            SRC_FETCH_INPUT: begin
                source_ctrl.addressgen_ctrl = in_addr_gen;
                if (i_in_bit_stream.valid) // One more valid data load
                    n_fetching_cnt = fetching_cnt + 1;

                if (source_flags.done) begin
                    n_el_cnt = el_cnt + 1;
                end
            end
        endcase

        in_bit_ch_idx = (fetching_cnt % ((ch_sz + 7) / 8)) * 8;
        in_bit_in_idx = (fetching_cnt / ((ch_sz + 7) / 8));
    end

    // Current FF outputs
    always_ff @(posedge clk_i, negedge rst_ni) begin
        if (~rst_ni) begin
            fetching_cnt    <= 0;
            ft_cnt          <= 0;
            el_cnt          <= 0;
            in_bit_buff_o   <= 0;
            bias_o          <= 0;
        end else begin
            fetching_cnt    <= n_fetching_cnt;
            ft_cnt          <= n_ft_cnt;
            el_cnt          <= n_el_cnt;
            if (i_in_bit_stream.valid) begin
                case(src_fsm_state_o.curr_state)
                    SRC_FETCH_WEIGHTS: begin
                        for (int i = 0; (i < 8) && ((in_bit_ch_idx + i) < ch_sz); i++)
                            in_bit_buff_o[in_bit_ch_idx + i][in_bit_in_idx] <= i_in_bit_stream.data[(i*4) +: 4];
                    end
                    SRC_FETCH_BIAS: begin
                        bias_o[fetching_cnt * 2]        = i_in_bit_stream.data[15:0];
                        bias_o[(fetching_cnt * 2) + 1]  = i_in_bit_stream.data[31:16];
                    end
                    SRC_FETCH_INPUT: begin
                        for (int i = 0; (i < 8) && ((in_bit_ch_idx + i) < ch_sz); i++)
                            in_bit_buff_o[in_bit_ch_idx + i][in_bit_in_idx] <= i_in_bit_stream.data[(i*4) +: 4];
                    end
                endcase
            end
        end
    end

endmodule