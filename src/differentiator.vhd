library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;



entity differentiator is
    port ( 
        clk : in std_logic;
        rst : in std_logic;
        phase_0 : in std_logic;
        din : in std_logic_vector(22 downto 0);
        dout : out std_logic_vector(22 downto 0)
    );
end differentiator;



architecture behavioral of differentiator is
    signal din_delayed : signed(23 downto 0);
    signal diff : signed(23 downto 0);
    signal sub1 : signed(23 downto 0);
    signal sub2 : signed(23 downto 0);
begin

    sub1 <= resize(signed(din), 24);
    sub2 <= signed(din_delayed);
    diff <= sub1 - sub2;

    feedforward_reg: process(clk, rst)
    begin
        if rst = '1' then
            din_delayed <= (others => '0');
        elsif rising_edge(clk) then
            if phase_0 = '1' then
                din_delayed <= resize(signed(din), 24);
            end if;    
        end if;    
    end process;    

    process(clk, rst)
    begin
        if rst = '1' then
            dout <= (others => '0');
        elsif rising_edge(clk) then
            dout <= std_logic_vector(diff(22 downto 0));
        end if;
    end process;


end behavioral;
