#include "layers_util.h"
#include "pec_driver.h"
#include <stdio.h>

uint8_t TEST_FE = 16;   // for testing
uint8_t TEST_HE = 32;   // for testing
uint8_t TEST_WI = 32;   // for testing
int8_t  TEST_ER = 0;    // for testing

uint32_t __attribute__((section(".l2_data.compr_mat"))) compr_mat[8192] = {0};
uint32_t __attribute__((section(".l2_data.z_pad_mat"))) z_pad_mat[8192] = {0};

void compress_channels(Matrix_4D_t *dst_mat, Matrix_4D_t *org_mat)
{
    uint8_t *dst_addr = dst_mat->data_addr;
    uint8_t *org_addr = org_mat->data_addr;
    uint8_t ft_sz = org_mat->ft_sz;
    uint32_t in_sz = (org_mat->hg_sz) * (org_mat->wd_sz);
    uint8_t ch_sz = org_mat->ch_sz;
    uint8_t el_sz = org_mat->el_sz;

    uint8_t dst_ch_sz = (ch_sz + 7) / 8;
    uint32_t (*dst_prt)[in_sz][dst_ch_sz] = (uint32_t(*)[in_sz][dst_ch_sz])dst_addr;
    for (int f = 0; f < ft_sz; f++) {
        for (uint32_t i = 0; i < in_sz; i++) {
            for (int c = 0; c < ch_sz; c++) {
                uint8_t dst_ch_idx = (c / 8);
                uint8_t dst_ch_off = (c % 8) * 4;
                dst_prt[f][i][dst_ch_idx] &= ~(((uint32_t)0xF) << dst_ch_off);  //clear bit field
                dst_prt[f][i][dst_ch_idx] |=  (((uint32_t)0xF) & *(org_addr + (((f*in_sz) + i)*ch_sz + c)*el_sz)) << dst_ch_off;
            }
        }
    }
}

void add_zero_padding(Matrix_4D_t *dst_mat, Matrix_4D_t *org_mat, uint8_t ud_sz, uint8_t rl_sz)
{
    uint8_t *org_addr = org_mat->data_addr;
    uint8_t ft_sz_o = org_mat->ft_sz;
    uint8_t hg_sz_o = org_mat->hg_sz;
    uint8_t wd_sz_o = org_mat->wd_sz;
    uint8_t ch_sz_o = org_mat->ch_sz;
    uint8_t el_sz_o = org_mat->el_sz;
    uint8_t *dst_addr = dst_mat->data_addr;
    uint8_t ft_sz_d = dst_mat->ft_sz = org_mat->ft_sz;
    uint8_t hg_sz_d = dst_mat->hg_sz = org_mat->hg_sz + (2 * ud_sz);
    uint8_t wd_sz_d = dst_mat->wd_sz = org_mat->wd_sz + (2 * rl_sz);
    uint8_t ch_sz_d = dst_mat->ch_sz = org_mat->ch_sz;
    uint8_t el_sz_d = dst_mat->el_sz = org_mat->el_sz;

    for (int f = 0; f < ft_sz_d; f++) {
        for (int h = 0; h < hg_sz_d; h++) {
            for (int w = 0; w < wd_sz_d; w++) {
                for (int c = 0; c < ch_sz_d; c++) {
                    for (int e = 0; e < el_sz_d; e++) {
                        if ((h < ud_sz) || (h > (hg_sz_o + ud_sz - 1)) || (w < rl_sz) || (w > (wd_sz_o + rl_sz - 1))) {
                            *(dst_addr + ((((f*hg_sz_d) + h)*wd_sz_d + w)*ch_sz_d + c)*el_sz_d + e) = 0;
                        }
                        else {
                            *(dst_addr + ((((f*hg_sz_d) + h)*wd_sz_d + w)*ch_sz_d + c)*el_sz_d + e) = 
                                *(org_addr + ((((f*hg_sz_o) + (h-ud_sz))*wd_sz_o + (w-rl_sz))*ch_sz_o + c)*el_sz_o + e);
                        }
                    }
                }
            }
        }
    }
}

void quantized_relu(Matrix_4D_t *mat)
{
    uint16_t *mat_addr = (uint16_t*)mat->data_addr;
    uint8_t ft_sz = mat->ft_sz;
    uint8_t hg_sz = mat->hg_sz;
    uint8_t wd_sz = mat->wd_sz;
    uint8_t ch_sz = mat->ch_sz;
    uint8_t el_sz = mat->el_sz;

    uint8_t (*mat_ptr)[hg_sz][wd_sz][ch_sz] = (uint8_t(*)[hg_sz][wd_sz][ch_sz]) mat_addr;

    for (uint8_t f = 0; f < ft_sz; f++) {
        for (uint8_t h = 0; h < hg_sz; h++) {
            for (uint8_t w = 0; w < wd_sz; w++) {
                for (uint8_t c = 0; c < ch_sz; c++) {
                    int32_t mat_value = *(mat_addr + (((f*hg_sz) + h)*wd_sz + w)*ch_sz + c);
                    if (mat_value < 0) {
                        mat_ptr[f][h][w][c] = 0;
                    }
                    else {
                        mat_value = mat_value >> 3;
                        mat_ptr[f][h][w][c] = (mat_value > 15) ? 15 : mat_value;
                        // mat_ptr[f][h][w][c] = (uint8_t)mat_value;
                    }

                }
            }
        }
    }
}

