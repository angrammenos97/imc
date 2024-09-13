#include <stdio.h>
#include <pulp.h>
#include "layers_util.h"

uint8_t __attribute__((section(".l2_data"))) input[16];
int8_t __attribute__((section(".l2_data"))) weight[2][9];
uint16_t __attribute__((section(".l2_data"))) bias[2];
uint16_t __attribute__((section(".l2_data"))) output[4];

int main()
{
    { // Initialize arrays
        weight[0][0] = 2;
        weight[0][1] = 3;
        weight[0][2] = 4;
        weight[0][3] = -1;
        weight[0][4] = 7;
        weight[0][5] = -3;
        weight[0][6] = 0;
        weight[0][7] = -2;
        weight[0][8] = 6;
        
        weight[1][0] = 0;
        weight[1][1] = -1;
        weight[1][2] = 6;
        weight[1][3] = 3;
        weight[1][4] = 5;
        weight[1][5] = 2;
        weight[1][6] = 0;
        weight[1][7] = -2;
        weight[1][8] = -1;

        bias[0] = 1;
        bias[1] = 3;

        input[0] = 8;
        input[1] = 3;
        input[2] = 1;
        input[3] = 2;
        input[4] = 0;
        input[5] = 12;
        input[6] = 6;
        input[7] = 4;
        input[8] = 5;
        input[9] = 4;
        input[10] = 6;
        input[11] = 12;
        input[12] = 0;
        input[13] = 2;
        input[14] = 1;
        input[15] = 3;
    }

    // Configuring layer settings
    Layer_Setting_t sett = {0};
    sett.input_padded = 1;
    sett.output_saturated = 1;
    sett.verbose = 1;

    // Creating data matrix
    Matrix_4D_t input_l, weight_l, bias_l, output_l;

    input_l.data_addr = (uint8_t*)&input[0];
    input_l.ft_sz = 1;
    input_l.hg_sz = 4;
    input_l.wd_sz = 4;
    input_l.ch_sz = 1;
    input_l.el_sz = sizeof(input[0]);

    weight_l.data_addr = (uint8_t*)&weight[0][0];
    weight_l.ft_sz = 2;
    weight_l.hg_sz = 3;
    weight_l.wd_sz = 3;
    weight_l.ch_sz = 1;
    weight_l.el_sz = sizeof(weight[0][0]);

    bias_l.data_addr = (uint8_t*)&bias[0];
    bias_l.ft_sz = 2;
    bias_l.hg_sz = 1;
    bias_l.wd_sz = 1;
    bias_l.ch_sz = 1;
    bias_l.el_sz = sizeof(bias[0]);

    output_l.data_addr = (uint8_t*)&output[0];
    output_l.ft_sz = 1;
    output_l.hg_sz = 2;
    output_l.wd_sz = 2;
    output_l.ch_sz = 2;
    output_l.el_sz = sizeof(output[0]);

    // Performing 2D convolution
    pec_wait_till_ready();
    qConv2D(&output_l, &input_l, &weight_l, &bias_l, sett);

    // Displaying results
    pec_wait_till_ready();
    printf("Done!\n");
    printf_matrix(&output_l, "output_matrix"); // expected: 7c, 41, 60, 40, 44, 44, 4d, 52
    return 0;
}
