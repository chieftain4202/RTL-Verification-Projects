//`define SIMULATION 1

//  https://luplab.gitlab.io/rvcodecjs/
//  https://godbolt.org/
//  https://riscvasm.lucasteske.dev/#

//OP code
`define R_TYPE 7'b0110011
`define S_TYPE 7'b0100011
`define I_TYPE 7'b0010011
`define IL_TYPE 7'b0000011
`define B_TYPE 7'b1100011
`define U_TYPE 7'b0010111
`define UL_TYPE 7'b0110111
`define J_TYPE 7'b1101111
`define JL_TYPE 7'b1100111

// R_type instrucktion
`define ADD 4'b0000        
`define SUB 4'b1000       
`define SLL 4'b0001        
`define SLT 4'b0010      
`define SLTU 4'b0011       
`define XOR 4'b0100     
`define SRL 4'b0101      
`define SRA 4'b1101     
`define OR 4'b0110    
`define AND 4'b0111       

// B type instrucktion
`define BEQ 4'b0000
`define BNE 4'b0001
`define BLT 4'b0100
`define BGE 4'b0101
`define BLTU 4'b0110
`define BGEU 4'b0111

// S type instrucktion
`define SB 3'b000
`define SH 3'b001
`define SW 3'b010


// MMIO Address Map
`define ROM 32'h00000000