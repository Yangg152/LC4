/* TODO: name and PennKeys of all group members here
 *
 * lc4_single.v
 * Implements a single-cycle data path
 *
 */

`timescale 1ns / 1ps

// disable implicit wire declaration
`default_nettype none

module lc4_processor
   (input  wire        clk,                // Main clock
    input  wire        rst,                // Global reset
    input  wire        gwe,                // Global we for single-step clock
   
    output wire [15:0] o_cur_pc,           // Address to read from instruction memory
    input  wire [15:0] i_cur_insn,         // Output of instruction memory
    output wire [15:0] o_dmem_addr,        // Address to read/write from/to data memory; SET TO 0x0000 FOR NON LOAD/STORE INSNS
    input  wire [15:0] i_cur_dmem_data,    // Output of data memory
    output wire        o_dmem_we,          // Data memory write enable
    output wire [15:0] o_dmem_towrite,     // Value to write to data memory

    // Testbench signals are used by the testbench to verify the correctness of your datapath.
    // Many of these signals simply export internal processor state for verification (such as the PC).
    // Some signals are duplicate output signals for clarity of purpose.
    //
    // Don't forget to include these in your schematic!

    output wire [1:0]  test_stall,         // Testbench: is this a stall cycle? (don't compare the test values)
    output wire [15:0] test_cur_pc,        // Testbench: program counter
    output wire [15:0] test_cur_insn,      // Testbench: instruction bits
    output wire        test_regfile_we,    // Testbench: register file write enable
    output wire [2:0]  test_regfile_wsel,  // Testbench: which register to write in the register file 
    output wire [15:0] test_regfile_data,  // Testbench: value to write into the register file
    output wire        test_nzp_we,        // Testbench: NZP condition codes write enable
    output wire [2:0]  test_nzp_new_bits,  // Testbench: value to write to NZP bits
    output wire        test_dmem_we,       // Testbench: data memory write enable
    output wire [15:0] test_dmem_addr,     // Testbench: address to read/write memory
    output wire [15:0] test_dmem_data,     // Testbench: value read/writen from/to memory
   
    input  wire [7:0]  switch_data,        // Current settings of the Zedboard switches
    output wire [7:0]  led_data            // Which Zedboard LEDs should be turned on?
    );

   // By default, assign LEDs to display switch inputs to avoid warnings about
   // disconnected ports. Feel free to use this for debugging input/output if
   // you desire.
   assign led_data = switch_data;

   
   /* DO NOT MODIFY THIS CODE */
   // Always execute one instruction each cycle (test_stall will get used in your pipelined processor)
   assign test_stall = 2'b0; 

   // pc wires attached to the PC register's ports
   wire [15:0]   pc;      // Current program counter (read out from pc_reg)
   wire [15:0]   next_pc; // Next program counter (you compute this and feed it into next_pc)

   // Program counter register, starts at 8200h at bootup
   Nbit_reg #(16, 16'h8200) pc_reg (.in(next_pc), .out(pc), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   /* END DO NOT MODIFY THIS CODE */


   /*******************************
    * TODO: INSERT YOUR CODE HERE *
    *******************************/
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

   assign o_cur_pc = pc;
   assign o_dmem_addr = (is_load | is_store) ? o_result : 16'h0000;
   assign o_dmem_we = is_store;
   assign o_dmem_towrite = (is_load) ? i_cur_dmem_data : (is_store) ? o_rt_data : 16'h0000;
   
   assign next_pc = (is_branch & take_branch | is_control_insn) ? o_result : s_next_pc;

   assign i_wdata = (is_load) ? i_cur_dmem_data : (is_store) ? o_rt_data : (is_control_insn) ? s_next_pc : is_branch ? 16'h0000 : o_result;
 
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
      end else if (nzp_we && gwe) begin
         nzp <= new_nzp_bits;
      end
   end

   wire [2:0] branch_condition = i_cur_insn[11:9];

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
               
   wire [15:0] s_next_pc;

   cla16 u_cla16(
      .a   	( pc    ),
      .b   	( 16'h0001  ),
      .cin 	( 1'b0  ),
      .sum 	( s_next_pc )
   );

   // outports wire
   wire [2:0]  	r1sel;
   wire        	r1re;
   wire [2:0]  	r2sel;
   wire        	r2re;
   wire [2:0]  	wsel;
   wire        	regfile_we;
   wire        	nzp_we;
   wire        	select_pc_plus_one;
   wire        	is_load;
   wire        	is_store;
   wire        	is_branch;
   wire        	is_control_insn;

   lc4_decoder u_lc4_decoder(
      .insn               	( i_cur_insn          ),
      .r1sel              	( r1sel               ),
      .r1re               	( r1re                ),
      .r2sel              	( r2sel               ),
      .r2re               	( r2re                ),
      .wsel               	( wsel                ),
      .regfile_we         	( regfile_we          ),
      .nzp_we             	( nzp_we              ),
      .select_pc_plus_one 	( select_pc_plus_one  ),
      .is_load            	( is_load             ),
      .is_store           	( is_store            ),
      .is_branch          	( is_branch           ),
      .is_control_insn    	( is_control_insn     )
   );
   
   // outports wire
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


   // outports wire
   wire [15:0] 	o_result;

   lc4_alu u_lc4_alu(
      .i_insn   	( i_cur_insn    ),
      .i_pc     	( pc      ),
      .i_r1data 	( o_rs_data  ),
      .i_r2data 	( o_rt_data  ),
      .o_result 	( o_result  )
   );


   /* Add $display(...) calls in the always block below to
    * print out debug information at the end of every cycle.
    *
    * You may also use if statements inside the always block
    * to conditionally print out information.
    *
    * You do not need to resynthesize and re-implement if this is all you change;
    * just restart the simulation.
    * 
    * To disable the entire block add the statement
    * `define NDEBUG
    * to the top of your file.  We also define this symbol
    * when we run the grading scripts.
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
      // then right-click, and select Radix->Hexadecial.

      // To see the values of wires within a module, select
      // the module in the hierarchy in the "Scopes" pane.
      // The Objects pane will update to display the wires
      // in that module.

      // $display();
   end
`endif
endmodule