void printf_matrix(Matrix_4D_t *mat, char *mat_name)
{
    uint8_t *mat_addr = mat->data_addr;
    uint8_t ft_sz = mat->ft_sz;
    uint8_t hg_sz = mat->hg_sz;
    uint8_t wd_sz = mat->wd_sz;
    uint8_t ch_sz = mat->ch_sz;
    uint8_t el_sz = mat->el_sz;

    uint16_t *mat_addr_16b = (uint16_t*)mat_addr;
    uint32_t *mat_addr_32b = (uint32_t*)mat_addr;
    printf("%s(%dx%dx%dx%d of %dbytes):\n", mat_name, ft_sz, hg_sz, wd_sz, ch_sz, el_sz);
    for (int f = 0; f < ft_sz; f++) {
        for (int h = 0; h < hg_sz; h++) {
            for (int w = 0; w < wd_sz; w++) {
                for (int c = 0; c < ch_sz; c++) {
                    if (el_sz == 1)
                        printf("(%d,%d,%d,%d) = %x\n", f, h, w, c, *(mat_addr + (((f*hg_sz) + h)*wd_sz + w)*ch_sz + c));
                    else if (el_sz == 2)
                        printf("(%d,%d,%d,%d) = %x\n", f, h, w, c, *(mat_addr_16b + (((f*hg_sz) + h)*wd_sz + w)*ch_sz + c));
                    else if (el_sz == 4)
                        printf("(%d,%d,%d,%d) = %x\n", f, h, w, c, *(mat_addr_32b + (((f*hg_sz) + h)*wd_sz + w)*ch_sz + c));
                }
            }
        }
    }
}

uint32_t compare_layers(Matrix_4D_t *a, Matrix_4D_t *b)
{
    // TODO: Check equal dimentions
    uint32_t errorNum = 0;
    for (uint8_t c = 0; c < TEST_FE /*a->ch_sz*/; c++) {
        for (uint8_t f = 0; f < a->ft_sz; f++) {
            for (uint8_t h = 0; h < TEST_HE /*a->hg_sz*/; h++) {
                for (uint8_t w = 0; w < TEST_WI /*a->wd_sz*/; w++) {
                    int32_t a_value = *(a->data_addr + ((((f*a->hg_sz) + h)*a->wd_sz + w)*a->ch_sz + c)*a->el_sz);
                    int32_t b_value = *(b->data_addr + ((((f*b->hg_sz) + h)*b->wd_sz + w)*b->ch_sz + c)*b->el_sz);
                    int32_t diff = a_value - b_value;
                    if (diff > TEST_ER || diff < -TEST_ER) {
                        printf("At (%d,%d,%d,%d) got %d and expected %d\n", f, h, w, c, a_value, b_value);
                        errorNum++;
                    }
                        // printf("At (%d,%d,%d,%d) got %d and expected %d\n", f, h, w, c, a_value, b_value);
                }
            }
        }
    }
    return errorNum;
}

void clear_accelerator()
{
    pec_status_t status = pec_trigger_operation(OP_CLEAR, 0, 0, 0);
    if(status != STATUS_OK)
        printf("Error during accelerator reset (error code: %d)\n", status);
}

void load_layer_weights(Matrix_4D_t *weight_mat, Layer_Setting_t sett) {
    // Compress matrix if asked
    if (!sett.weights_compressed) {
        Matrix_4D_t *dst_mat;
        dst_mat->data_addr = (uint8_t*)&compr_mat[0];
        if (sett.verbose) printf("VERBOSE: Compressing channels of the weights.\n");
        compress_channels(dst_mat, weight_mat);
        weight_mat->data_addr = dst_mat->data_addr;
    }
    // Set weights start address
    pec_status_t status;
    status = pec_set_in_bit_address((uint32_t*)weight_mat->data_addr);
    if(status != STATUS_OK)
        printf("Error during setting weights address (error code: %d)\n", status);
    // Set weights matrix size
    uint8_t ft_sz = weight_mat->ft_sz;
    uint8_t wg_sz = (weight_mat->hg_sz);
    uint8_t ch_sz = weight_mat->ch_sz;
    if (wg_sz != weight_mat->wd_sz)
        printf("Warning during programming height != width\n");
    status = pec_set_feature_size(ft_sz);
    if(status != STATUS_OK)
        printf("Error during setting weights feature size (error code: %d)\n", status);
    status = pec_set_weight_size(wg_sz);
    if(status != STATUS_OK)
        printf("Error during setting weights size (error code: %d)\n", status);
    status = pec_set_channel_size(ch_sz);
    if(status != STATUS_OK)
        printf("Error during setting weights channel size (error code: %d)\n", status);
    // Trigger weights programming
    if (sett.verbose) printf("VERBOSE: Triggering weights programming.\n");
    status = pec_trigger_operation(OP_LOAD_WEIGHTS, sett.wl, sett.bl, sett.write_col_sels);
    if(status != STATUS_OK)
        printf("Error during triggering programming (error code: %d)\n", status);
}

