// Generated register defines for pec

#ifndef _PEC_REG_DEFS_
#define _PEC_REG_DEFS_

#ifdef __cplusplus
extern "C" {
#endif
// Register width
#define PEC_PARAM_REG_WIDTH 32

// Controls segment's addresses and trigger signal of the accelerator.
#define PEC_CTRL_REG_OFFSET 0x0
#define PEC_CTRL_START_BIT 0
#define PEC_CTRL_OPERATION_MASK 0x7
#define PEC_CTRL_OPERATION_OFFSET 1
#define PEC_CTRL_OPERATION_FIELD \
  ((bitfield_field32_t) { .mask = PEC_CTRL_OPERATION_MASK, .index = PEC_CTRL_OPERATION_OFFSET })
#define PEC_CTRL_OPERATION_VALUE_NO_OPERATION 0x0
#define PEC_CTRL_OPERATION_VALUE_CLEAR 0x1
#define PEC_CTRL_OPERATION_VALUE_LOAD_WEIGHTS 0x2
#define PEC_CTRL_OPERATION_VALUE_LOAD_BIAS 0x3
#define PEC_CTRL_OPERATION_VALUE_COMPUTE 0x4
#define PEC_CTRL_WORD_LINE_MASK 0xf
#define PEC_CTRL_WORD_LINE_OFFSET 4
#define PEC_CTRL_WORD_LINE_FIELD \
  ((bitfield_field32_t) { .mask = PEC_CTRL_WORD_LINE_MASK, .index = PEC_CTRL_WORD_LINE_OFFSET })
#define PEC_CTRL_BIT_LINE_MASK 0x7
#define PEC_CTRL_BIT_LINE_OFFSET 8
#define PEC_CTRL_BIT_LINE_FIELD \
  ((bitfield_field32_t) { .mask = PEC_CTRL_BIT_LINE_MASK, .index = PEC_CTRL_BIT_LINE_OFFSET })
#define PEC_CTRL_WRITE_COL_SELS_MASK 0x1f
#define PEC_CTRL_WRITE_COL_SELS_OFFSET 11
#define PEC_CTRL_WRITE_COL_SELS_FIELD \
  ((bitfield_field32_t) { .mask = PEC_CTRL_WRITE_COL_SELS_MASK, .index = PEC_CTRL_WRITE_COL_SELS_OFFSET })
#define PEC_CTRL_STATE_MASK 0xf
#define PEC_CTRL_STATE_OFFSET 16
#define PEC_CTRL_STATE_FIELD \
  ((bitfield_field32_t) { .mask = PEC_CTRL_STATE_MASK, .index = PEC_CTRL_STATE_OFFSET })
#define PEC_CTRL_STATE_VALUE_READY 0x0
#define PEC_CTRL_STATE_VALUE_CLEAR 0x1
#define PEC_CTRL_STATE_VALUE_BUSY 0x2
#define PEC_CTRL_STATE_VALUE_FETCH_WEIGHTS 0x3
#define PEC_CTRL_STATE_VALUE_PROGRAMMING 0x4
#define PEC_CTRL_STATE_VALUE_FETCH_BIAS 0x5
#define PEC_CTRL_STATE_VALUE_FETCH_INPUT 0x6
#define PEC_CTRL_STATE_VALUE_COMPUTE 0x7
#define PEC_CTRL_STATE_VALUE_STORE_OUTPUT 0x8

// Contain's the size of the layer.
#define PEC_LAYER_SIZE_REG_OFFSET 0x4
#define PEC_LAYER_SIZE_FT_SZ_MASK 0xff
#define PEC_LAYER_SIZE_FT_SZ_OFFSET 0
#define PEC_LAYER_SIZE_FT_SZ_FIELD \
  ((bitfield_field32_t) { .mask = PEC_LAYER_SIZE_FT_SZ_MASK, .index = PEC_LAYER_SIZE_FT_SZ_OFFSET })
#define PEC_LAYER_SIZE_IN_SZ_MASK 0xff
#define PEC_LAYER_SIZE_IN_SZ_OFFSET 8
#define PEC_LAYER_SIZE_IN_SZ_FIELD \
  ((bitfield_field32_t) { .mask = PEC_LAYER_SIZE_IN_SZ_MASK, .index = PEC_LAYER_SIZE_IN_SZ_OFFSET })
#define PEC_LAYER_SIZE_WG_SZ_MASK 0xff
#define PEC_LAYER_SIZE_WG_SZ_OFFSET 16
#define PEC_LAYER_SIZE_WG_SZ_FIELD \
  ((bitfield_field32_t) { .mask = PEC_LAYER_SIZE_WG_SZ_MASK, .index = PEC_LAYER_SIZE_WG_SZ_OFFSET })
#define PEC_LAYER_SIZE_CH_SZ_MASK 0xff
#define PEC_LAYER_SIZE_CH_SZ_OFFSET 24
#define PEC_LAYER_SIZE_CH_SZ_FIELD \
  ((bitfield_field32_t) { .mask = PEC_LAYER_SIZE_CH_SZ_MASK, .index = PEC_LAYER_SIZE_CH_SZ_OFFSET })

// Address of layer's bias to memory.
#define PEC_BIAS_ADDR_REG_OFFSET 0x8

// Address of layer's input to memory.
#define PEC_IN_BIT_ADDR_REG_OFFSET 0xc

// Address of layer's output to memory.
#define PEC_PIXEL_ADDR_REG_OFFSET 0x10

#ifdef __cplusplus
}  // extern "C"
#endif
#endif  // _PEC_REG_DEFS_
// End generated register defines for pec