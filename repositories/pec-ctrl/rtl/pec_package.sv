package pec_package;

typedef enum bit [3:0] {
    CTRL_READY,
    CTRL_CLEAR,
    CTRL_BUSY,
    CTRL_FETCH_WEIGHTS,
    CTRL_PROGRAMMING,
    CTRL_FETCH_BIAS,
    CTRL_FETCH_INPUT,
    CTRL_COMPUTE,
    CTRL_STORE_OUTPUT
} pec_controller_fsm_e;

typedef enum bit [2:0] {  
    SRC_READY,
    SRC_BUSY,
    SRC_FETCH_WEIGHTS,
    SRC_FETCH_BIAS,
    SRC_FETCH_INPUT
} pec_streamer_source_fsm_e;

typedef enum bit [1:0] {
    SNK_READY,
    SNK_BUSY,
    SNK_BUFF_OUTPUT,
    SNK_STORE_OUTPUT
} pec_streamer_sink_fsm_e;

typedef enum bit [2:0] {
    OP_NOOP,
    OP_CLEAR,
    OP_LD_WEIGHTS,
    OP_LD_BIAS,
    OP_COMPUTE
} pec_operations_e;

typedef struct packed {
    pec_controller_fsm_e curr_state;
    pec_controller_fsm_e next_state;
} pec_ctrl_fsm_state_t;

typedef struct packed {
    pec_streamer_source_fsm_e curr_state;
    pec_streamer_source_fsm_e next_state;
} pec_src_fsm_state_t;

typedef struct packed {
    pec_streamer_sink_fsm_e curr_state;
    pec_streamer_sink_fsm_e next_state;
} pec_snk_fsm_state_t;


endpackage