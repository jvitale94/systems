//New mux that has 8 inputs and 3 controls. Self-explanatory
module mux8to1B32 (input logic C2, input logic C1, input logic C0,
		   input logic [31:0] I7, input logic [31:0] I6,
		   input logic[31:0] I5, input logic [31:0] I4, 
		   input logic [31:0] I3, input logic [31:0] I2,
		   input logic [31:0] I1, input logic [31:0] I0,
		   output logic [31:0] O);

   //Built out of 3 4to1 mux's
   logic [31:0] O1, O2;
   mux4to1B32 s1(C2,C1,I6,I4,I2,I0,O1);
   mux4to1B32 s2(C2,C1,I7,I5,I3,I1,O2);
   mux4to1B32 s3(1'b0,C0,32'b111111,32'b010101,O2,O1,O);
   
endmodule