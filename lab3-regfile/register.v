/* register.v
 * A parameterized-width positive-edge-trigged register, with synchronous reset. 
 * The value to take on after a reset is the 2nd parameter.
 * 
 * DO NOT MODIFY
 */

`timescale 1ns / 1ps
`default_nettype none

/* A parameterized-width positive-edge-trigged register, with synchronous reset. 
   The value to take on after a reset is the 2nd parameter. */

   lc4_processor proc_inst (.clk(clk), 
                            .rst(rst),
                            .gwe(gwe),
                            .o_cur_pc(cur_pc), 
                            .i_cur_insn(cur_insn), 
                            .o_dmem_addr(dmem_addr), 
                            .o_dmem_towrite(dmem_tworite), 
                            .i_cur_dmem_data(cur_dmem_data), 
                            .o_dmem_we(dmem_we),
                            .test_stall(test_stall),
                            .test_cur_pc(test_pc),
                            .test_cur_insn(test_insn),
                            .test_regfile_we(test_regfile_we),
                            .test_regfile_wsel(test_regfile_reg),
                            .test_regfile_data(test_regfile_in),
                            .test_nzp_we(test_nzp_we),
                            .test_nzp_new_bits(test_nzp_new_bits),
                            .test_dmem_we(test_dmem_we),
                            .test_dmem_addr(test_dmem_addr),
                            .test_dmem_data(test_dmem_data),
                            .switch_data(8'd0)
                            );