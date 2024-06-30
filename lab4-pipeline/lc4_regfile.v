/* TODO: Names of all group members
 * TODO: PennKeys of all group members
 *
 * lc4_regfile.v
 * Implements an 8-register register file parameterized on word size.
 *
 */

`timescale 1ns / 1ps

// Prevent implicit wire declaration
`default_nettype none

module lc4_regfile #(parameter n = 16)
   (input  wire         clk,
    input  wire         gwe,
    input  wire         rst,
    input  wire [  2:0] i_rs,      // rs选择器
    output wire [n-1:0] o_rs_data, // rs内容
    input  wire [  2:0] i_rt,      // rt选择器
    output wire [n-1:0] o_rt_data, // rt内容
    input  wire [  2:0] i_rd,      // rd选择器
    input  wire [n-1:0] i_wdata,   // 要写入的数据
    input  wire         i_rd_we    // 写使能
    );

   // 寄存器实例
   wire [n-1:0] reg_data [7:0];

   // 实例化8个寄存器
   genvar i;
   generate
      for (i = 0; i < 8; i = i + 1) begin: reg_inst
         Nbit_reg #(n, 0) reg_instance (
            .in(i_wdata),
            .out(reg_data[i]),
            .clk(clk),
            .we(i_rd_we && (i_rd == i)),
            .gwe(gwe),
            .rst(rst)
         );
      end
   endgenerate

   // 异步读取操作
   assign o_rs_data = reg_data[i_rs];
   assign o_rt_data = reg_data[i_rt];

endmodule