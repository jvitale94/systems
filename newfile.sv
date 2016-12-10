module somethingelse(clock, pcQ, instr, pcD, regWriteEnable);

   // The clock will be driven from the testbench 
   // The instruction, pcQ and pcD are sent to the testbench to
   // make debugging easier
   

   input logic clock;
   output logic [31:0] instr;
   output logic [31:0] pcQ;
   output logic [31:0] pcD;
   output logic [0:0] regWriteEnable;
   
   // The PC is just a register
   // for now, it is always enabled so it updates on every clock cycle
   // Its ports are above
   
   enabledRegister PC(pcD,pcQ,clock,1'b1);

   // set up a hard-wired connection to a value
   
   logic [31:0] constant4;

   initial
     constant4 <= 32'b100;

   // construct the adder for the PC incrementing circuit.

   logic [31:0] adderIn1, adderIn2, adderOut, pcmux;
   
   adder psAdd(adderIn1,adderIn2,adderOut);

   // Connect the adder to the right inputs and output
   // notice that using pcD and pcQ here and above in the PC register is like
   // connecting a wire  BUT the wires have a direction. E.g. the first
   // line below says a signal goes from pcQ to adderIn1

   //The mux before PC. Incomplete, but change when doing branch
   mux4to1B32 PCprime(1'b0, 1'b0/*change this for branch*/, 32'b111111, 32'b101010, 32'b010101, adderOut, pcmux);
   
   
   assign adderIn1 = pcQ;
   assign adderIn2 = constant4;
   assign pcD = pcmux;

   
   // construct the instuctionmemory
   // wired to PC and instruction

   logic [31:0] instA;
   
   instructionMemory imem(instA,instr);

   // Wire instruction memory

   assign instA = pcQ;

   // construct the control unit  This unit generates the signals that control the datapath
   // it will have many more ports later


   //Change these????? Edit ALU file to output a shit load more control signals?
   logic [0:0] 	memWrite, alu4, alu3, alu2, alu1, alu0;
   
   
   Control theControl(instr, memWrite, regWriteEnable, alu4, alu3, alu2, alu1, alu0);
   
   
   // construct the register file with (currently mostly) unused values to connect to it
   
   logic [4:0] 	       A3, A2, A1, muxA3;
   logic 	       WE3;
   logic [31:0]        WD3, RD1, RD2;
   assign A2 = instr[20:16];

   //Change control when r-type is finished. It will be RegDst
   mux2to1B5 muxforA3(1'b0, instr[20:16], instr[15:11], muxA3); 
   assign A3 = muxA3;
   
   
   registerFile theRegisters(A1,A2, 
			     A3, clk, WE3, WD3, RD1, RD2);

   // attach the A1 port to 5 bits of the instruction

   logic [31:0]   RD;

   assign clk = clock;
   assign A1 = instr[25:21];	
   assign WE3 = regWriteEnable;
   
   
   logic [31:0]        SignImm;

   // sign extend the immediate field
   //  
   assign SignImm = {{16{instr[15]}}, instr[15:0]};

   logic [31:0]        SrcA, SrcB, ALUResult, ALUmuxOut;
   logic [4:0] 	       aluSelect;
   assign SrcA = RD1;

   mux4to1B32 muxforALUSrcB(1'b0, 1'b1/*CHANGE TO ALUSRC*/,  32'b111111, 32'b101010, SignImm, 32'b010101, ALUmuxOut);
   
   assign SrcB = ALUmuxOut;
   
   ALU theALU(SrcA, SrcB, 5'b0, ALUResult);
   
   logic [31:0]        WD,dataA, ALUorData;
   logic [0:0] 	       WE;

   
   assign WD = RD2;
   assign dataA = ALUResult;
   assign WE = memWrite;
   
   dataMemory data(dataA, RD, WD, clk, WE);

   mux4to1B32 muxALUorRD(1'b0, 1'b1, 32'b111111, 32'b101010, RD, ALUResult, ALUorData);

   assign WD3 = ALUorData;
   
endmodule

