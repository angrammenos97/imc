#ifndef _RESNET20_H_
#define _RESNET20_H_

#include <stdio.h>
#include "layers_util.h"
#include "resdata.h"

int16_t __attribute__((section(".l2_data.mid_buff"))) mid_buff[3][32][32][16] = {0};

Matrix_4D_t resnet20(Matrix_4D_t *input, uint8_t verbose)
{
    Layer_Setting_t sett = {0};
    sett.verbose = verbose;

    /*** Define layer weights and bias ***/
    Matrix_4D_t qconv_w  = {(uint8_t*)weights0,  16, 3,  3,   3,  sizeof(int8_t)};
    Matrix_4D_t qconv_b  = {(uint8_t*)bias0,     16, 1,  1,   1,  sizeof(int16_t)};
    Matrix_4D_t qconv1_w = {(uint8_t*)weights1,  16, 3,  3,  16,  sizeof(int8_t)};
    Matrix_4D_t qconv1_b = {(uint8_t*)bias1,     16, 1,  1,   1,  sizeof(int16_t)};

    /*** Store weights in the accelerator ***/
    // Layer qconv
    if (sett.verbose) printf("VERBOSE: Loading qconv layer weights to the accelerator.\n");
    sett.write_col_sels = 1;
    load_layer_weights(&qconv_w, sett);
    pec_wait_till_ready();
    // Layer qconv1
    if (sett.verbose) printf("VERBOSE: Loading qconv1 layer weights to the accelerator.\n");
    sett.wl = 1;
    load_layer_weights(&qconv1_w, sett);
    pec_wait_till_ready();

    /*** Passing to the network the input ***/
    if (sett.verbose) printf("VERBOSE: Passing input to the network.\n");
    sett.write_col_sels = 0;
    // Layer qconv
    if (sett.verbose) printf("VERBOSE: Passing through layer qconv.\n");
    sett.weights_preloaded = 1;
    sett.wl = 0;
    Matrix_4D_t qconv_r  = {(uint8_t*)mid_buff[0], 1, 32, 32, 16, sizeof(int16_t)};
    qConv2D(&qconv_r, input, &qconv_w, &qconv_b, sett);
    // printf_matrix(&qconv_r, "qconv_r");
    // Layer qconv1
    if (sett.verbose) printf("VERBOSE: Passing through layer qconv1.\n");
    sett.weights_preloaded = 1;
    sett.wl = 1;
    Matrix_4D_t qconv1_r  = {(uint8_t*)mid_buff[1], 1, 32, 32, 16, sizeof(int16_t)};
    qConv2D(&qconv1_r, &qconv_r, &qconv1_w, &qconv1_b, sett);

    /*** Return output ***/
    return qconv1_r;
}


#endif // _RESNET20_H_
