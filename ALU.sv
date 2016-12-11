/*
As you are given it, this ALU only implements Add
*/

module ALU(input logic  [31:0] I1,
	   input logic [31:0] I2,
	   input logic [4:0] Selector,
	   output logic [31:0] O,
	   output logic [0:0] zero
	   );

   //need a buch of logics to compute everything the ALU does, then mux them to select the right one, using Selector
   logic [31:0] sum, nor_ins, nori_ins, not_ins, rolv, rorv, bleu;
   assign sum = I1 + I2;
   assign nor_ins = (~I1)&(~I2);
   assign not_ins = ~I1;
   assign nori_ins = (~I1)&(~I2);

   //ROTATE
   logic [31:0] rolv0, rolv1, rolv2, rolv3, rolv4, rolv5, rolv6, rolv7;
   assign rolv0 = I2;
   assign rolv1 = {I2[30:0], I2[31:31]};
   assign rolv2 = {I2[29:0], I2[31:30]};
   assign rolv3 = {I2[28:0], I2[31:29]};
   assign rolv4 = {I2[27:0], I2[31:28]};
   assign rolv5 = {I2[26:0], I2[31:27]};
   assign rolv6 = {I2[25:0], I2[31:26]};
   assign rolv7 = {I2[24:0], I2[31:25]};

   logic [31:0] rorv0, rorv1, rorv2, rorv3, rorv4, rorv5, rorv6, rorv7;
   assign rorv0 = I2;
   assign rorv1 = {I2[0:0], I2[31:1]};
   assign rorv2 = {I2[1:0], I2[31:2]};
   assign rorv3 = {I2[2:0], I2[31:3]};
   assign rorv4 = {I2[3:0], I2[31:4]};
   assign rorv5 = {I2[4:0], I2[31:5]};
   assign rorv6 = {I2[5:0], I2[31:6]};
   assign rorv7 = {I2[6:0], I2[31:7]};

   mux8to1B32 muxrolv(I1[2:2], I1[1:1], I1[0:0], rolv7, rolv6, rolv5, rolv4, rolv3, rolv2, rolv1, rolv0, rolv);
   mux8to1B32 muxrorv(I1[2:2], I1[1:1], I1[0:0], rorv7, rorv6, rorv5, rorv4, rorv3, rorv2, rorv1, rorv0, rorv);

   //Brach conditional
   logic [31:0] rtminusrs;
   assign rtminusrs = I2 + (~I1 + 1'b1);
   assign zero = ~(rtminusrs[31:31]);

   always_comb
     case(Selector)
       0:O=rolv;
       1:O=rorv;
       2:O=not_ins;
       7:O=nori_ins;
       16:O=sum;
       19:O=nor_ins;
       default:O=sum;
     endcase // case (Selector)

  // logic [31:0] m1, m2, m3;   
	
endmodule
