/* TODO: INSERT NAME AND PENNKEY HERE */

`timescale 1ns / 1ps
`default_nettype none

module lc4_divider(input  wire [15:0] i_dividend,
                   input  wire [15:0] i_divisor,
                   output wire [15:0] o_remainder,
                   output wire [15:0] o_quotient);

      /*** YOUR CODE HERE ***/
      wire [15:0] array_dividend  [0:16];
      wire [15:0] array_remainder [0:16];
      wire [15:0] array_quotient  [0:16];
      assign array_dividend[0]  = i_dividend;
      assign array_remainder[0] = 16'b0; 
      assign array_quotient[0]  = 16'b0;  

      genvar i;
      for(i = 0; i < 16; i = i + 1 ) begin
            lc4_divider_one_iter inst_div(
                  .i_dividend(array_dividend[i]),
                  .i_divisor(i_divisor),
                  .i_quotient(array_quotient[i]),
                  .i_remainder(array_remainder[i]),
                  .o_dividend(array_dividend[i+1]),
                  .o_quotient(array_quotient[i+1]),
                  .o_remainder(array_remainder[i+1])
            );
      end

      assign o_remainder = (i_divisor == 0) ? 16'b0 : array_remainder[16];
      assign o_quotient  = (i_divisor == 0) ? 16'b0 : array_quotient[16];


endmodule // lc4_divider

module lc4_divider_one_iter(input  wire [15:0] i_dividend,
                            input  wire [15:0] i_divisor,
                            input  wire [15:0] i_remainder,
                            input  wire [15:0] i_quotient,
                            output wire [15:0] o_dividend,
                            output wire [15:0] o_remainder,
                            output wire [15:0] o_quotient);

      /*** YOUR CODE HERE ***/
      wire [15:0] remainder_temp;
      assign remainder_temp = ((i_remainder << 1) | ((i_dividend >> 15) & 1));
      assign o_quotient     = (remainder_temp < i_divisor) ? (i_quotient << 1) : ((i_quotient << 1) | 1);
      assign o_remainder    = (remainder_temp < i_divisor) ? remainder_temp : (remainder_temp - i_divisor);
      assign o_dividend = i_dividend << 1;

endmodule

/*
int divide(int dividend, int divisor) {
    int quotient = 0;
    int remainder = 0;

    if (divisor == 0) {
        return 0;
    }

    for (int i = 0; i < 16; i++) {
        remainder = (remainder << 1) | ((dividend >> 15) & 0x1);
        if (remainder < divisor) {
            quotient = (quotient << 1);
        } else {
            quotient = (quotient << 1) | 0x1;
            remainder = remainder - divisor;
        }

        dividend = dividend << 1;
    }

    return quotient;
}
*/