void load_layer_bias(Matrix_4D_t *bias_mat)
{
    // Set bias start address
    pec_status_t status;
    status = pec_set_bias_address((uint32_t*)bias_mat->data_addr);
    if(status != STATUS_OK)
        printf("Error during setting bias address (error code: %d)\n", status);
    // Set bias matrix size
    uint8_t ft_sz = bias_mat->ft_sz;
    status = pec_set_feature_size(ft_sz);
    if(status != STATUS_OK)
        printf("Error during setting bias feature sizes (error code: %d)\n", status);
    // Trigger bias load
    status = pec_trigger_operation(OP_LOAD_BIAS, 0, 0, 0);
    if(status != STATUS_OK)
        printf("Error during triggering bias loading (error code: %d)\n", status);
}

void perform_layer_mac(Matrix_4D_t *out_mat, Matrix_4D_t *in_mat, Layer_Setting_t sett) {
    // Compress matrix if asked
    if (!sett.input_compressed) {
        Matrix_4D_t *dst_mat;
        dst_mat->data_addr = (uint8_t*)&compr_mat[0];
        if (sett.verbose) printf("VERBOSE: Compressing channels of the input.\n");
        compress_channels(dst_mat, in_mat);
        in_mat->data_addr = dst_mat->data_addr;
    }
    // Set input start address
    pec_status_t status;
    status = pec_set_in_bit_address((uint32_t*)in_mat->data_addr);
    if(status != STATUS_OK)
        printf("Error during setting input address (error code: %d)\n", status);
    status = pec_set_pixel_address((uint32_t*)out_mat->data_addr);
    if(status != STATUS_OK)
        printf("Error during setting output address (error code: %d)\n", status);
    // Set input matrix size
    uint8_t in_sz = in_mat->hg_sz;
    if (in_sz != in_mat->wd_sz)
        printf("Warning during performing mac height != width\n");
    status = pec_set_input_size(in_sz);
    if(status != STATUS_OK)
        printf("Error during setting input size (error code: %d)\n", status);
    // Trigger compute
    if (sett.verbose) printf("VERBOSE: Triggering to start computations.\n");
    status = pec_trigger_operation(OP_COMPUTE, sett.wl, sett.bl, 0);
    if(status != STATUS_OK)
        printf("Error during triggering programming (error code: %d)\n", status);
}

void qConv2D(
    Matrix_4D_t *out_mat, 
    Matrix_4D_t *in_mat, 
    Matrix_4D_t *wg_mat, 
    Matrix_4D_t *bs_mat,
    Layer_Setting_t sett
) {
    //TODO : Check if sizes agree

    // Load weights if asked
    if (!sett.weights_preloaded) {
        if (sett.verbose) printf("VERBOSE: Loading weights to the accelerator.\n");
        load_layer_weights(wg_mat, sett);
        pec_wait_till_ready();
    }
    // Load bias if asked
    if (!sett.bias_preloaded) {
        if (sett.verbose) printf("VERBOSE: Loading bias to the accelerator.\n");
        load_layer_bias(bs_mat);
        pec_wait_till_ready();
    }
    // Add zero padding if asked
    if (!sett.input_padded) {
        Matrix_4D_t *dst_mat;
        dst_mat->data_addr = (uint8_t*)&z_pad_mat[0];
        uint8_t ud_sz = wg_mat->hg_sz / 2;
        uint8_t rl_sz = wg_mat->wd_sz / 2;
        if (sett.verbose) printf("VERBOSE: Adding zero padding to the input.\n");
        add_zero_padding(dst_mat, in_mat, ud_sz, rl_sz);
        in_mat->data_addr = dst_mat->data_addr;
        in_mat->hg_sz += 2 * ud_sz;
        in_mat->wd_sz += 2 * rl_sz;
    }
    // Set size of input, weights and bias
    pec_status_t status;
    if (sett.verbose) printf("VERBOSE: Setting sizes of input, weights and bias.\n");
    status = pec_set_layer_sizes(wg_mat->ft_sz, in_mat->hg_sz, wg_mat->hg_sz, wg_mat->ch_sz);
    if(status != STATUS_OK)
        printf("Error during setting layer size (error code: %d)\n", status);
    // Perform the mac operation
    if (sett.verbose) printf("VERBOSE: Initiating mac operation.\n");
    perform_layer_mac(out_mat, in_mat, sett);
    // Correct output and saturate if asked
    if (!sett.output_saturated) {
        pec_wait_till_ready();
        if (sett.verbose) printf("VERBOSE: Applying ReLU to the output.\n");
        quantized_relu(out_mat);
        out_mat->el_sz = (uint8_t)sizeof(uint8_t);
    }
}
