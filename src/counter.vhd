library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;



entity counter is
    port (
        rst : in std_logic;
        en : in std_logic;
        clk : in std_logic;
        phase_0 : out std_logic
    );
end counter;


architecture behavioral of counter is

    constant osr : integer := 160;
    signal current_count : unsigned(7 downto 0);

begin

    counter : process (clk, rst)
    begin
        if rst = '1' then
            current_count <= to_unsigned(0, 8);
        elsif rising_edge(clk) then
            if en = '1' then
                if current_count >= to_unsigned(osr-1, 8) then
                    current_count <= to_unsigned(0, 8);
                else
                    current_count <= current_count + to_unsigned(1, 8);
                end if;
            end if;
        end if; 
    end process counter;

    phase_0 <= '1' when current_count = to_unsigned(0, 8) and en = '1' else '0';

end behavioral;