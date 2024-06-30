/* TODO: INSERT NAME AND PENNKEY HERE */

`timescale 1ns / 1ps
`default_nettype none

/**
 * @param a first 1-bit input
 * @param b second 1-bit input
 * @param g whether a and b generate a carry
 * @param p whether a and b would propagate an incoming carry
 */
module gp1(input wire a, b,
           output wire g, p);
   assign g = a & b;
   assign p = a | b;
endmodule

/**
 * Computes aggregate generate/propagate signals over a 4-bit window.
 * @param gin incoming generate signals 
 * @param pin incoming propagate signals
 * @param cin the incoming carry
 * @param gout whether these 4 bits collectively generate a carry (ignoring cin)
 * @param pout whether these 4 bits collectively would propagate an incoming carry (ignoring cin)
 * @param cout the carry outs for the low-order 3 bits
 */
module gp4(input wire [3:0] gin, pin,
           input wire cin,
           output wire gout, pout,
           output wire [2:0] cout);
  
   assign cout[0] = gin[0] | (pin[0] & cin);
   assign cout[1] = gin[1] | (pin[1] & gin[0]) | (pin[1] & pin[0] & cin);
   assign cout[2] = gin[2] | (pin[2] & gin[1]) | (pin[2] & pin[1] & gin[0]) | (pin[2] & pin[1] & pin[0] & cin);
   assign gout = gin[3] | (pin[3] & gin[2]) | (pin[3] & pin[2] & gin[1]) | (pin[3] & pin[2] & pin[1] & gin[0]);
   assign pout = pin[3] & pin[2] & pin[1] & pin[0];
   
endmodule


/**
 * 16-bit Carry-Lookahead Adderwhether these 4 bits collectively generate a carry (ignoring cin)
 * @param a first input
 * @param b second input(pin[3] & pin[2] & pin[1] & gin[0])
 * @param cin carry in
 * @param sum sum of a + b + carry-in
 */
module cla16
  (input wire [15:0] a, b,
   input wire cin,
   output wire [15:0] sum);

   wire [15:0] g, p;  // Single bit generate and propagate signals for each bit
   wire [4:0] g4, p4; // Generate and propagate signals for each 4-bit block
   wire [15:0] carry; // Carry signals for each bit

   // Instantiate 16 gp1 blocks
   genvar i;
   generate
      for (i = 0; i < 16; i = i + 1) begin : gen1
         gp1 gp1_inst (
            .a(a[i]),
            .b(b[i]),
            .g(g[i]),
            .p(p[i])
         );
      end
   endgenerate

   // Instantiate 4 gp4 blocks using the outputs of gp1 blocks
   gp4 gp4_0 (.gin(g[3:0]), .pin(p[3:0]), .cin(cin), .gout(g4[0]), .pout(p4[0]), .cout(carry[2:0]));
   gp4 gp4_1 (.gin(g[7:4]), .pin(p[7:4]), .cin(carry[3]), .gout(g4[1]), .pout(p4[1]), .cout(carry[6:4]));
   gp4 gp4_2 (.gin(g[11:8]), .pin(p[11:8]), .cin(carry[7]), .gout(g4[2]), .pout(p4[2]), .cout(carry[10:8]));
   gp4 gp4_3 (.gin(g[15:12]), .pin(p[15:12]), .cin(carry[11]), .gout(g4[3]), .pout(p4[3]), .cout(carry[14:12]));

   gp4 gp4_second_level(
        .gin(g4[3:0]),
        .pin(p4[3:0]),
        .cin(cin),
        .gout(g4[4]),
        .pout(p4[4]),
        .cout({carry[11], carry[7], carry[3]})
   );

  assign carry[15] = g4[4] | p4[4] & cin;

  genvar k;
  generate
    for(k = 1; k < 16; k = k + 1) begin: gen2
      assign sum[k] = a[k] ^ b[k] ^ carry[k-1];
    end
  endgenerate 
  assign  sum[0] = a[0] ^ b[0] ^ cin;

endmodule




/** Lab 2 Extra Credit, see details at
  https://github.com/upenn-acg/cis501/blob/master/lab2-alu/lab2-cla.md#extra-credit
 If you are not doing the extra credit, you should leave this module empty.
 */
module gpn
  #(parameter N = 4)
  (input wire [N-1:0] gin, pin,
   input wire cin,
   output wire gout, pout,
   output wire [N-2:0] cout);
   
   genvar i;
   generate
      for (i = 0; i < N-1; i = i + 1) begin : gen_gpn
         assign cout[i] = gin[i] | (pin[i] & (i == 0 ? cin : cout[i-1]));
      end
   endgenerate
   
   assign gout = gin[N-1] | (pin[N-1] & cout[N-2]);
   assign pout = &pin; 
   
endmodule
