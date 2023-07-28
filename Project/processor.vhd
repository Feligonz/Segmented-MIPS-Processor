library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
--Cambios desde el lunes, le puse que la operacion de la alu en los LW y SW sea de add, le cambie a los registros de pipeline en vez de falling edge rising edge
entity processor is
port(
	Clk         : in  std_logic;
	Reset       : in  std_logic;
	-- Instruction memory
	I_Addr      : out std_logic_vector(31 downto 0);
	I_RdStb     : out std_logic;
	I_WrStb     : out std_logic;
	I_DataOut   : out std_logic_vector(31 downto 0);
	I_DataIn    : in  std_logic_vector(31 downto 0);
	-- Data memory
	D_Addr      : out std_logic_vector(31 downto 0);
	D_RdStb     : out std_logic;
	D_WrStb     : out std_logic;
	D_DataOut   : out std_logic_vector(31 downto 0);
	D_DataIn    : in  std_logic_vector(31 downto 0)
);
end processor;

architecture processor_arq of processor is 
--Comienzo Señales Etapa IF(1)
signal IF_PC_4, IF_ID_PC_4, IF_ID_inst, IF_MUX_4, IF_PC:std_logic_vector(31 downto 0);
--Fin Etapa IF
--Comienzo Etapa ID(2)
signal ID_EX_PC_4, ID_EX_DATAInm, ID_RegA, ID_RegB, ID_EX_RegA, ID_EX_RegB:std_logic_vector(31 downto 0);
signal ID_EX_RegD_lw, ID_EX_RegD_TR, ID_EX_Ctrl_EX, ID_UCtrl_EX:std_logic_vector(4 downto 0);
signal ID_EX_Ctrl_MEM, ID_UCtrl_MEM:std_logic_vector(2 downto 0);
signal ID_EX_Ctrl_WB, ID_UCtrl_WB:std_logic_vector(1 downto 0);
--Fin Etapa ID
--Comienzo Etapa EX(3)
signal EX_Mux_ALU_Scr, EX_ALU_Result, EX_MEM_ALU_Result,EX_MEM_RegB:std_logic_vector(31 downto 0);
signal EX_Mux_Reg_Dst, EX_MEM_Reg_Dst:std_logic_vector(4 downto 0);
signal EX_ALU_Ctrl, EX_MEM_Ctrl_MEM:std_logic_vector(2 downto 0);
signal EX_MEM_Ctrl_WB:std_logic_vector(1 downto 0);
signal EX_Zero,EX_MEM_ZERO:std_logic;
--Fin Etapa EX
--Comienzo Señales Etapa MEM(4)
signal EX_MEM_ADD_PC, MEM_WB_MemData,MEM_WB_ALU_Result:std_logic_vector(31 downto 0);
signal MEM_WB_Reg_Dst:std_logic_vector(4 downto 0);
signal MEM_WB_Ctrl_WB:std_logic_vector(1 downto 0);
signal MEM_PCScr:std_logic;
--Fin Etapa MEM
--Comienzo Señales Etapa WB(5)
signal WB_MUX:std_logic_vector(31 downto 0);
--Fin Etapa WB
begin 	
--Comienzo Procesos Etapa IF(1)
    I_WrStb<='0';
    I_RdStb<='1';
    I_Addr<=IF_PC;
    IF_PC_4<=IF_PC+4;
    I_DataOut<=(others=>'0');
    PC_act:process (Clk,Reset)
    begin
        if (Reset='1') then
            IF_PC<=(others=>'0');
        elsif (rising_edge(Clk)) then
            IF_PC<=IF_MUX_4;
        end if; 
    end process;
    
    IF_ID_PIPE_act:process (Clk,Reset)
    begin
        if (Reset='1') then
            IF_ID_PC_4<=(others=>'0');
            IF_ID_inst<=(others=>'0');
        elsif (rising_edge(Clk)) then
            IF_ID_PC_4<=IF_PC_4;
            IF_ID_inst<=I_DataIn;
        end if;
    end process;
    
    IF_MUX_4<=EX_MEM_ADD_PC when MEM_PCScr ='1' else (IF_PC_4);
    --MEM_PCScr se instancia en la etapa 4 junto con EX_MEM_MUX_PC
--Fin Etapa IF

