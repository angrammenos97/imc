#ifndef _LAYERS_UTIL_H_
#define _LAYERS_UTIL_H_

#include <hal/pulp.h>

typedef struct {
    uint8_t *data_addr; //start address of the data
    uint8_t ft_sz;      //features size
    uint8_t hg_sz;      //heigh size
    uint8_t wd_sz;      //width size
    uint8_t ch_sz;      //channel size
    uint8_t el_sz;      //element size
} Matrix_4D_t;

typedef struct {
    uint8_t input_padded;
    uint8_t input_compressed;
    uint8_t weights_compressed;
    uint8_t weights_preloaded;
    uint8_t bias_preloaded;
    uint8_t output_saturated;
    uint8_t wl;
    uint8_t bl;
    uint8_t write_col_sels;
    uint8_t verbose;
} Layer_Setting_t;

void compress_channels(Matrix_4D_t *dst_mat, Matrix_4D_t *org_mat);

void add_zero_padding(Matrix_4D_t *dst_mat, Matrix_4D_t *org_mat, uint8_t ud_sz, uint8_t rl_sz);

void quantized_relu(Matrix_4D_t *mat);

void printf_matrix(Matrix_4D_t *mat, char *mat_name);

uint32_t compare_layers(Matrix_4D_t *a, Matrix_4D_t *b);

void clear_accelerator();

void load_layer_weights(Matrix_4D_t *weight_mat, Layer_Setting_t sett);

void load_layer_bias(Matrix_4D_t *bias_mat);

void perform_layer_mac(Matrix_4D_t *out_mat, Matrix_4D_t *in_mat, Layer_Setting_t sett);

void qConv2D(
    Matrix_4D_t *out_mat, 
    Matrix_4D_t *in_mat, 
    Matrix_4D_t *wg_mat, 
    Matrix_4D_t *bs_mat,
    Layer_Setting_t sett
);

#endif //_LAYERS_UTIL_H_