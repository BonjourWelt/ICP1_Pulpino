#include <stdio.h>

#define ROWS_INPUT 4
#define COLS_INPUT 8
#define COLS_COEFFICIENT 4

// Function to perform matrix multiplication
void matrixMultiply(int inputMatrix[ROWS_INPUT][COLS_INPUT], 
                    int coefficientMatrix[COLS_INPUT][COLS_COEFFICIENT], 
                    int resultMatrix[ROWS_INPUT][COLS_COEFFICIENT]) {
    for (int i = 0; i < ROWS_INPUT; i++) {
        for (int j = 0; j < COLS_COEFFICIENT; j++) {
            resultMatrix[i][j] = 0;
            for (int k = 0; k < COLS_INPUT; k++) {
                resultMatrix[i][j] += inputMatrix[i][k] * coefficientMatrix[k][j];
            }
        }
    }
}

// Function to print a matrix
void printMatrix(int *matrix, int rows, int cols) {
    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++)
            printf("%d ", matrix[i * cols + j]);
        printf("\n");
    }
}

int main() {
    // Define and initialize the coefficient matrix
    int coefficientMatrix[COLS_INPUT][COLS_COEFFICIENT] = {
        {1, 2, 3, 4},
        {5, 6, 7, 8},
        {9, 10, 11, 12},
        {13, 14, 15, 16},
        {17, 18, 19, 20},
        {21, 22, 23, 24},
        {25, 26, 27, 28},
        {29, 30, 31, 32}
    };

    printf("Coefficient matrix:\n");
    printMatrix((int *)coefficientMatrix, COLS_INPUT, COLS_COEFFICIENT);

    // Define the result matrix
    int resultMatrix[ROWS_INPUT][COLS_COEFFICIENT];

    // Number of input matrices
    #define numInputMatrices  5

    // Pre-define 5 input matrices of size 4x8
    int inputMatrices[numInputMatrices][ROWS_INPUT][COLS_INPUT] = {
        {{1, 2, 3, 4, 5, 6, 7, 8}, {9, 10, 11, 12, 13, 14, 15, 16}, {17, 18, 19, 20, 21, 22, 23, 24}, {25, 26, 27, 28, 29, 30, 31, 32}},
        {{33, 34, 35, 36, 37, 38, 39, 40}, {41, 42, 43, 44, 45, 46, 47, 48}, {49, 50, 51, 52, 53, 54, 55, 56}, {57, 58, 59, 60, 61, 62, 63, 64}},
        {{65, 66, 67, 68, 69, 70, 71, 72}, {73, 74, 75, 76, 77, 78, 79, 80}, {81, 82, 83, 84, 85, 86, 87, 88}, {89, 90, 91, 92, 93, 94, 95, 96}},
        {{97, 98, 99, 100, 101, 102, 103, 104}, {105, 106, 107, 108, 109, 110, 111, 112}, {113, 114, 115, 116, 117, 118, 119, 120}, {121, 122, 123, 124, 125, 126, 127, 128}},
        {{129, 130, 131, 132, 133, 134, 135, 136}, {137, 138, 139, 140, 141, 142, 143, 144}, {145, 146, 147, 148, 149, 150, 151, 152}, {153, 154, 155, 156, 157, 158, 159, 160}}
    };

    // Loop through and process each input matrix
    for (int matrixIndex = 0; matrixIndex < numInputMatrices; matrixIndex++) {
        int (*inputMatrix)[COLS_INPUT] = inputMatrices[matrixIndex];

        printf("Input matrix %d:\n", matrixIndex + 1);
        printMatrix((int *)inputMatrix, ROWS_INPUT, COLS_INPUT);

        // Perform matrix multiplication
        matrixMultiply(inputMatrix, coefficientMatrix, resultMatrix);

        // Print the resulting matrix
        printf("Result of matrix multiplication for the %d-th input matrix:\n", matrixIndex + 1);
        printMatrix((int *)resultMatrix, ROWS_INPUT, COLS_COEFFICIENT);
    }

    return 0;
}



