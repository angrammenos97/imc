#include <stdio.h>
#include <pulp.h>
#include "resnet20.h"
// #include "resdata.h"
// #include "layers_util.h"

int16_t __attribute__((section(".l2_data.buff"))) buff[3][32][32][16] = {0};

int main()
{

    Matrix_4D_t img1        = {(uint8_t*)image0,    1,  32, 32,  3,  sizeof(uint8_t)};
    // Matrix_4D_t qconv_w = {(uint8_t*)weights0,  16, 3,  3,   3,  sizeof(int8_t)};
    // Matrix_4D_t qconv_b = {(uint8_t*)bias0,     16, 1,  1,   1,  sizeof(int16_t)};
    // Matrix_4D_t qconv_r = {(uint8_t*)buff[0],   1,  32, 32,  16, sizeof(uint16_t)};
    // Matrix_4D_t qconv_o = {(uint8_t*)output0_0, 1,  32, 32,  16, sizeof(uint8_t)};
    // Matrix_4D_t qconv1_w = {(uint8_t*)weights1,  16, 3,  3,   16,  sizeof(int8_t)};
    // Matrix_4D_t qconv1_b = {(uint8_t*)bias1,     16, 1,  1,   1,  sizeof(int16_t)};
    // Matrix_4D_t qconv1_r = {(uint8_t*)buff[1],   1,  32, 32,  16, sizeof(uint16_t)};
    Matrix_4D_t qconv1_o    = {(uint8_t*)output0_1, 1,  32, 32,  16, sizeof(uint8_t)};

    // Layer_Setting_t sett = {0};
    // sett.write_col_sels = 1;
    // // sett.output_saturated = 1;
    // sett.verbose = 1;

    // // Layer 1
    // qConv2D(&qconv_r, &img1, &qconv_w, &qconv_b, sett);
    // printf("Number of errors: %d\n", compare_layers(&qconv_r, &qconv_o));
    // // Layer 2
    // qConv2D(&qconv1_r, &qconv_o, &qconv1_w, &qconv1_b, sett);
    // printf("Number of errors: %d\n", compare_layers(&qconv1_r, &qconv1_o));

    Matrix_4D_t res_out = resnet20(&img1, 1);
    // printf_matrix(&res_out, "output_mat");
    printf("Number of errors: %d\n", compare_layers(&res_out, &qconv1_o));
        
    return(0);
}