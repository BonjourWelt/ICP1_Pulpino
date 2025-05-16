#include <stdio.h>

#define numInputMatrices 5
#define ROWS_INPUT 4
#define COLS_INPUT 8
#define ROWS_COEFFICIENT 8
#define COLS_COEFFICIENT 4

void matrixMultiply(int inputMatrix[], int coefficientMatrix[], int resultMatrix[]) {
    for (int i = 0; i < ROWS_INPUT; i++) {
        for (int j = 0; j < COLS_COEFFICIENT; j++) {
            resultMatrix[i * COLS_COEFFICIENT + j] = 0;
            for (int k = 0; k < COLS_INPUT; k++) {
                resultMatrix[i * COLS_COEFFICIENT + j] += inputMatrix[i * COLS_INPUT + k] * coefficientMatrix[k * COLS_COEFFICIENT + j];
            }
        }
    }
}

void compareResults(int resultMatrix[], int expectedResult[]) {
    int isEqual = 1;
    for (int i = 0; i < ROWS_INPUT * COLS_COEFFICIENT; i++) {
        if (resultMatrix[i] != expectedResult[i]) {
            isEqual = 0;
            break;
        }
    }

    if (isEqual) {
        printf("The computed results match the expected results.\n");
    } else {
        printf("The computed results do not match the expected results.\n");
    }
}

int main() {
    int inputMatrices[numInputMatrices][ROWS_INPUT * COLS_INPUT] = {
        {87, 17, 92, 14, 15, 81, 42, 83, 95, 74, 94, 30, 93, 123, 110, 11, 47, 47, 87, 76, 100, 47, 26, 11, 98, 26, 49, 70, 29, 82, 62, 19},
        {99, 13, 37, 30, 67, 12, 51, 13, 14, 100, 37, 77, 122, 55, 88, 96, 55, 83, 14, 119, 24, 34, 101, 62, 98, 50, 35, 5, 86, 55, 57, 77},
        {8, 40, 98, 88, 16, 17, 12, 1, 54, 83, 92, 67, 14, 80, 16, 17, 13, 18, 21, 25, 40, 40, 28, 32, 113, 89, 71, 23, 27, 10, 116, 90},
        {71, 40, 21, 79, 125, 22, 33, 50, 9, 87, 51, 125, 51, 79, 20, 48, 20, 96, 111, 45, 87, 37, 67, 106, 76, 43, 38, 57, 54, 46, 71, 94},
        {54, 55, 16, 3, 37, 40, 83, 122, 119, 58, 31, 97, 96, 94, 94, 13, 87, 59, 27, 13, 105, 22, 21, 85, 114, 66, 89, 20, 121, 69, 86, 5}
    };

    int coefficientMatrix[ROWS_COEFFICIENT * COLS_COEFFICIENT] = {
     3,  8, 18, 1,
    22,  15, 40,  10,
    11,  2,  3,  4,
     1,  4,  2,  0,
     8, 12,  16,  2,
     3,  6,  9,  12,
     1, 1,  1,  1,
     2, 2,  2,  2
    };

    int expectedResults[5][ROWS_INPUT * COLS_COEFFICIENT] = {
        {2232, 2065, 3727, 1835, 4222, 4164, 7739, 3005, 3197, 3089, 5210, 1677, 2053, 2492, 4393, 1696},
        {1669, 2134, 3730, 732, 4147, 4068, 7244, 2346, 2783, 2906, 5505, 1622, 2848, 3197, 5961, 1781},
        {2263, 1520, 2637, 1050, 3469, 2827, 5696, 2290, 1223, 1328, 2159, 929, 3643, 3153, 6671, 1757},
        {2602, 3291, 5430, 1202, 3388, 3181, 5688, 2249, 4524, 3547, 6627, 2321, 2478, 2740, 4853, 1577},
        {2294, 2312, 4505, 1549, 3241, 4108, 7251, 2263, 2966, 3270, 6102, 1450, 4064, 4122, 7652, 2296}
    };

    int resultMatrix[ROWS_INPUT * COLS_COEFFICIENT];

    for (int m = 0; m < numInputMatrices; m++) {
        // Perform matrix multiplication
        matrixMultiply(inputMatrices[m], coefficientMatrix, resultMatrix);

        // Compare results
        printf("Matrix %d:\n", m + 1);
        compareResults(resultMatrix, expectedResults[m]);

        // Print result matrix
        printf("Computed Result Matrix:\n");
        for (int i = 0; i < ROWS_INPUT * COLS_COEFFICIENT; i++) {
            printf("%d ", resultMatrix[i]);
            if ((i + 1) % COLS_COEFFICIENT == 0) {
                printf("\n");
            }
        }
        printf("\n");
    }

    return 0;
}
