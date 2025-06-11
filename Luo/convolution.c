#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include "ifm.h"
#include "w.h"

#define IFM_ROWS 28
#define IFM_COLS 28
#define IFM_CHANNELS 3
#define W_ROWS 3
#define W_COLS 3
#define OFM_CHANNELS 1
#define PADDING 1
#define STRIDE 1
#define OFM_ROWS ((IFM_ROWS + 2 * PADDING - W_ROWS) / STRIDE + 1)
#define OFM_COLS ((IFM_COLS + 2 * PADDING - W_COLS) / STRIDE + 1)

// Padding function for 3D input
void pad_input(uint8_t input[IFM_ROWS][IFM_COLS][IFM_CHANNELS],
               uint8_t output[IFM_ROWS + 2 * PADDING][IFM_COLS + 2 * PADDING][IFM_CHANNELS]) {
    for (int c = 0; c < IFM_CHANNELS; c++) {
        for (int i = 0; i < IFM_ROWS + 2 * PADDING; i++) {
            for (int j = 0; j < IFM_COLS + 2 * PADDING; j++) {
                if (i >= PADDING && i < IFM_ROWS + PADDING && j >= PADDING && j < IFM_COLS + PADDING) {
                    output[i][j][c] = input[i - PADDING][j - PADDING][c];
                } else {
                    output[i][j][c] = 0;
                }
            }
        }
    }
}

int main() {
    uint8_t ifm_array[IFM_ROWS][IFM_COLS][IFM_CHANNELS];
    uint8_t w_array[W_ROWS][W_COLS][IFM_CHANNELS][OFM_CHANNELS];

    // Load IFM
    for (int ch = 0, idx = 0; ch < IFM_CHANNELS; ch++) {
        for (int row = 0; row < IFM_ROWS; row++) {
            for (int col = 0; col < IFM_COLS; col++, idx++) {
                ifm_array[row][col][ch] = ifm[idx];
            }
        }
    }

    // Load Weights
    for (int och = 0, idx = 0; och < OFM_CHANNELS; och++) {
        for (int ch = 0; ch < IFM_CHANNELS; ch++) {
            for (int row = 0; row < W_ROWS; row++) {
                for (int col = 0; col < W_COLS; col++, idx++) {
                    w_array[row][col][ch][och] = w[idx];
                }
            }
        }
    }

    uint8_t padded_ifm[IFM_ROWS + 2 * PADDING][IFM_COLS + 2 * PADDING][IFM_CHANNELS];
    pad_input(ifm_array, padded_ifm);

    uint8_t ofm[OFM_ROWS][OFM_COLS][OFM_CHANNELS];  

    // Convolution
    for (int och = 0; och < OFM_CHANNELS; och++) {
        for (int i = 0; i < OFM_ROWS; i++) {
            for (int j = 0; j < OFM_COLS; j++) {
                int32_t acc = 0;
                for (int ch = 0; ch < IFM_CHANNELS; ch++) {
                    for (int ki = 0; ki < W_ROWS; ki++) {
                        for (int kj = 0; kj < W_COLS; kj++) {
                            acc += padded_ifm[i * STRIDE + ki][j * STRIDE + kj][ch] *
                                   w_array[ki][kj][ch][och];
                        }
                    }
                }
                // Clamp result to uint8_t range if needed
                if (acc > 255) acc = 255;
                if (acc < 0) acc = 0;
                ofm[i][j][och] = (uint8_t)acc;
            }
        }
    }

    // Optionally print or write output
    printf("Output feature map:\n");
    for (int i = 0; i < OFM_ROWS; i++) {
        for (int j = 0; j < OFM_COLS; j++) {
            printf("%3d ", ofm[i][j][0]);
        }
        printf("\n");
    } 

    return 0;
}
