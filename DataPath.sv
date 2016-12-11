module DataPath(clock, pcQ, instr, pcD, regWriteEnable);
   
   input logic clock;
   output logic [31:0] instr;
   output logic [31:0] pcQ;
   output logic [31:0] pcD;
   output logic [0:0] regWriteEnable;
   //These are the control outputs. We declared them up here because we use them in the mux's for brach and jump and the code would not run correctly if they were not declared before using them as controls for the mux's
   logic [0:0] 	memWrite, RegDst, ALUSrc, MemtoReg, Branch, JumpReg, JumpandLink, alu4, alu3, alu2, alu1, alu0;
   
   // The PC register
   enabledRegister PC(pcD,pcQ,clock,1'b1);
   logic [31:0] constant4;
   initial
     constant4 <= 32'b100;

   //controls and operands for the PC+4 and mux's that choose branch/jump addresses
   logic [31:0] adderIn1, adderIn2, adderOut, pcmux, jumpins, jumpout;
   //These are used in the register file, but declared up here for the same reason as the control signals above
   logic [31:0]        WD3, RD1, RD2;
   adder psAdd(adderIn1,adderIn2,adderOut);
   logic [0:0] 	       zero;
   logic [31:0]        PCBranch;

   //Two mux's before the PC register that either pass in PC+4 or the address for the branch
   mux4to1B32 BranchorPlus4(1'b0, (Branch & zero), 32'b111111, 32'b101010, PCBranch, adderOut, pcmux);
   mux4to1B32 JALorJR(JumpandLink, JumpReg, 32'b111111, jumpins, RD1, pcmux, jumpout);

   
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
   //Control outputs are declared above
   logic [4:0] 	ALUControl;
   Control theControl(instr, memWrite, regWriteEnable, RegDst,ALUSrc, MemtoReg,ALUControl,Branch, JumpReg, JumpandLink, alu4, alu3, alu2, alu1, alu0);

   //Display Control outputs
   always @ (negedge clock)
     begin
	$display("****Control Signals****");
	$display ("RegDst %b", RegDst);
	$display ("memWrite %b", memWrite);
	$display ("ALUSrc %b", ALUSrc);
	$display ("MemtoReg %b", MemtoReg);
	$display ("ALUControl %b", ALUControl);
	$display ("JumpReg %b", JumpReg);
	$display ("JumpandLink %b", JumpandLink);
	$display ("Branch %b", Branch);
	//This is output by the ALU, but is used in the same manner as a contorl control, so we print it here
	$display ("zero %b", zero);
     end
   
   //Register File
   logic [4:0] 	       A3, A2, A1, muxA3, finalA3, finalA1;
   logic 	       WE3;
   
   assign A2 = instr[20:16];
   assign clk = clock;

   //If jr is the instruction, we want to read out register 7. If it is not, then we just read out the address of Rs 
   mux2to1B5 muxforjr(JumpReg, 5'b00111, instr[25:21], finalA1);
   
   assign A1 = finalA1;	
   assign WE3 = regWriteEnable;

   //Mux for which register is the destination based on r or i type inst.
   mux2to1B5 muxforA3(RegDst, instr[15:11], instr[20:16], muxA3);

   //one more mux to write to register 7 if the instruction is jump and link, or the register decided above if not
   mux2to1B5 muxA3final (JumpandLink, 5'b00111, muxA3, finalA3);
   
   assign A3 = finalA3;

   always @ (negedge clock)
     begin
	$display("A3 %b", A3);
     end
   
   registerFile theRegisters(A1,A2, 
			     A3, clk, WE3, WD3, RD1, RD2);

   //Sign Extend or shift for the bracnh calculation
   logic [31:0]        SignImm, SignShift;
   assign SignImm = {{16{instr[15]}}, instr[15:0]};
   assign SignShift = {SignImm[29:0], {2{1'b0}}};

   //adder to calculate the branch address
   adder BrachAdd(SignShift,adderOut,PCBranch);

   //check to see if the sign extending works correctly
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
   assign SrcA = RD1;
   
   mux4to1B32 muxforALUSrcB(1'b0,ALUSrc, 32'b111111, 32'b101010, SignImm, RD2, ALUmuxOut);
   assign SrcB = ALUmuxOut;

   //zero is declared in line 22 because it is used as a control for a mux up there
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

   //These mux's choose whether to use the ALU result or the Data Memory output, and then either the PC+4 (which stores the location to return to when jr is called) or what was previously decided in the first mux
   mux4to1B32 muxALUorRD(1'b0, MemtoReg, 32'b111111, 32'b101010, RD, ALUResult, ALUorData);
   mux4to1B32 muxfinalWD3(1'b0, JumpandLink, 32'b111111, 32'b101010, adderOut, ALUorData, finalWD3);
   
   assign WD3 = finalWD3;
   always @ (negedge clock)
     begin
	$display("RD %b", RD);
	$display("WD3 %b", WD3);
     end
   
   
endmodule

