//`include "./lc4_cla.v"

`timescale 1ns / 1ps
`default_nettype none

module lc4_alu(input wire [15:0] i_insn,
               input wire [15:0] i_pc,
               input wire [15:0] i_r1data,
               input wire [15:0] i_r2data,
               output wire [15:0] o_result);

    /*** YOUR CODE HERE ***/
    wire [15:0] sum;
    wire carry_out;
    reg [15:0] a, b, result;
    reg cin;

    cla16 cla16_instance (
        .a(a),
        .b(b),
        .cin(cin),
        .sum(sum)
    );

    wire [15:0] quotient, remainder;

    lc4_divider lc4_divider_instance (
        .i_dividend(a),
        .i_divisor(b),
        .o_remainder(remainder),
        .o_quotient(quotient)
    );

    always @(*) begin
        // 初始化result以防止未定义行为
        result = 16'h0000;
        a = 16'h0000;
        b = 16'h0000;
        cin = 0;

        case (i_insn[15:12])  // 根据指令的高4位进行选择
            4'b0000: begin  // NOP BRp BRz BRzp BRn BRnp BRnz BRnzp
                case (i_insn[11:9])
                    3'b000: begin // NOP
                        a = i_pc;
                        b = {{7{i_insn[8]}}, i_insn[8:0]};
                        cin = 1;
                        result = sum;
                    end
                    3'b001: begin // BRp
                        a = i_pc;
                        b = {{7{i_insn[8]}}, i_insn[8:0]};
                        cin = 1;
                        result = sum;
                    end
                    3'b010: begin // BRz
                        a = i_pc;
                        b = {{7{i_insn[8]}}, i_insn[8:0]};
                        cin = 1;
                        result = sum;  
                    end
                    3'b011: begin // BRzp
                        a = i_pc;
                        b = {{7{i_insn[8]}}, i_insn[8:0]};
                        cin = 1;
                        result = sum; 
                    end
                    3'b100: begin // BRn
                        a = i_pc;
                        b = {{7{i_insn[8]}}, i_insn[8:0]};
                        cin = 1;
                        result = sum; 
                    end
                    3'b101: begin // BRnp
                        a = i_pc;
                        b = {{7{i_insn[8]}}, i_insn[8:0]};
                        cin = 1;
                        result = sum; 
                    end
                    3'b110: begin // BRnz
                        a = i_pc;
                        b = {{7{i_insn[8]}}, i_insn[8:0]};
                        cin = 1;
                        result = sum;   
                    end
                    3'b111: begin // BRnzp
                        a = i_pc;
                        b = {{7{i_insn[8]}}, i_insn[8:0]};
                        cin = 1;
                        result = sum; 
                    end
                endcase
            end
            4'b0001: begin  // ADD, MUL, SUB, DIV ADDI
                case (i_insn[5:3])
                    3'b000: begin // ADD
                        a = i_r1data;
                        b = i_r2data;
                        cin = 0;
                        result = sum;
                    end
                    3'b001: begin // MUL
                        result = i_r1data * i_r2data;
                    end
                    3'b010: begin // SUB
                        a = i_r1data;
                        b = ~i_r2data;
                        cin = 1;
                        result = sum;
                    end
                    3'b011: begin // DIV
                        a = i_r1data;
                        b = i_r2data;
                        result = quotient;
                    end
                    3'b100, 3'b101, 3'b110, 3'b111: begin // ADDI
                        a = i_r1data;
                        b = {{12{i_insn[4]}}, i_insn[3:0]}; 
                        cin = 0;
                        result = sum;
                    end
                endcase
            end
            4'b0010: begin  // CMP, CMPU, CMPI, CMPIU
                case (i_insn[8:7])
                    2'b00: begin // CMP
                        a = i_r1data;
                        b = i_r2data;
                        
                        // 使用带符号数比较
                        if ($signed(a) > $signed(b)) begin
                            result = 16'h0001; // a 大于 b
                        end else if ($signed(a) < $signed(b)) begin
                            result = 16'hFFFF; // a 小于 b
                        end else begin
                            result = 16'h0000; // a 等于 b
                        end
                    end                
                    2'b01: begin // CMPU
                        result = (i_r1data > i_r2data) ? 16'h0001 : 
                                 (i_r1data < i_r2data) ? 16'hFFFF : 16'h0000;
                    end
                    2'b10: begin // CMPI
                        a = i_r1data;
                        // 符号扩展立即数
                        b = {{10{i_insn[6]}}, i_insn[5:0]};
                        
                        // 使用带符号数比较
                        if ($signed(a) > $signed(b)) begin
                            result = 16'h0001; // a 大于 b
                        end else if ($signed(a) < $signed(b)) begin
                            result = 16'hFFFF; // a 小于 b
                        end else begin
                            result = 16'h0000; // a 等于 b
                        end
                    end
                    2'b11: begin // CMPIU
                        result = (i_r1data < {i_insn[6:0]}) ? 16'hFFFF : 
                                 (i_r1data > {i_insn[6:0]}) ? 16'h0001 : 16'h0000;
                    end
                endcase
            end
            4'b0100: begin  // JSRR JSR
                case (i_insn[11])
                    1'b0: begin // JSRR
                        result = i_r1data;
                    end
                    1'b1: begin // JSR
                        a = i_pc;
                        b = i_insn[10:0];
                        result = a & 16'h8000 | (b << 4);
                    end
                endcase
            end              
            4'b0101: begin  // AND, NOT, OR, XOR ANDI
                case (i_insn[5:3])
                    3'b000: begin // AND
                        result = i_r1data & i_r2data;
                    end
                    3'b001: begin // NOT
                        result = ~i_r1data;
                    end
                    3'b010: begin // OR
                        result = i_r1data | i_r2data;
                    end
                    3'b011: begin // XOR
                        result = i_r1data ^ i_r2data;
                    end
                    3'b100, 3'b101, 3'b110, 3'b111: begin // ANDI
                        a = i_r1data;
                        b = {{12{i_insn[4]}}, i_insn[3:0]}; 
                        result = a & b;
                    end
                endcase
            end
            4'b0110: begin  // LDR
                a = i_r1data;
                b = {{11{i_insn[5]}}, i_insn[4:0]};
                cin = 0;
                result = sum;
            end
            4'b0111: begin  // STR
                a = i_r1data;
                b = {{11{i_insn[5]}}, i_insn[4:0]};
                cin = 0;
                result = sum;
            end
            4'b1000: begin  // RTI
                result = i_r1data;
            end            
            4'b1001: begin  // CONST
                result = {{7{i_insn[8]}}, i_insn[8:0]};
            end
            4'b1010: begin  // SLL, SRA, SRL, MOD
                case (i_insn[5:4])
                    2'b00: begin // SLL
                        result = i_r1data << i_insn[3:0];
                    end
                    2'b01: begin // SRA
                        result = ($signed(i_r1data) >>> (i_insn[3:0]));
                    end
                    2'b10: begin // SRL
                        result = i_r1data >> i_insn[3:0];
                    end
                    2'b11: begin // MOD
                        a = i_r1data;
                        b = i_r2data;
                        result = remainder;
                    end
                endcase
            end
            4'b1100: begin  // JMPR JMP
                case (i_insn[11])
                    1'b0: begin // JMPR
                        result = i_r1data;
                    end
                    1'b1: begin // JMP
                        a = i_pc;
                        b = {{6{i_insn[10]}}, i_insn[9:0]};
                        cin = 1;
                        result = sum;
                    end
                endcase
            end            
            4'b1101: begin  // HICONST
                result = (i_r1data & 16'h00FF) | (i_insn[7:0] << 8);
            end
            4'b1101: begin  // HICONST
                result = (i_r1data & 16'h00FF) | (i_insn[7:0] << 8);
            end
            4'b1111: begin  // TRAP
                result = 16'h8000 | i_insn[7:0];
            end
            default: begin
                result = 16'h0000; // 默认输出0
            end
        endcase
    end

    assign o_result = result;

endmodule
