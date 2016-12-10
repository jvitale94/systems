/*
As you are given it, this ALU only implements Add
*/

module ALU(input logic  [31:0] I1,
	   input logic [31:0] I2,
	   input logic [4:0] Selector,
	   output logic [31:0] O
	   );

   //need a buch of logics to compute everything the ALU does, then mux them to select the right one, using Selector
   logic [31:0] sum, nor_ins, nori_ins, not_ins, rolv, rorv, bleu;
   assign sum = I1 + I2;
   assign nor_ins = (~I1)&(~I2);
   assign not_ins = ~I1;
   assign nori_ins = (~I1)&(~I2);

   logic [4:0] 	Rsbits;

   assign Rsbits = I1 [4:0];
   

   always_comb
     case(Selector)
       2:O=not_ins;
       7:O=nori_ins;
       16:O=sum;
       19:O=nor_ins;
       default:O=sum;
     endcase // case (Selector)

   

  // logic [31:0] m1, m2, m3;   
  // assign O = sum;
   
   
	
endmodule