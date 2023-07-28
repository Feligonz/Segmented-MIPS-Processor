library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_signed.all;

entity alu is
    Port ( a : in std_logic_vector(31 downto 0);
           b : in std_logic_vector(31 downto 0);
           control : in std_logic_vector(2 downto 0);
           result : out std_logic_vector(31 downto 0);
           zero : out STD_LOGIC
           );
end alu;

architecture Behavioral of alu is
signal r: std_logic_vector(31 downto 0);
signal z: std_logic;
begin
    alu: process(control,a,b)
    begin
        CASE control is
            when "000" => r<= a and b;
            when "001" => r<= a or b;
            when "010" => r <= a + b;
            when "110" => r <= a - b;
            when "111" => 
                if (a<b) then
                    r<=x"00000001";
                else
                    r<=(others=>'0');
                end if;
            when "100" => r <= b(15 downto 0)&x"0000";
            when others => r<=(others=>'0');
        end case;
    end process;
    asig_zero:process (r)
    begin
        CASE r is
            when x"00000000" => z <='1';
            when others => z<='0';
        end case;
    end process;
    result<=r;
    zero<=z;
end Behavioral;
