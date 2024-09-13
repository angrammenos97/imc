#include "pec_driver.h"

#define PEC0_BASE_ADDR 0x1A400000

pec_state_t pec_get_state(void)
{
    uint32_t volatile *ctrl_reg = (uint32_t*)(PEC0_BASE_ADDR + PEC_CTRL_REG_OFFSET);
    pec_state_t state = (*ctrl_reg & (PEC_CTRL_STATE_MASK << PEC_CTRL_STATE_OFFSET)) >> PEC_CTRL_STATE_OFFSET;
    return state;
}

void pec_wait_till_ready(void)
{
    while (pec_get_state() != CTRL_READY);
}

pec_status_t pec_trigger_operation(pec_operation_t op, uint8_t wl, uint8_t bl, uint8_t write_col_sels)
{
    if (wl >= MAX_WL)
        return WL_SIZE_EXCEED;
    else if (bl >= MAX_BL)
        return BL_SIZE_EXCEED;
    else if (pec_get_state() != CTRL_READY)
        return DEVICE_BUSY;
    uint32_t volatile *ctrl_reg = (uint32_t*)(PEC0_BASE_ADDR + PEC_CTRL_REG_OFFSET);
    uint32_t new_reg_val = 0;
    // Triggering start
    new_reg_val |= ((uint32_t) 1) << PEC_CTRL_START_BIT;   //set bit
    // Setting operation bit field
    new_reg_val |= ((uint32_t)op) << PEC_CTRL_OPERATION_OFFSET;
    // Setting word line bit field
    new_reg_val |= ((uint32_t)wl) << PEC_CTRL_WORD_LINE_OFFSET;
    // Setting bit line bit field
    new_reg_val |= ((uint32_t)bl) << PEC_CTRL_BIT_LINE_OFFSET;
    // Setting write_col_sels bit field
    new_reg_val |= ((uint32_t)write_col_sels) << PEC_CTRL_WRITE_COL_SELS_OFFSET;
    *ctrl_reg = new_reg_val;
    return STATUS_OK;
}

pec_status_t pec_set_feature_size(uint8_t ft_sz)
{
    if (pec_get_state() != CTRL_READY)
        return DEVICE_BUSY;
    uint32_t volatile *layer_size_reg = (uint32_t*)(PEC0_BASE_ADDR + PEC_LAYER_SIZE_REG_OFFSET);
    uint32_t new_reg_val = *layer_size_reg;
    new_reg_val &= ~(((uint32_t)PEC_LAYER_SIZE_FT_SZ_MASK) << PEC_LAYER_SIZE_FT_SZ_OFFSET); //clear feature size field
    new_reg_val |=   ((uint32_t)ft_sz) << PEC_LAYER_SIZE_FT_SZ_OFFSET; //setting feature size field
    *layer_size_reg = new_reg_val;
    return STATUS_OK;
}

pec_status_t pec_set_input_size(uint8_t in_sz)
{
    if (pec_get_state() != CTRL_READY)
        return DEVICE_BUSY;
    uint32_t volatile *layer_size_reg = (uint32_t*)(PEC0_BASE_ADDR + PEC_LAYER_SIZE_REG_OFFSET);
    uint32_t new_reg_val = *layer_size_reg;
    new_reg_val &= ~(((uint32_t)PEC_LAYER_SIZE_IN_SZ_MASK) << PEC_LAYER_SIZE_IN_SZ_OFFSET); //clear input size field
    new_reg_val |=   ((uint32_t)in_sz) << PEC_LAYER_SIZE_IN_SZ_OFFSET; //setting input size field
    *layer_size_reg = new_reg_val;
    return STATUS_OK;
}

pec_status_t pec_set_weight_size(uint8_t wg_sz)
{
    if (pec_get_state() != CTRL_READY)
        return DEVICE_BUSY;
    uint32_t volatile *layer_size_reg = (uint32_t*)(PEC0_BASE_ADDR + PEC_LAYER_SIZE_REG_OFFSET);
    uint32_t new_reg_val = *layer_size_reg;
    new_reg_val &= ~(((uint32_t)PEC_LAYER_SIZE_WG_SZ_MASK) << PEC_LAYER_SIZE_WG_SZ_OFFSET); //clear weight size field
    new_reg_val |=   ((uint32_t)wg_sz) << PEC_LAYER_SIZE_WG_SZ_OFFSET; //setting weight size field
    *layer_size_reg = new_reg_val;
    return STATUS_OK;
}

pec_status_t pec_set_channel_size(uint8_t ch_sz)
{
    if (pec_get_state() != CTRL_READY)
        return DEVICE_BUSY;
    uint32_t volatile *layer_size_reg = (uint32_t*)(PEC0_BASE_ADDR + PEC_LAYER_SIZE_REG_OFFSET);
    uint32_t new_reg_val = *layer_size_reg;
    new_reg_val &= ~(((uint32_t)PEC_LAYER_SIZE_CH_SZ_MASK) << PEC_LAYER_SIZE_CH_SZ_OFFSET); //clear channel size field
    new_reg_val |=   ((uint32_t)ch_sz) << PEC_LAYER_SIZE_CH_SZ_OFFSET; //setting channel size field
    *layer_size_reg = new_reg_val;
    return STATUS_OK;
}

pec_status_t pec_set_layer_sizes(uint8_t ft_sz, uint8_t in_sz, uint8_t wg_sz, uint8_t ch_sz)
{
    if (pec_get_state() != CTRL_READY)
        return DEVICE_BUSY;
    uint32_t volatile *layer_size_reg = (uint32_t*)(PEC0_BASE_ADDR + PEC_LAYER_SIZE_REG_OFFSET);
    uint32_t new_reg_val = 0;
    new_reg_val |= ((uint32_t)ft_sz) << PEC_LAYER_SIZE_FT_SZ_OFFSET; //setting feature size field
    new_reg_val |= ((uint32_t)in_sz) << PEC_LAYER_SIZE_IN_SZ_OFFSET; //setting input size field
    new_reg_val |= ((uint32_t)wg_sz) << PEC_LAYER_SIZE_WG_SZ_OFFSET; //setting weight size field
    new_reg_val |= ((uint32_t)ch_sz) << PEC_LAYER_SIZE_CH_SZ_OFFSET; //setting channel size field
    *layer_size_reg = new_reg_val;
    return STATUS_OK;
}

pec_status_t pec_set_in_bit_address(uint32_t *in_bit_addr)
{
    if (pec_get_state() != CTRL_READY)
        return DEVICE_BUSY;
    uint32_t volatile *in_bit_reg = (uint32_t*)(PEC0_BASE_ADDR + PEC_IN_BIT_ADDR_REG_OFFSET);
    *in_bit_reg = (uint32_t)in_bit_addr;
    return STATUS_OK;
}

pec_status_t pec_set_bias_address(uint32_t *bias_addr)
{
    if (pec_get_state() != CTRL_READY)
        return DEVICE_BUSY;
    uint32_t volatile *bias_reg = (uint32_t*)(PEC0_BASE_ADDR + PEC_BIAS_ADDR_REG_OFFSET);
    *bias_reg = (uint32_t)bias_addr;
    return STATUS_OK;
}

pec_status_t pec_set_pixel_address(uint32_t *pixel_addr)
{
    if (pec_get_state() != CTRL_READY)
        return DEVICE_BUSY;
    uint32_t volatile *pixel_reg = (uint32_t*)(PEC0_BASE_ADDR + PEC_PIXEL_ADDR_REG_OFFSET);
    *pixel_reg = (uint32_t)pixel_addr;
    return STATUS_OK;
}
