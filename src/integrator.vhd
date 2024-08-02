library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;



entity integrator is
    port ( 
        clk : in std_logic;
        rst : in std_logic;
        din : in std_logic_vector(22 downto 0);
        dout : out std_logic_vector(22 downto 0)
    );
end integrator;



architecture behavioral of integrator is
    signal sum : signed(23 downto 0);
    signal add1 : signed(22 downto 0);
    signal add2 : signed(22 downto 0);
begin

    add1 <= resize(signed(din), 24);
    add2 <= resize(sum, 24);

    process(clk, rst)
    begin
        if rst = '1' then
            sum <= (others => '0');
        elsif rising_edge(clk) then
            sum <= add1 + add2;
        end if;
    end process;

    dout <= std_logic_vector(sum(22 downto 0));

end Behavioral;
