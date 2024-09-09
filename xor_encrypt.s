        .section .data
input_file:      .asciz "input.txt"        // Input file
output_file:     .asciz "encrypted.txt"    // Output file
msg_success:     .asciz "File opened successfully\n"
msg_fail_open:   .asciz "Failed to open file\n"
msg_fail_write:  .asciz "Failed to write to file\n"
encryption_key:  .word 0x42                // XOR key (0x42 is arbitrary)

        .section .text
        .global _start

_start:
        // Load encryption key
        ldr x2, =encryption_key
        ldr w2, [x2]           // Load the key into w2

        // Open input file (input.txt)
        adr x0, input_file     // Filename of the input file
        mov x1, #0             // Read-only mode
        bl open_file           // Call open_file
        cmp x0, #0             // Check if file was opened successfully
        blt error_open_file    // Jump to error handler if file couldn't be opened

        // Save input file descriptor in x3
        mov x3, x0

        // Open output file (encrypted.txt)
        adr x0, output_file    // Filename of the output file
        mov x1, #577           // Write-only mode with create and truncate flags
        bl open_file
        cmp x0, #0             // Check if file was opened successfully
        blt error_open_file    // Jump to error handler if file couldn't be opened

        // Save output file descriptor in x4
        mov x4, x0

        // Success message after files are opened
        adr x0, msg_success
        bl print_msg

        // Process file: read, XOR, and write
process_file:
        // Read from input file
        mov x0, x3             // File descriptor for input file
        adr x1, buffer         // Buffer for reading data
        mov x2, #1             // Read 1 byte at a time
        bl read_file
        cmp x0, #0             // Check if end of file (read returned 0)
        beq end_program        // Exit if end of file

        // XOR encryption
        ldrb w5, [x1]          // Load byte from buffer into w5
        eor w5, w5, w2         // XOR byte with encryption key
        strb w5, [x1]          // Store the result back in buffer

        // Write encrypted byte to output file
        mov x0, x4             // File descriptor for output file
        bl write_file
        cmp x0, #0             // Check if write was successful
        blt error_write_file   // Jump to error handler if write failed

        // Loop back to process the next byte
        b process_file

end_program:
        mov x0, #0             // Exit the program
        bl exit_program

error_open_file:
        adr x0, msg_fail_open  // Print failure message if file open fails
        bl print_msg
        b end_program

error_write_file:
        adr x0, msg_fail_write // Print failure message if write fails
        bl print_msg
        b end_program

// Subroutine to print debug messages
print_msg:
        mov x1, x0             // Message to print
        mov x2, #23            // Message length
        mov x0, #1             // File descriptor 1 (stdout)
        mov x8, #64            // Syscall number for write (AArch64)
        svc #0
        ret

// Subroutine to open a file
open_file:
        mov x8, #56            // Syscall number for 'openat' (AArch64)
        mov x16, #-100            // AT_FDCWD (relative to current directory)
        svc #0                 // Make system call
        ret

// Subroutine to read from a file
read_file:
        mov x8, #63            // Syscall number for 'read' (AArch64)        svc #0              
   // Make system call 
        ret

// Subroutine to write to a file
write_file:
        mov x8, #64            // Syscall number for 'write' (AArch64)
        svc #0                 // Make system call
        ret

// Subroutine to exit the program
exit_program:
        mov x8, #93            // Syscall number for 'exit' (AArch64)
        svc #0                 // Make system call

        .section .bss
buffer: .space 1               // Buffer for reading and writing 1 byte
