module pec_controller
    import pec_reg_pkg::*;
    import pec_package::*;
#(
    parameter int unsigned SEG_ROW  = 16,
    parameter int unsigned SEG_COL  = 8
) (
    input logic         clk_i,
    input logic         rst_ni,
    input pec_reg2hw_t              reg_file_to_ip_i,
    input logic [15:0][8:0][3:0]    in_bit_buff_i,
    input pec_src_fsm_state_t       src_fsm_state_i,
    input pec_snk_fsm_state_t       snk_fsm_state_i,
    output pec_ctrl_fsm_state_t     ctrl_fsm_state_o,
    output pec_hw2reg_t         ip_to_reg_file_o,
    output logic                trigger_acc_o,
    output logic                clear_acc_o,
    output logic [15:0][8:0]    in_bit_o,
    output logic [SEG_ROW-1:0]  wl_o,
    output logic [SEG_COL-1:0]  bl_o,
    output logic [15:0][15:0]   write_col_sels_o
);

    // Static assignments for controller <=> AXI communication
    assign ip_to_reg_file_o.ctrl.start.de           = 1'b1;
    assign ip_to_reg_file_o.ctrl.start.d            = 1'b0; //reset trigger bit
    assign ip_to_reg_file_o.ctrl.operation.de       = 1'b0;
    assign ip_to_reg_file_o.ctrl.operation.d        = 0;
    assign ip_to_reg_file_o.ctrl.word_line.de       = 1'b0;
    assign ip_to_reg_file_o.ctrl.word_line.d        = 0;
    assign ip_to_reg_file_o.ctrl.bit_line.de        = 1'b0;
    assign ip_to_reg_file_o.ctrl.bit_line.d         = 0;
    assign ip_to_reg_file_o.ctrl.write_col_sels.de  = 1'b0;
    assign ip_to_reg_file_o.ctrl.write_col_sels.d   = 0;
    assign ip_to_reg_file_o.ctrl.state.de           = 1'b1;
    assign ip_to_reg_file_o.ctrl.state.d            = ctrl_fsm_state_o.curr_state; //state to the c_code

    // FSM signals and variables declaration
    pec_operations_e curr_op;
    logic n_trigger_acc;
    logic [2:0] bl_counter,     n_bl_counter;
    logic [2:0] in_bit_counter, n_in_bit_counter;

    // FSM signals and variable for burst operation
    logic [4:0] ft_cnt, n_ft_cnt;           //fetched features counter

    // State logic
    always_ff@(posedge clk_i, negedge rst_ni) begin
        if (!rst_ni)
            ctrl_fsm_state_o.curr_state <= CTRL_CLEAR;
        else
            ctrl_fsm_state_o.curr_state <= ctrl_fsm_state_o.next_state;
    end

    // Next state logic
    always_comb begin
        curr_op = pec_operations_e'(reg_file_to_ip_i.ctrl.operation.q);
        ctrl_fsm_state_o.next_state = ctrl_fsm_state_o.curr_state;
        case(ctrl_fsm_state_o.curr_state)
            CTRL_READY: begin
                if (reg_file_to_ip_i.ctrl.start.q) begin
                    case(curr_op)
                        // Operation clear weights
                        OP_CLEAR: begin
                            ctrl_fsm_state_o.next_state = CTRL_CLEAR;
                        end
                        // Operation load weights
                        OP_LD_WEIGHTS: begin
                            ctrl_fsm_state_o.next_state = CTRL_FETCH_WEIGHTS;
                        end
                        // Operation load bias
                        OP_LD_BIAS: begin
                            ctrl_fsm_state_o.next_state = CTRL_FETCH_BIAS;
                        end
                        // Operation load input and compute
                        OP_COMPUTE: begin
                            ctrl_fsm_state_o.next_state = CTRL_FETCH_INPUT;
                        end
                    endcase
                end
            end
            CTRL_CLEAR: begin
                ctrl_fsm_state_o.next_state = CTRL_READY;
            end
            CTRL_BUSY: begin
                if (curr_op == OP_LD_WEIGHTS) begin
                    if (src_fsm_state_i.next_state == SRC_FETCH_WEIGHTS)
                        ctrl_fsm_state_o.next_state = CTRL_FETCH_WEIGHTS;
                end
                else if (curr_op == OP_COMPUTE) begin
                    if (src_fsm_state_i.next_state == SRC_FETCH_INPUT)
                        ctrl_fsm_state_o.next_state = CTRL_FETCH_INPUT;                
                end
            end
            CTRL_FETCH_WEIGHTS: begin
                if ((src_fsm_state_i.next_state == SRC_BUSY) ||
                    (src_fsm_state_i.next_state == SRC_READY))
                begin
                    ctrl_fsm_state_o.next_state = CTRL_PROGRAMMING;
                end
            end
            CTRL_PROGRAMMING: begin
                if ((bl_counter == 3) && (in_bit_counter == 3))
                    if (src_fsm_state_i.curr_state == SRC_BUSY)
                        ctrl_fsm_state_o.next_state = CTRL_BUSY;
                    else
                        ctrl_fsm_state_o.next_state = CTRL_READY;
            end
            CTRL_FETCH_BIAS: begin
                if (src_fsm_state_i.curr_state == SRC_READY)
                    ctrl_fsm_state_o.next_state = CTRL_READY;
            end
            CTRL_FETCH_INPUT: begin
                if ((src_fsm_state_i.next_state == SRC_BUSY) ||
                    (src_fsm_state_i.next_state == SRC_READY))
                begin
                    ctrl_fsm_state_o.next_state = CTRL_COMPUTE;
                end
            end
            CTRL_COMPUTE: begin
                if ((bl_counter == 3) && (in_bit_counter == 3))
                    ctrl_fsm_state_o.next_state = CTRL_STORE_OUTPUT;
            end
            CTRL_STORE_OUTPUT: begin
                if (snk_fsm_state_i.next_state == SNK_BUSY)
                    ctrl_fsm_state_o.next_state = CTRL_BUSY;
                else if (snk_fsm_state_i.next_state == SNK_READY)
                    ctrl_fsm_state_o.next_state = CTRL_READY;
            end
        endcase
    end

    // Next output logic
    always_comb begin
        // Default values
        n_bl_counter        = 0;
        n_in_bit_counter    = 0;
        n_ft_cnt            = ft_cnt;
        n_trigger_acc       = 0;
        clear_acc_o         = 0;

        case(ctrl_fsm_state_o.curr_state)
            CTRL_READY: begin
                if (reg_file_to_ip_i.ctrl.start.q)
                    n_ft_cnt = 0;   // reset feature counter
            end
            CTRL_CLEAR: begin
                clear_acc_o = 1;
            end
            CTRL_BUSY: begin
                // Controller is idle waiting load or store to finish
            end
            CTRL_FETCH_WEIGHTS: begin
                if (ctrl_fsm_state_o.next_state == CTRL_PROGRAMMING)
                    n_ft_cnt = ft_cnt + 1;
            end
            CTRL_PROGRAMMING: begin
                if (ctrl_fsm_state_o.next_state == CTRL_PROGRAMMING) begin
                    n_bl_counter     = bl_counter + 1;
                    n_in_bit_counter = in_bit_counter + 1;
                end
            end
            CTRL_FETCH_BIAS: begin
                //Controller is idle during bias loading
            end
            CTRL_FETCH_INPUT: begin
                if (ctrl_fsm_state_o.next_state == CTRL_COMPUTE) begin
                    n_bl_counter = bl_counter + 1;
                    n_trigger_acc = 1;
                end
            end
            CTRL_COMPUTE: begin
                n_bl_counter = bl_counter + 1;
                n_in_bit_counter = in_bit_counter;
                if (n_bl_counter == 4) begin
                    n_in_bit_counter    = in_bit_counter + 1;
                    n_bl_counter        = 0;
                end
                if (n_in_bit_counter == 4)
                    n_in_bit_counter = 3;
            end
            CTRL_STORE_OUTPUT: begin
                //Controller is idle durin pixel storing
            end
        endcase

        // Output signals
        if (ctrl_fsm_state_o.curr_state == CTRL_PROGRAMMING)
            for (int f = 0; f < 16; f++) 
                write_col_sels_o[f] = 1 << (reg_file_to_ip_i.ctrl.write_col_sels.q + ft_cnt - 1);   // Convert to One Hot
        else
            write_col_sels_o = 0;
        for (int f = 0; f < 16; f++)
            for (int p = 0; p < 9; p++)
                in_bit_o[f][p] = in_bit_buff_i[f][p][in_bit_counter];
        wl_o = 1 << (reg_file_to_ip_i.ctrl.word_line.q);                // Convert to One Hot
        bl_o = 1 << (reg_file_to_ip_i.ctrl.bit_line.q + bl_counter);    // Convert to One Hot
    end

    // Output registers
    always_ff@(posedge clk_i, negedge rst_ni) begin
        if (!rst_ni) begin
           bl_counter       <= 0;
           in_bit_counter   <= 0;
           ft_cnt           <= 0;
           trigger_acc_o    <= 0;
        end else begin
            bl_counter      <= n_bl_counter;    
            in_bit_counter  <= n_in_bit_counter;
            ft_cnt          <= n_ft_cnt;
            trigger_acc_o   <= n_trigger_acc;
        end
    end

endmodule