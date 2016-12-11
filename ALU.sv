module ALU(input logic  [31:0] I1,
	   input logic [31:0] I2,
	   input logic [4:0] Selector,
	   output logic [31:0] O,
	   output logic [0:0] zero
	   );

   //these variables will store the correct the outputs for each operation
   //below are the simple sum, nor and not operations
   logic [31:0] sum, nor_ins, nori_ins, not_ins, rolv, rorv;
   assign sum = I1 + I2;
   assign nor_ins = (~I1)&(~I2);
   assign not_ins = ~I1;
   assign nori_ins = (~I1)&(~I2);

   //ROTATE - we hardcoded each possible rotation up to 7 bit shift distance
   //below are the mulitplexers to choose the correct rotation amount
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

   //Brach conditional - this subtracts the Rs from Rt and sees if the result is negative or positive
   logic [31:0] rtminusrs;
   assign rtminusrs = I2 + (~I1 + 1'b1);
   assign zero = ~(rtminusrs[31:31]);

   //Here we have all the outputs correctly calculated. We now need to choose the correct one based on the Selector, which we chose to be the first 5 bits of the instruction. We set up control signals for each output and then use mux's to choose the output based on which contorl is high.
   logic [0:0] 	sum_con, nor_con, not_con, rolv_con, rorv_con;
   assign sum_con = Selector[4] & ~Selector[3] & ~Selector[1];
   assign nor_con = ~Selector[3] & Selector[1] & Selector[0];
   assign not_con = ~Selector[4] & ~Selector[3] & ~Selector[2] & Selector[1] & ~Selector[0];
   assign rolv_con = ~Selector[4] & ~Selector[3] & ~Selector[2] & ~Selector[1] & ~Selector[0];
   assign rorv_con = ~Selector[4] & ~Selector[3] & ~Selector[2] & ~Selector[1] & Selector[0];

   logic [31:0] summuxout, normuxout, rolvmuxout, rorvmuxout;

   mux4to1B32 summux(1'b0, sum_con, 32'b111111, 32'b01010101, sum, 32'b1100110011, summuxout);
    mux4to1B32 normux(1'b0, nor_con, 32'b111111, 32'b01010101, nor_ins, summuxout, normuxout);
    mux4to1B32 rolvmux(1'b0, rolv_con, 32'b111111, 32'b01010101, rolv, normuxout, rolvmuxout);
    mux4to1B32 rorvmux(1'b0, rorv_con, 32'b111111, 32'b01010101, rorv, rolvmuxout, rorvmuxout);
   mux4to1B32 notmux(1'b0, not_con, 32'b111111, 32'b01010101, not_ins, rorvmuxout, O);
	
endmodule
