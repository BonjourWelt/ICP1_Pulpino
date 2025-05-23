// Copyright 2017 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the “License”); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.


// Copyright 2017 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the “License”); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.


#include <stdio.h>
#include <stdint.h>

// Define the start and end addresses for a 32-bit memory space.
#define START_ADDR ((uintptr_t)0x00100000)
#define END_ADDR   ((uintptr_t)0x00108000)

int main(void) {
    // Use a volatile pointer so that the compiler cannot optimize away the writes.
    volatile uint32_t *addr;

    // Define an array of four test patterns to write in sequence.
    uint32_t patterns[4] = { 0xDEADBEEF, 0x12345678, 0xCAFEBABE, 0x0BADF00D };
    int error_count = 0;
    size_t pattern_index = 0;

    printf("Starting memory write test with 4-pattern sequence...\n");
    printf("Writing patterns to addresses from 0x%08lX to 0x%08lX.\n",
           (unsigned long)START_ADDR, (unsigned long)END_ADDR);

    // Write phase: cycle through the 4 patterns
    pattern_index = 0;
    for (addr = (volatile uint32_t *)START_ADDR; (uintptr_t)addr < END_ADDR; addr += 4) {
        *addr = patterns[pattern_index];
        pattern_index = (pattern_index + 1) % 4;
    }

    printf("Write phase complete.\n");

    // Read-back and verification phase
    pattern_index = 0;
    for (addr = (volatile uint32_t *)START_ADDR; (uintptr_t)addr < END_ADDR; addr += 4) {
        if (*addr != patterns[pattern_index]) {
            printf("Mismatch at 0x%08lX: expected 0x%08X, got 0x%08X.\n",
                   (unsigned long)addr, patterns[pattern_index], *addr);
            error_count++;
        }
        pattern_index = (pattern_index + 1) % 4;
    }

    if (error_count == 0) {
        printf("Memory read-back test passed: all values are correct.\n");
    } else {
        printf("Memory read-back test failed: %d errors detected.\n", error_count);
    }

    // Prevent program from exiting, if testing on bare metal
    //while (1) { }

    return 0;
}

