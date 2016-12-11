module Control(ins, memWrite, regWriteEnable, RegDst, ALUSrc, MemtoReg,ALUControl, Branch,JumpReg, JumpandLink, alu4, alu3, alu2, alu1, alu0);

   input logic [31:0] ins;
   output logic [0:0] memWrite, regWriteEnable, RegDst, ALUSrc, MemtoReg, Branch, JumpReg, JumpandLink, alu4, alu3, alu2, alu1, alu0;
   output logic [4:0] ALUControl;

   logic [0:0] lw, sw, add, jr, jal, nor_ins, nori_ins, not_ins, bleu, rolv, rorv;
   //Only one of these will be high, since the OPCODE is unique for each instruction
   assign lw = ins[31] & ~ins[30] & ~ins[29] & ~ins[28] & ins[27] & ins[26];
   assign sw = ins[31] & ~ins[30] & ins[29] & ~ins[28] & ins[27] & ins[26];
   assign add = ins[31] & ~ins[30] & ~ins[29] & ~ins[28] & ~ins[27] & ~ins[26];
   assign jr = ~ins[31] & ~ins[30] & ins[29] & ~ins[28] & ~ins[27] & ~ins[26];
   assign jal = ~ins[31] & ~ins[30] & ~ins[29] & ~ins[28] & ins[27] & ins[26];
   assign nor_ins = ins[31] & ~ins[30] & ~ins[29] & ins[28] & ins[27] & ~ins[26];
   assign nori_ins = ~ins[31] & ~ins[30] & ins[29] & ins[28] & ins[27] & ~ins[26];
   assign not_ins = ~ins[31] & ~ins[30] & ~ins[29] & ins[28] & ~ins[27] & ~ins[26];
   assign bleu = ~ins[31] & ins[30] & ~ins[29] & ~ins[28] & ~ins[27] & ~ins[26];
   assign rolv = ~ins[31] & ~ins[30] & ~ins[29] & ~ins[28] & ~ins[27] & ~ins[26];
   assign rorv = ~ins[31] & ~ins[30] & ~ins[29] & ~ins[28] & ins[27] & ~ins[26];

   //We decided to use the first 5 bits of the instruction for the ALUControl becuase they are unique for each instruction that uses the ALU
   assign alu0 = ins[27];
   assign alu1 = ins[28];
   assign alu2 = ins[29];
   assign alu3 = ins[30];
   assign alu4 = ins[31];
   assign ALUControl = {alu4, alu3, alu2, alu1, alu0};

   //Corresponding controls will be high when they need to be
   assign ALUSrc = (lw | sw | nori_ins);
   assign RegDst = (add |not_ins| nor_ins | rolv | rorv);
   assign regWriteEnable = (jal|lw|add|nor_ins|nori_ins|not_ins|rolv|rorv);
   assign memWrite = sw;
   assign MemtoReg = lw;
   assign Branch = bleu;
   assign JumpReg = jr;
   assign JumpandLink = jal;
   
   
   
   

   endmodule