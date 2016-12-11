/* The beginning of a register set */

module registerFile(input logic [4:0] A1,
		    input logic [4:0] A2,
		    input logic [4:0] A3,
		    input logic [0:0] CLK,
		    input logic [0:0] WE3,
		    input logic [31:0] WD3,
		    output logic [31:0] RD1,
		    output logic [31:0] RD2
		    );
   
   //used as the writeEnables for registers below
   logic  [0:0] yesWrite0;
   logic  [0:0] yesWrite1;
   logic  [0:0] yesWrite2;
   logic  [0:0] yesWrite3;
   logic  [0:0] yesWrite4;
   logic  [0:0] yesWrite5;
   logic  [0:0] yesWrite6;
   logic  [0:0] yesWrite7;

   //the values in each register
   logic [31:0]  reg0, reg1, reg2, reg3, reg4, reg5, reg6, reg7;

   //Only one of these will be high since you can only write one register at a time
   assign yesWrite0 = WE3 &  ~A3[2] & ~A3[1] & ~A3[0];
   assign yesWrite1 = WE3 &  ~A3[2] & ~A3[1] & A3[0];
   assign yesWrite2 = WE3 &  ~A3[2] & A3[1] & ~A3[0];
   assign yesWrite3 = WE3 &  ~A3[2] & A3[1] & A3[0];
   assign yesWrite4 = WE3 &  A3[2] & ~A3[1] & ~A3[0];
   assign yesWrite5 = WE3 &  A3[2] & ~A3[1] & A3[0];
   assign yesWrite6 = WE3 &  A3[2] & A3[1] & ~A3[0];
   assign yesWrite7 = WE3 &  A3[2] & A3[1] & A3[0];

   //at most one register will have a high yesWrite
   enabledRegister r0(WD3,reg0,CLK,yesWrite0);
   enabledRegister r1(WD3,reg1,CLK,yesWrite1);
   enabledRegister r2(WD3,reg2,CLK,yesWrite2);
   enabledRegister r3(WD3,reg3,CLK,yesWrite3);
   enabledRegister r4(WD3,reg4,CLK,yesWrite4);
   enabledRegister r5(WD3,reg5,CLK,yesWrite5);
   enabledRegister r6(WD3,reg6,CLK,yesWrite6);
   enabledRegister r7(WD3,reg7,CLK,yesWrite7);

   //mux's to read out the registers. We use the 8 to 1 mux we built to choose the correct register for A1 and A2
   mux8to1B32 mpxA1(A1[2], A1[1],A1[0],reg7,reg6,reg5,reg4,reg3,reg2,reg1,reg0, RD1);
   mux8to1B32 mpxA2(A2[2], A2[1],A2[0],reg7,reg6,reg5,reg4,reg3,reg2,reg1, reg0, RD2);

   always @ (negedge CLK)
     begin
	$display("*****NEW INSTRUCTION******");
	$display("register 0 %h ",reg0);
	$display("register 1 %h ",reg1);
	$display("register 2 %h ",reg2);
	$display("register 3 %h ",reg3);
	$display("register 4 %h ",reg4);
	$display("register 5 %h ",reg5);
	$display("register 6 %h ",reg6);
	$display("register 7 %h ",reg7);
     end
   
endmodule