--Comienzo Procesos Etapa ID(2)
    ID_Reg_Bank:entity work.registers(Behavioral) port map(
        clk=>Clk,
        reset=>Reset,
        wr=>MEM_WB_Ctrl_WB(0),
        reg1_rd=>IF_ID_inst(25 downto 21),
        reg2_rd=>IF_ID_inst(20 downto 16),
        reg_wr=>MEM_WB_Reg_Dst,
        data_wr=>WB_MUX,
        data1_rd=>ID_RegA,
        data2_rd=>ID_RegB);
        
    ID_EX_PIPE_act:process (Clk,Reset)
        begin
            if (Reset='1') then
                ID_EX_DATAInm<=(others=>'0');
                ID_EX_PC_4<=(others=>'0');
                ID_EX_RegD_lw<=(others=>'0');
                ID_EX_RegD_TR<=(others=>'0');
                ID_EX_RegA<=(others=>'0');
                ID_EX_RegB<=(others=>'0');
                ID_EX_Ctrl_EX<=(others=>'0');
                ID_EX_Ctrl_MEM<=(others=>'0');
                ID_EX_Ctrl_WB<=(others=>'0');
            elsif (rising_edge(Clk)) then
                if (IF_ID_inst(15)='0') then
                    ID_EX_DATAInm(31 downto 16)<=(others=>'0');
                    ID_EX_DATAInm(15 downto 0)<=IF_ID_inst(15 downto 0);
                else
                    ID_EX_DATAInm(31)<='1';
                    ID_EX_DATAInm(30 downto 15)<=(others=>'0');
                    ID_EX_DATAInm(14 downto 0)<=IF_ID_inst(14 downto 0);
                end if;
                ID_EX_PC_4<=IF_ID_PC_4;
                ID_EX_RegD_lw<=IF_ID_inst(20 downto 16);
                ID_EX_RegD_TR<=IF_ID_inst(15 downto 11);
                ID_EX_RegA<=ID_RegA;
                ID_EX_RegB<=ID_RegB;
                ID_EX_Ctrl_EX<=ID_UCtrl_EX;
                ID_EX_Ctrl_MEM<=ID_UCtrl_MEM;
                ID_EX_Ctrl_WB<=ID_UCtrl_WB;
            end if;
        end process;
        
    UCtrl:process (IF_ID_inst)
        begin
            CASE IF_ID_inst(31 downto 26) is
                when "000000" => --Operacion tipo R
                    ID_UCtrl_EX<="10010";
                    ID_UCtrl_MEM<="000";
                    ID_UCtrl_WB<="01";
                when "100011" => --Operacion Lw
                    ID_UCtrl_EX<="01000";
                    ID_UCtrl_MEM<="010";
                    ID_UCtrl_WB<="11";
                when "101011" => --Operacion Sw
                    ID_UCtrl_EX<="01000";
                    ID_UCtrl_MEM<="100";
                    ID_UCtrl_WB<="00";
                when "000100" => --Operacion Beq
                    ID_UCtrl_EX<="00001";
                    ID_UCtrl_MEM<="001";
                    ID_UCtrl_WB<="00";
                when "001111" => --Operacion LUI
                    ID_UCtrl_EX<="01111";
                    ID_UCtrl_MEM<="000";
                    ID_UCtrl_WB<="01";
                when "001000" => --Operacion Addi
                    ID_UCtrl_EX<="01110";
                    ID_UCtrl_MEM<="000";
                    ID_UCtrl_WB<="01";
                when "001100" => --Operacion Andi
                    ID_UCtrl_EX<="01100";
                    ID_UCtrl_MEM<="000";
                    ID_UCtrl_WB<="01";
                when "001101" => --Operacion Ori
                    ID_UCtrl_EX<="01101";
                    ID_UCtrl_MEM<="000";
                    ID_UCtrl_WB<="01";
                when others => 
                    ID_UCtrl_EX<=(others=>'X');
                    ID_UCtrl_MEM<=(others=>'X');
                    ID_UCtrl_WB<=(others=>'X');
            end case;
--ID_EX_Ctrl_EX:(4)RegDst, (3)AluSrc, (2,1,0)AluOP
--ID_EX_Ctrl_MEM:(2)MemWrite, (1)MemRead, (0)Branch            
--ID_EX_Ctrl_WB:(1)MemtoReg, (0)RegWrite            
        end process;
               
--Fin Etapa ID

