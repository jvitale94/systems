module DataPath(clock, pcQ, instr, pcD, regWriteEnable);

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

   //set up a hard-wired connection to a value
   logic [31:0] constant4;
   initial
     constant4 <= 32'b100;

   // construct the adder for the PC incrementing circuit.
   logic [31:0] adderIn1, adderIn2, adderOut, pcmux;
   adder psAdd(adderIn1,adderIn2,adderOut);

   //The mux before PC. Incomplete, but change when doing branch
   mux4to1B32 PCprime(1'b0, 1'b0/*change this for branch*/, 32'b111111, 32'b101010, 32'b010101, adderOut, pcmux);
   
   assign adderIn1 = pcQ;
   assign adderIn2 = constant4;
   assign pcD = pcmux;

   //Instruction Memory
   logic [31:0] instA;
   instructionMemory imem(instA,instr);
   assign instA = pcQ;

   //CONTROL UNIT
   //Control outputs
   logic [0:0] 	memWrite, RegDst, ALUSrc, MemtoReg, Branch, alu4, alu3, alu2, alu1, alu0;
   logic [4:0] 	ALUControl;
   Control theControl(instr, memWrite, regWriteEnable, RegDst,ALUSrc, MemtoReg,ALUControl,Branch, alu4, alu3, alu2, alu1, alu0);

   //Display Control outputs
   always @ (negedge clock)
     begin
	$display ("RegDst %b", RegDst);
	$display ("memWrite %b", memWrite);
	$display ("ALUSrc %b", ALUSrc);
	$display ("MemtoReg %b", MemtoReg);
	$display ("ALUControl %b", ALUControl);
     end
   
   //Register File
   logic [4:0] 	       A3, A2, A1, muxA3;
   logic 	       WE3;
   logic [31:0]        WD3, RD1, RD2;
   
   assign A2 = instr[20:16];
   assign clk = clock;
   assign A1 = instr[25:21];	
   assign WE3 = regWriteEnable;
   //Change control when r-type is finished. It will be RegDst
   mux2to1B5 muxforA3(RegDst, instr[15:11], instr[20:16], muxA3);
   assign A3 = muxA3;

   always @ (negedge clock)
     begin
	$display("A3 %b", A3);
     end
   
   registerFile theRegisters(A1,A2, 
			     A3, clk, WE3, WD3, RD1, RD2);

   //Sign Extend      
   logic [31:0]        SignImm, SignShift;
   assign SignImm = {{16{instr[15]}}, instr[15:0]};
   assign SignShift = {SignImm[29:0], {2{1'b0}}};

  // logic [31:0]        BranchadderIn1, BranchadderIn2, PCBranch;
  // assign BranchadderIn1 = SignShift;
  // assign BranchadderIn2 = adderOut;
   logic [31:0]        PCBranch;
   adder BrachAdd(SignShift,adderOut,PCBranch);

   always @ (negedge clock)
     begin
	$display("SignImm   %b", SignImm);
	$display("SignShift %b", SignShift);
	$display("adderOut %b", adderOut);
	$display("PCBranch %b", PCBranch);
     end
   
   //ALU
   logic [31:0]        SrcA, SrcB, ALUResult, ALUmuxOut;
   logic [4:0] 	       aluSelect;
   assign SrcA = RD1;
   mux4to1B32 muxforALUSrcB(1'b0,ALUSrc, 32'b111111, 32'b101010, SignImm, RD2, ALUmuxOut);
   assign SrcB = ALUmuxOut;
   
   ALU theALU(SrcA, SrcB, ALUControl, ALUResult);

   always @ (negedge clock)
     begin
	$display("SrcA %b", SrcA);
	$display("SrcB %b", SrcB);
	$display("ALUResult %b", ALUResult);
     end

   //Data Memory
   logic [31:0]   RD;
   logic [31:0]        WD,dataA, ALUorData;
   logic [0:0] 	       WE;
   assign WD = RD2;
   assign dataA = ALUResult;
   assign WE = memWrite;
   dataMemory data(dataA, RD, WD, clk, WE);

   //What is read back to register file?
   mux4to1B32 muxALUorRD(1'b0, MemtoReg, 32'b111111, 32'b101010, RD, ALUResult, ALUorData);
   assign WD3 = ALUorData;
   always @ (negedge clock)
     begin
	$display("RD %b", RD);
	$display("WD3 %b", WD3);
     end
   
   
endmodule

