`timescale 1ns / 1ps

// disable implicit wire declaration
`default_nettype none

module lc4_processor
   (input  wire        clk,                // main clock
    input wire         rst, // global reset
    input wire         gwe, // global we for single-step clock
                                    
    output wire [15:0] o_cur_pc, // Address to read from instruction memory
    input wire [15:0]  i_cur_insn, // Output of instruction memory
    output wire [15:0] o_dmem_addr, // Address to read/write from/to data memory
    input wire [15:0]  i_cur_dmem_data, // Output of data memory
    output wire        o_dmem_we, // Data memory write enable
    output wire [15:0] o_dmem_towrite, // Value to write to data memory
   
    output wire [1:0]  test_stall, // Testbench: is this is stall cycle? (don't compare the test values)
    output wire [15:0] test_cur_pc, // Testbench: program counter
    output wire [15:0] test_cur_insn, // Testbench: instruction bits
    output wire        test_regfile_we, // Testbench: register file write enable
    output wire [2:0]  test_regfile_wsel, // Testbench: which register to write in the register file 
    output wire [15:0] test_regfile_data, // Testbench: value to write into the register file
    output wire        test_nzp_we, // Testbench: NZP condition codes write enable
    output wire [2:0]  test_nzp_new_bits, // Testbench: value to write to NZP bits
    output wire        test_dmem_we, // Testbench: data memory write enable
    output wire [15:0] test_dmem_addr, // Testbench: address to read/write memory
    output wire [15:0] test_dmem_data, // Testbench: value read/writen from/to memory

    input wire [7:0]   switch_data, // Current settings of the Zedboard switches
    output wire [7:0]  led_data // Which Zedboard LEDs should be turned on?
    );
   
   /*** YOUR CODE HERE ***/
   assign test_stall = ; 
   // pc wires attached to the PC register's ports
   wire [15:0]   pc;      // Current program counter (read out from pc_reg)
   wire [15:0]   next_pc; // Next program counter (you compute this and feed it into next_pc)

   // 定义流水线寄存器信号
   wire [15:0] i_if_id_insn, o_if_id_insn;
   wire [15:0] i_if_id_pc, o_if_id_pc;
   wire [15:0] i_id_ex_insn, o_id_ex_insn;
   wire [15:0] i_id_ex_pc, o_id_ex_pc;
   wire [15:0] i_id_ex_alu_src1, o_id_ex_alu_src1;
   wire [15:0] i_id_ex_alu_src2, o_id_ex_alu_src2;
   wire [15:0] i_ex_mem_insn, o_ex_mem_insn;
   wire [15:0] i_ex_mem_alu_result, o_ex_mem_alu_result;
   wire [15:0] i_ex_mem_dmem_towrite, o_ex_mem_dmem_towrite;
   wire [15:0] i_mem_wb_insn, o_mem_wb_insn;
   wire [15:0] i_mem_wb_alu_result, o_mem_wb_alu_result;
   wire [15:0] i_mem_wb_dmem_data, o_mem_wb_dmem_data;

   wire if_id_we, id_ex_we, ex_mem_we, mem_wb_we;

   // 解码信号的流水线寄存器
   wire [8:0] i_id_ex_sel, o_id_ex_sel;
   wire [8:0] i_id_ex_decode, o_id_ex_decode;
   wire [8:0] i_ex_mem_sel, o_ex_mem_sel;
   wire [8:0] i_ex_mem_decode, o_ex_mem_decode;
   wire [8:0] i_mem_wb_sel, o_mem_wb_sel;
   wire [8:0] i_mem_wb_decode, o_mem_wb_decode;
   // Program Counter (pc_reg)
   Nbit_reg #(16, 16'h8200) pc_reg (.in(next_pc), .out(pc), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   // IF-ID Pipeline Register
   Nbit_reg #(16, 16'h0000) if_id_insn_reg (.in(i_if_id_insn), .out(o_if_id_insn), .clk(clk), .we(if_id_we), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'h0000) if_id_pc_reg (.in(i_if_id_pc), .out(o_if_id_pc), .clk(clk), .we(if_id_we), .gwe(gwe), .rst(rst));

   // ID-EX Pipeline Register
   Nbit_reg #(16, 16'h0000) id_ex_insn_reg (.in(i_id_ex_insn), .out(o_id_ex_insn), .clk(clk), .we(id_ex_we), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'h0000) id_ex_pc_reg (.in(i_id_ex_pc), .out(o_id_ex_pc), .clk(clk), .we(id_ex_we), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'h0000) id_ex_alu_src1_reg (.in(i_id_ex_alu_src1), .out(o_id_ex_alu_src1), .clk(clk), .we(id_ex_we), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'h0000) id_ex_alu_src2_reg (.in(i_id_ex_alu_src2), .out(o_id_ex_alu_src2), .clk(clk), .we(id_ex_we), .gwe(gwe), .rst(rst));
   
   Nbit_reg #(9, 9'b000000000) id_ex_sel_reg (.in(i_id_ex_sel), .out(o_id_ex_sel), .clk(clk), .we(id_ex_we), .gwe(gwe), .rst(rst));
   Nbit_reg #(9, 9'b000000000) id_ex_decode_reg (.in(i_id_ex_decode), .out(o_id_ex_decode), .clk(clk), .we(id_ex_we), .gwe(gwe), .rst(rst));

   // EX-MEM Pipeline Register
   Nbit_reg #(16, 16'h0000) ex_mem_insn_reg (.in(i_ex_mem_insn), .out(o_ex_mem_insn), .clk(clk), .we(ex_mem_we), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'h0000) ex_mem_alu_result_reg (.in(i_ex_mem_alu_result), .out(o_ex_mem_alu_result), .clk(clk), .we(ex_mem_we), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'h0000) ex_mem_dmem_towrite_reg (.in(i_ex_mem_dmem_towrite), .out(o_ex_mem_dmem_towrite), .clk(clk), .we(ex_mem_we), .gwe(gwe), .rst(rst));
   Nbit_reg #(9, 9'b000000000) ex_mem_sel_reg (.in(i_ex_mem_sel), .out(o_ex_mem_sel), .clk(clk), .we(ex_mem_we), .gwe(gwe), .rst(rst));
   Nbit_reg #(9, 9'b000000000) ex_mem_decode_reg (.in(i_ex_mem_decode), .out(o_ex_mem_decode), .clk(clk), .we(ex_mem_we), .gwe(gwe), .rst(rst));

   // MEM-WB Pipeline Register
   Nbit_reg #(16, 16'h0000) mem_wb_insn_reg (.in(i_mem_wb_insn), .out(o_mem_wb_insn), .clk(clk), .we(mem_wb_we), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'h0000) mem_wb_alu_result_reg (.in(i_mem_wb_alu_result), .out(o_mem_wb_alu_result), .clk(clk), .we(mem_wb_we), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'h0000) mem_wb_dmem_data_reg (.in(i_mem_wb_dmem_data), .out(o_mem_wb_dmem_data), .clk(clk), .we(mem_wb_we), .gwe(gwe), .rst(rst));
   Nbit_reg #(9, 9'b000000000) mem_wb_sel_reg (.in(i_mem_wb_sel), .out(o_mem_wb_sel), .clk(clk), .we(mem_wb_we), .gwe(gwe), .rst(rst));
   Nbit_reg #(9, 9'b000000000) mem_wb_decode_reg (.in(i_mem_wb_decode), .out(o_mem_wb_decode), .clk(clk), .we(mem_wb_we), .gwe(gwe), .rst(rst));


   // Signals for the testbench
   assign test_cur_pc = pc;
   assign test_cur_insn = i_cur_insn;
   assign test_regfile_we = regfile_we; 
   assign test_regfile_wsel = wsel;
   assign test_regfile_data = i_wdata;
   assign test_nzp_we = nzp_we;    
   assign test_nzp_new_bits = new_nzp_bits;
   assign test_dmem_we = o_dmem_we;   
   assign test_dmem_addr = o_dmem_addr;
   assign test_dmem_data = o_dmem_towrite;   

   // NZP寄存器定义
   reg [2:0] nzp; // NZP寄存器

   // 计算新的NZP值
   wire [2:0] new_nzp_bits;
   assign new_nzp_bits = (i_wdata[15] == 1'b1) ? 3'b100 : // N位
                        (i_wdata == 16'b0) ? 3'b010 :   // Z位
                        3'b001;                         // P位

   // 在写入寄存器时更新NZP
   always @(posedge clk) begin
      if (rst) begin
         nzp <= 3'b000;
      end else if (o_mem_wb_decode[3] && gwe) begin
         nzp <= new_nzp_bits;
      end
   end

   wire [2:0] branch_condition = alu_insn[11:9];

   // Determine if the branch should be taken
   wire take_branch = (branch_condition == 3'b000) ? 1'b0 : // No branch
                     (branch_condition == 3'b001) ? nzp[0] : // BRp: branch if positive
                     (branch_condition == 3'b010) ? nzp[1] : // BRz: branch if zero
                     (branch_condition == 3'b011) ? (nzp[0] | nzp[1]) : // BRzp: branch if zero or positive
                     (branch_condition == 3'b100) ? nzp[2] : // BRn: branch if negative
                     (branch_condition == 3'b101) ? (nzp[0] | nzp[2]) : // BRnp: branch if negative or positive
                     (branch_condition == 3'b110) ? (nzp[1] | nzp[2]) : // BRnz: branch if negative or zero
                     (branch_condition == 3'b111) ? (nzp[0] | nzp[1] | nzp[2]) : // BRnzp: branch if negative, zero, or positive
                     1'b0; // Default case

   // Fetch
   wire [15:0] s_next_pc;

   cla16 u_cla16(
      .a    ( pc    ),
      .b    ( 16'h0001  ),
      .cin  ( 1'b0  ),
      .sum  ( s_next_pc )
   );

   assign next_pc = (is_branch & take_branch | is_control_insn) ? alu_result : s_next_pc;
   assign i_if_id_insn = i_cur_insn;
   assign i_if_id_pc = pc;
   assign if_id_we = (i_cur_insn != 16'b0);

   // Decode阶段
   wire [2:0]   r1sel;
   wire         r1re;
   wire [2:0]   r2sel;
   wire         r2re;
   wire [2:0]   wsel;
   wire         regfile_we;
   wire         nzp_we;
   wire         select_pc_plus_one;
   wire         is_load;
   wire         is_store;
   wire         is_branch;
   wire         is_control_insn;

   lc4_decoder u_lc4_decoder(
      .insn                ( o_if_id_insn        ),
      .r1sel               ( r1sel               ),
      .r1re                ( r1re                ),
      .r2sel               ( r2sel               ),
      .r2re                ( r2re                ),
      .wsel                ( wsel                ),
      .regfile_we          ( regfile_we          ),
      .nzp_we              ( nzp_we              ),
      .select_pc_plus_one  ( select_pc_plus_one  ),
      .is_load             ( is_load             ),
      .is_store            ( is_store            ),
      .is_branch           ( is_branch           ),
      .is_control_insn     ( is_control_insn     )
   );

   wire [15:0] 	o_rs_data;
   wire [15:0] 	o_rt_data;
   wire [15:0]    i_wdata;

   lc4_regfile #(
      .n 	( 16  ))
   u_lc4_regfile(
      .clk       	( clk        ),
      .gwe       	( gwe        ),
      .rst       	( rst        ),
      .i_rs      	( r1sel       ),
      .o_rs_data 	( o_rs_data  ),
      .i_rt      	( r2sel       ),
      .o_rt_data 	( o_rt_data  ),
      .i_rd      	( wsel       ),
      .i_wdata   	( i_wdata    ),
      .i_rd_we   	( regfile_we )
   );



   assign i_id_ex_insn = o_if_id_insn;
   assign i_id_ex_pc = pc;
   assign i_id_ex_alu_src1 = o_rs_data;
   assign i_id_ex_alu_src2 = o_rt_data;

   assign id_ex_we = 1'b1;

   assign i_id_ex_sel[2:0] = r1sel;
   assign i_id_ex_sel[5:3] = r2sel;
   assign i_id_ex_sel[8:6] = wsel;
   assign i_id_ex_decode[0] = r1re;
   assign i_id_ex_decode[1] = r2re;
   assign i_id_ex_decode[2] = regfile_we;
   assign i_id_ex_decode[3] = nzp_we;
   assign i_id_ex_decode[4] = select_pc_plus_one;
   assign i_id_ex_decode[5] = is_load;
   assign i_id_ex_decode[6] = is_store;
   assign i_id_ex_decode[7] = is_branch;
   assign i_id_ex_decode[8] = is_control_insn;

   // Execute阶段
   wire [15:0]   alu_insn; 
   wire [15:0]   alu_pc; 
   wire [15:0]   alu_r1data, alu_r2data;
   wire [15:0]   alu_result;

   lc4_alu u_lc4_alu(
      .i_insn   ( alu_insn       ),
      .i_pc     ( alu_pc         ),
      .i_r1data ( alu_r1data     ),
      .i_r2data ( alu_r2data     ),
      .o_result ( alu_result     )
   );

   assign alu_insn   = o_id_ex_insn;
   assign alu_pc     = o_id_ex_pc;
   assign alu_r1data = o_id_ex_alu_src1;
   assign alu_r2data = o_id_ex_alu_src2;

   assign i_ex_mem_insn = o_id_ex_insn;
   assign i_ex_mem_alu_result = alu_result;
   assign i_ex_mem_dmem_towrite = o_id_ex_alu_src2;
   assign ex_mem_we = 1'b1;
   assign i_ex_mem_decode = o_id_ex_decode;



   // Memory阶段
   assign o_dmem_addr = o_ex_mem_alu_result;
   assign o_dmem_we = is_store; // 确保在存储操作时才启用DMEM写使能
   assign o_dmem_towrite = o_ex_mem_dmem_towrite;
   assign i_mem_wb_insn = o_ex_mem_insn;
   assign i_mem_wb_alu_result = o_ex_mem_alu_result;
   assign i_mem_wb_dmem_data = i_cur_dmem_data;
   assign i_mem_wb_decode = o_ex_mem_decode;
   assign i_mem_wb_sel = o_id_ex_sel;
 
   assign mem_wb_we = 1'b1;

   // Writeback阶段
   assign i_wdata = (o_mem_wb_decode[5]) ? i_mem_wb_dmem_data : o_mem_wb_alu_result;
   assign wsel = o_mem_wb_sel[8:6];

   // 将信号通过寄存器传递到下一个流水线阶段
   assign o_cur_pc = pc;

   /* Add $display(...) calls in the always block below to
    * print out debug information at the end of every cycle.
    * 
    * You may also use if statements inside the always block
    * to conditionally print out information.
    *
    * You do not need to resynthesize and re-implement if this is all you change;
    * just restart the simulation.
    */
`ifndef NDEBUG
   always @(posedge gwe) begin
      // $display("%d %h %h %h %h %h", $time, f_pc, d_pc, e_pc, m_pc, test_cur_pc);
      // if (o_dmem_we)
      //   $display("%d STORE %h <= %h", $time, o_dmem_addr, o_dmem_towrite);

      // Start each $display() format string with a %d argument for time
      // it will make the output easier to read.  Use %b, %h, and %d
      // for binary, hex, and decimal output of additional variables.
      // You do not need to add a \n at the end of your format string.
      // $display("%d ...", $time);

      // Try adding a $display() call that prints out the PCs of
      // each pipeline stage in hex.  Then you can easily look up the
      // instructions in the .asm files in test_data.

      // basic if syntax:
      // if (cond) begin
      //    ...;
      //    ...;
      // end

      // Set a breakpoint on the empty $display() below
      // to step through your pipeline cycle-by-cycle.
      // You'll need to rewind the simulation to start
      // stepping from the beginning.

      // You can also simulate for XXX ns, then set the
      // breakpoint to start stepping midway through the
      // testbench.  Use the $time printouts you added above (!)
      // to figure out when your problem instruction first
      // enters the fetch stage.  Rewind your simulation,
      // run it for that many nano-seconds, then set
      // the breakpoint.

      // In the objects view, you can change the values to
      // hexadecimal by selecting all signals (Ctrl-A),
      // then right-click, and select Radix->Hexadecimal.

      // To see the values of wires within a module, select
      // the module in the hierarchy in the "Scopes" pane.
      // The Objects pane will update to display the wires
      // in that module.

      //$display(); 
   end
`endif
endmodule
