import rv32i_types::*; /* Import types defined in rv32i_types.sv */

module control_rom
(
    input rv32i_opcode opcode,
    input logic [2:0] funct3,
    input logic [6:0] funct7,
    output rv32i_control ctrl
);


    /************************* Function Definitions *******************************/
function void set_defaults();
    ctrl.opcode = opcode;
    ctrl.funct3 = funct3;
    ctrl.load_regfile = 1'b0;
    ctrl.alumux1_sel = alumux::rs1_out;
    ctrl.alumux2_sel = alumux::i_imm;
    ctrl.regfilemux_sel = regfilemux::alu_out;
    ctrl.cmpmux_sel = cmpmux::rs2_out;
    ctrl.cmpop = beq; //branch_funct3_t'(funct3);
    ctrl.aluop = alu_ops'(funct3);
    ctrl.icache_read = 1'b1;
    ctrl.dcache_read = 1'b0;
    ctrl.dcache_write = 1'b0;
    ctrl.jal_enable = 1'b0;
    ctrl.jalr_enable = 1'b0;
    ctrl.branch_enable = 1'b0;
    ctrl.m_enable = 1'b0;
    ctrl.forward_cmp = 1'b0;
endfunction

function void loadRegfile(regfilemux::regfilemux_sel_t sel);
    ctrl.load_regfile = 1'b1;
    ctrl.regfilemux_sel = sel;
endfunction

/*function void loadPC(pcmux::pcmux_sel_t sel);
    ctrl.pcmux_sel = sel;
endfunction*/

function void setALU(alumux::alumux1_sel_t sel1, alumux::alumux2_sel_t sel2, logic setop, alu_ops op);
    ctrl.alumux1_sel = sel1;
    ctrl.alumux2_sel = sel2;
    if (setop)  ctrl.aluop = op; // else default value
endfunction

function automatic void setCMP(cmpmux::cmpmux_sel_t sel, branch_funct3_t op);
    ctrl.cmpmux_sel = sel;
    ctrl.cmpop = op;
endfunction


    /************************* Output *******************************/
always_comb
begin
    set_defaults();
    unique case (opcode)
        op_lui:   begin
                  loadRegfile(regfilemux::u_imm);
                  end

        op_auipc: begin
                  setALU(alumux::pc_out, alumux::u_imm, 1'b1, alu_add);
	          loadRegfile(regfilemux::alu_out);
                  end

        op_jal:   begin
                  setALU(alumux::pc_out, alumux::j_imm, 1'b1, alu_add);
                  loadRegfile(regfilemux::pc_plus4);
                  ctrl.jal_enable = 1'b1;
                  end

        op_jalr:  begin
                  setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_add);
                  loadRegfile(regfilemux::pc_plus4);
                  ctrl.jalr_enable = 1'b1;
                  end

        op_br:    begin
                  unique case (funct3)
              	  3'b000: setCMP(cmpmux::rs2_out, beq);//BEQ
                  3'b001: setCMP(cmpmux::rs2_out, bne);//BNE
                  3'b100: setCMP(cmpmux::rs2_out, blt);//BLT
                  3'b101: setCMP(cmpmux::rs2_out, bge);//BGE
                  3'b110: setCMP(cmpmux::rs2_out, bltu);//BLTU
                  3'b111: setCMP(cmpmux::rs2_out, bgeu);//BGEU
                  endcase
                  setALU(alumux::pc_out, alumux::b_imm, 1'b1, alu_add);
                  ctrl.branch_enable = 1'b1;
                  end

        op_load:  begin
                  setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_add);
                  ctrl.dcache_read = 1'b1;
                  unique case (funct3)
                  3'b000 : loadRegfile(regfilemux::lb);  //LB
                  3'b001 : loadRegfile(regfilemux::lh);  //LH
                  3'b010 : loadRegfile(regfilemux::lw);  //LW
                  3'b100 : loadRegfile(regfilemux::lbu); //LBU
                  3'b101 : loadRegfile(regfilemux::lhu); //LHU
                  endcase
	          end

        op_store: begin
                  setALU(alumux::rs1_out, alumux::s_imm, 1'b1, alu_add);
                  ctrl.dcache_write = 1'b1;
	          end


        op_imm:   begin                  
                  unique case (funct3)
                  add:    begin
                          setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_add);//ADDI
                          loadRegfile(regfilemux::alu_out);
                          end

                  slt:    begin
                          setCMP(cmpmux::i_imm, blt);//SLTI
                          loadRegfile(regfilemux::br_en);
                          ctrl.forward_cmp = 1'b1;
                          end

                  sltu:   begin
                          setCMP(cmpmux::i_imm, bltu);//SLTIU
	                  loadRegfile(regfilemux::br_en);
                          ctrl.forward_cmp = 1'b1;
                          end

                  axor:   begin
                          setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_xor);//XORI
                          loadRegfile(regfilemux::alu_out);
	                  end

                  aor:    begin
                          setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_or);//ORI
                          loadRegfile(regfilemux::alu_out);
	                  end

                  aand:   begin
                          setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_and);//ANDI
                          loadRegfile(regfilemux::alu_out);
	                  end

                  sll:    begin
                          setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_sll);//SLLI
                          loadRegfile(regfilemux::alu_out);
	                  end

                  sr:     begin
                          setALU(alumux::rs1_out, alumux::i_imm, 1'b1, (funct7 == '0) ? alu_srl : alu_sra); //SRLI, SRAI
                          loadRegfile(regfilemux::alu_out);
	                  end
                  endcase
                  end

        op_reg:   begin
                  if (funct7 == 7'b0000001) ctrl.m_enable = 1'b1;
                  ctrl.alumux1_sel = alumux::rs1_out;
                  ctrl.alumux2_sel = alumux::rs2_out;
                  //if (funct7 !== 7'b0000001) begin
                  unique case (funct3)
                  add:    begin
                          setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, (funct7 == '0) ? alu_add : alu_sub);//ADD, SUB
                          loadRegfile(regfilemux::alu_out);
                          end

                  sll:    begin
                          setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_sll);//SLL
                          loadRegfile(regfilemux::alu_out);
	                  end

                  slt:    begin
                          setCMP(cmpmux::rs2_out, blt);//SLT
                          loadRegfile(regfilemux::br_en);
                          if (funct7 == 7'b0000001) loadRegfile(regfilemux::alu_out);
                          ctrl.forward_cmp = 1'b1;
                          end

                  sltu:   begin
                          setCMP(cmpmux::rs2_out, bltu);//SLTU
                          loadRegfile(regfilemux::br_en);
                          if (funct7 == 7'b0000001) loadRegfile(regfilemux::alu_out);
                          ctrl.forward_cmp = 1'b1;
                          end

                  axor:   begin
                          setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_xor);//XOR
                          loadRegfile(regfilemux::alu_out);
	                  end

                  sr:     begin
                          setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, (funct7 == '0) ? alu_srl : alu_sra); //SRL, SRA
                          loadRegfile(regfilemux::alu_out);
	                  end

                  aor:    begin
                          setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_or);//OR
                          loadRegfile(regfilemux::alu_out);
	                  end

                  aand:   begin
                          setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_and);//AND
                          loadRegfile(regfilemux::alu_out);
	                  end
                  endcase
                 // end
                end
        default: begin
                 ctrl = 0;
                 end
        endcase
end


endmodule : control_rom
