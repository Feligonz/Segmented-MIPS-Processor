library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;
entity Registers is
    Port ( reg1_rd : in STD_LOGIC_VECTOR (4 downto 0);
           reg2_rd : in STD_LOGIC_VECTOR (4 downto 0);
           reg_wr : in STD_LOGIC_VECTOR (4 downto 0);
           data_wr : in STD_LOGIC_VECTOR (31 downto 0);
           wr : in STD_LOGIC;
           clk : in STD_LOGIC;
           reset : in STD_LOGIC;
           data1_rd : out STD_LOGIC_VECTOR (31 downto 0);
           data2_rd : out STD_LOGIC_VECTOR (31 downto 0));
end Registers;

architecture Behavioral of Registers is
type mem is array(0 to 31) of STD_LOGIC_VECTOR(31 downto 0);
signal regs:mem;
begin
    process (clk, reset)
    begin
        if reset= '1' then
            regs<=(others =>x"00000000");
        elsif falling_edge(clk) then --si el clk tiene un flanco descendente 
            if wr= '1' then
                regs(CONV_INTEGER(reg_wr))<=data_wr;
            end if;
        end if;
    end process;
    data1_rd <= x"00000000" when (reg1_rd="00000")else regs(CONV_INTEGER(reg1_rd));
        
    data2_rd <= x"00000000" when (reg2_rd="00000")else regs(CONV_INTEGER(reg2_rd));
        
end Behavioral;