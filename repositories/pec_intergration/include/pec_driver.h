#ifndef _PEC_DRIVER_H_
#define _PEC_DRIVER_H_

#include <hal/pulp.h>
#include "pec_reg.h"

#define MAX_WL 16
#define MAX_BL 8

enum PEC_ERROR_CODES {
    STATUS_OK,
    DEVICE_BUSY,
    WL_SIZE_EXCEED,
    BL_SIZE_EXCEED
};
typedef uint8_t pec_status_t;

enum PEC_OPERATIONS {
    OP_NO_OPERATION = PEC_CTRL_OPERATION_VALUE_NO_OPERATION,
    OP_CLEAR        = PEC_CTRL_OPERATION_VALUE_CLEAR,
    OP_LOAD_WEIGHTS = PEC_CTRL_OPERATION_VALUE_LOAD_WEIGHTS,
    OP_LOAD_BIAS    = PEC_CTRL_OPERATION_VALUE_LOAD_BIAS,
    OP_COMPUTE      = PEC_CTRL_OPERATION_VALUE_COMPUTE
};
typedef uint8_t pec_operation_t;

enum PEC_STATES {
    CTRL_READY          = PEC_CTRL_STATE_VALUE_READY,
    CTRL_CLEAR          = PEC_CTRL_STATE_VALUE_CLEAR,
    CTRL_BUSY           = PEC_CTRL_STATE_VALUE_BUSY,
    CTRL_FETCH_WEIGHTS  = PEC_CTRL_STATE_VALUE_FETCH_WEIGHTS,
    CTRL_PROGRAMMING    = PEC_CTRL_STATE_VALUE_PROGRAMMING,
    CTRL_FETCH_BIAS     = PEC_CTRL_STATE_VALUE_FETCH_BIAS,
    CTRL_FETCH_INPUT    = PEC_CTRL_STATE_VALUE_FETCH_INPUT,
    CTRL_COMPUTE        = PEC_CTRL_STATE_VALUE_COMPUTE,
    CTRL_STORE_OUTPUT   = PEC_CTRL_STATE_VALUE_STORE_OUTPUT,
};
typedef uint8_t pec_state_t;

pec_state_t pec_get_state(void);

void pec_wait_till_ready(void);

pec_status_t pec_trigger_operation(pec_operation_t op, uint8_t wl, uint8_t bl, uint8_t write_col_sels);

pec_status_t pec_set_feature_size(uint8_t ft_sz);

pec_status_t pec_set_input_size(uint8_t in_sz);

pec_status_t pec_set_weight_size(uint8_t wg_sz);

pec_status_t pec_set_channel_size(uint8_t ch_sz);

pec_status_t pec_set_layer_sizes(uint8_t ft_sz, uint8_t in_sz, uint8_t wg_sz, uint8_t ch_sz);

pec_status_t pec_set_in_bit_address(uint32_t *in_bit_addr);

pec_status_t pec_set_bias_address(uint32_t *bias_addr);

pec_status_t pec_set_pixel_address(uint32_t *pixel_addr);

#endif //_PEC_DRIVER_H_