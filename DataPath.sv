module DataPath(clock, pcQ, instr, pcD, regWriteEnable);

   // The clock will be driven from the testbench 
   // The instruction, pcQ and pcD are sent to the testbench to
   // make debugging easier
   input logic clock;
   output logic [31:0] instr;
   output logic [31:0] pcQ;
   output logic [31:0] pcD;
   output logic [0:0] regWriteEnable;
   logic [0:0] 	memWrite, RegDst, ALUSrc, MemtoReg, Branch, JumpReg, JumpandLink, alu4, alu3, alu2, alu1, alu0;
   
   // The PC is just a register
   // for now, it is always enabled so it updates on every clock cycle
   // Its ports are above
   enabledRegister PC(pcD,pcQ,clock,1'b1);

   //set up a hard-wired connection to a value
   logic [31:0] constant4;
   
   initial
     constant4 <= 32'b100;

   // construct the adder for the PC incrementing circuit.
   logic [31:0] adderIn1, adderIn2, adderOut, pcmux, jumpins, jumpout;
   logic [31:0]        WD3, RD1, RD2;
   adder psAdd(adderIn1,adderIn2,adderOut);
   logic [0:0] 	       zero;
   logic [31:0]        PCBranch;
   //The mux before PC. Incomplete, but change when doing branch
   mux4to1B32 BranchorPlus4(1'b0, (Branch & zero), 32'b111111, 32'b101010, PCBranch, adderOut, pcmux);

   mux4to1B32 JALorJR(JumpandLink, JumpReg, 32'b111111, jumpins, RD1/*contents of register 7*/, pcmux, jumpout);
   
   assign jumpins = {adderOut[31:28], instr[25:0], {2{1'b0}}};

   assign adderIn1 = pcQ;
   assign adderIn2 = constant4;
   assign pcD = jumpout;

   always @ (negedge clock)
     begin
	$display ("PCD %b", pcD);
     end
   

   //Instruction Memory
   logic [31:0] instA;
   instructionMemory imem(instA,instr);
   assign instA = pcQ;

   //CONTROL UNIT
   //Control outputs
   //logic [0:0] 	memWrite, RegDst, ALUSrc, MemtoReg, Branch, JumpReg, JumpandLink, alu4, alu3, alu2, alu1, alu0;
   logic [4:0] 	ALUControl;
   Control theControl(instr, memWrite, regWriteEnable, RegDst,ALUSrc, MemtoReg,ALUControl,Branch, JumpReg, JumpandLink, alu4, alu3, alu2, alu1, alu0);

   //Display Control outputs
   always @ (negedge clock)
     begin
	$display ("RegDst %b", RegDst);
	$display ("memWrite %b", memWrite);
	$display ("ALUSrc %b", ALUSrc);
	$display ("MemtoReg %b", MemtoReg);
	$display ("ALUControl %b", ALUControl);
	$display ("JumpReg %b", JumpReg);
	$display ("JumpandLink %b", JumpandLink);
	$display ("Branch %b", Branch);
	$display ("zero %b", zero);
     end
   
   //Register File
   logic [4:0] 	       A3, A2, A1, muxA3, finalA3, finalA1;
   logic 	       WE3;
   //logic [31:0]        WD3, RD1, RD2;
   
   assign A2 = instr[20:16];
   assign clk = clock;
   mux2to1B5 muxforjr(JumpReg, 5'b00111, instr[25:21], finalA1);
   
   assign A1 = finalA1;	
   assign WE3 = regWriteEnable;
   //Change control when r-type is finished. It will be RegDst
   mux2to1B5 muxforA3(RegDst, instr[15:11], instr[20:16], muxA3);
   mux2to1B5 muxA3final (JumpandLink, 5'b00111, muxA3, finalA3);
   
   assign A3 = finalA3;

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
   //logic [31:0]        PCBranch;
   adder BrachAdd(SignShift,adderOut,PCBranch);

   always @ (negedge clock)
     begin
	$display("SignImm   %b", SignImm);
	$display("SignShift %b", SignShift);
	$display("adderOut  %b", adderOut);
	$display("PCBranch  %h", PCBranch);
     end
   
   //ALU
   logic [31:0]        SrcA, SrcB, ALUResult, ALUmuxOut;
   logic [4:0] 	       aluSelect;
   //logic [0:0] 	       zero;
   assign SrcA = RD1;
   mux4to1B32 muxforALUSrcB(1'b0,ALUSrc, 32'b111111, 32'b101010, SignImm, RD2, ALUmuxOut);
   assign SrcB = ALUmuxOut;
   
   ALU theALU(SrcA, SrcB, ALUControl, ALUResult, zero);

   always @ (negedge clock)
     begin
	$display("SrcA %b", SrcA);
	$display("SrcB %b", SrcB);
	$display("ALUResult %b", ALUResult);
     end

   //Data Memory
   logic [31:0]   RD;
   logic [31:0]        WD,dataA, ALUorData, finalWD3;
   logic [0:0] 	       WE;
   assign WD = RD2;
   assign dataA = ALUResult;
   assign WE = memWrite;
   dataMemory data(dataA, RD, WD, clk, WE);

   //What is read back to register file?
   mux4to1B32 muxALUorRD(1'b0, MemtoReg, 32'b111111, 32'b101010, RD, ALUResult, ALUorData);
   mux4to1B32 muxfinalWD3(1'b0, JumpandLink, 32'b111111, 32'b101010, adderOut, ALUorData, finalWD3);
   
   assign WD3 = finalWD3;
   always @ (negedge clock)
     begin
	$display("RD %b", RD);
	$display("WD3 %b", WD3);
     end
   
   
endmodule