--Comienzo Procesos Etapa EX(3)
    EX_MEM_PIPE_act:process(Clk,Reset)
    begin
    --7 Señales
        if (Reset='1') then
            EX_MEM_ADD_PC<=(others=>'0');
            EX_MEM_ZERO<='0';
            EX_MEM_ALU_Result<=(others=>'0');
            EX_MEM_Reg_Dst<=(others=>'0');
            EX_MEM_RegB<=(others=>'0');
            EX_MEM_Ctrl_MEM<=(others=>'0');
            EX_MEM_Ctrl_WB<=(others=>'0');
        elsif (rising_edge(Clk)) then
            EX_MEM_ADD_PC<=(ID_EX_DATAInm(29 downto 0)&"00")+ID_EX_PC_4;
            EX_MEM_ZERO<=EX_Zero;
            EX_MEM_ALU_Result<=EX_ALU_Result;
            EX_MEM_Reg_Dst<=EX_Mux_Reg_Dst;
            EX_MEM_RegB<=ID_EX_RegB;
            EX_MEM_Ctrl_MEM<=ID_EX_Ctrl_MEM;
            EX_MEM_Ctrl_WB<=ID_EX_Ctrl_WB;
        end if;
    end process;
    
    EX_Mux_ALU_Scr<=ID_EX_DATAInm when ID_EX_Ctrl_EX(3) ='1' else (ID_EX_RegB);
    EX_Mux_Reg_Dst<=ID_EX_RegD_TR when ID_EX_Ctrl_EX(4) ='1' else (ID_EX_RegD_lw);

    EX_ALU:entity work.ALU(Behavioral) port map(
        a=>ID_EX_RegA,
        b=>EX_Mux_ALU_Scr,
        control=>EX_ALU_Ctrl,
        result=>EX_ALU_Result,
        zero=>EX_Zero);
    
    ALU_U_Ctrl:process (ID_EX_Ctrl_EX,ID_EX_DATAInm)
    begin
        CASE ID_EX_Ctrl_EX(2 downto 0) is
            when "010" =>--Operacion tipo R
                CASE ID_EX_DATAInm(5 downto 0) is
                    when "100000"=>EX_ALU_Ctrl<="010";--ADD
                    when "100010"=>EX_ALU_Ctrl<="110";--SUB
                    when "100100"=>EX_ALU_Ctrl<="000";--AND
                    when "100101"=>EX_ALU_Ctrl<="001";--OR
                    when "101010"=>EX_ALU_Ctrl<="111";--Set on Less Than
                    when others =>EX_ALU_Ctrl<="011";
                end case;     
            when "001" =>EX_ALU_Ctrl<="110";--Operacion Beq
            when "000" =>EX_ALU_Ctrl<="010";--Operacion LW y SW
            when "111" =>EX_ALU_Ctrl<="100";--Operacion LUI
            when "110" =>EX_ALU_Ctrl<="010";--Operacion Addi
            when "100" =>EX_ALU_Ctrl<="000";--Operacion Andi
            when "101" =>EX_ALU_Ctrl<="001";--Operacion Ori
            when others =>EX_ALU_Ctrl<="011";--Operacion desconocida/nula
        end case;        
    end process;
--Fin Etapa EX
--Comienzo Procesos Etapa MEM(4)
    MEM_PCScr<=EX_MEM_ZERO and EX_MEM_Ctrl_MEM(0);
    D_RdStb<=EX_MEM_Ctrl_MEM(1);
    D_WrStb<=EX_MEM_Ctrl_MEM(2);
    D_Addr<=EX_MEM_ALU_Result;
    D_DataOut<=EX_MEM_RegB;
    
    MEM_WB_PIPE_act:process(Clk,Reset)
    begin
    --4 Señales
        if (Reset='1') then
            MEM_WB_MemData<=(others=>'0');
            MEM_WB_ALU_Result<=(others=>'0');
            MEM_WB_Reg_Dst<=(others=>'0');
            MEM_WB_Ctrl_WB<=(others=>'0');
        elsif (rising_edge(Clk)) then
            MEM_WB_MemData<=D_DataIn;
            MEM_WB_ALU_Result<=EX_MEM_ALU_Result;
            MEM_WB_Reg_Dst<=EX_MEM_Reg_Dst;
            MEM_WB_Ctrl_WB<=EX_MEM_Ctrl_WB;
        end if;
    end process;    
--Fin Etapa MEM
--Comienzo Procesos Etapa WB(5)
    WB_MUX<=MEM_WB_ALU_Result when MEM_WB_Ctrl_WB(1) ='0' else (MEM_WB_MemData);
--Fin Etapa WB
end processor_arq;
