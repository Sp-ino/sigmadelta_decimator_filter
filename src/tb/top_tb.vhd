library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library xil_defaultlib;


entity tb is
end tb;


architecture behavioral of tb is

    component cic_top_v1 is
    port (
        clk: in std_logic;
        reset: in std_logic;
        clk_enable: in std_logic;
        input: in std_logic_vector(7 DOWNTO 0);  -- int8
        ce_out: out std_logic;
        output: out std_logic_vector(29 DOWNTO 0)  -- sfix30
    );
    end component;

    constant one: std_logic_vector (7 downto 0) := "01111111";
    constant zero: std_logic_vector (7 downto 0) := "10000001";
    constant tck: time := 10ns;
    constant osr: integer := 160;
    signal ck: std_logic := '0';
    signal rst: std_logic := '0';
    signal ck_en: std_logic := '0';
    signal ce_out: std_logic;
    signal clk_decimated: std_logic;
    signal input: std_logic_vector (7 downto 0) := zero;
    signal output: std_logic_vector (29 downto 0);

begin

    cic_filter: cic_top_v1
    port map (
        clk => ck,
        reset => rst,
        clk_enable => ck_en,
        ce_out => ce_out,
        input => input,
        output => output
    );

    ck_gen: process
    begin
        ck <= '1';
        wait for tck/2;
        ck <= '0';
        wait for tck/2;
    end process ck_gen;


    test_sig: process
    begin
        wait for tck/2;
        rst <= '1';
        wait for 2*tck;
        rst <= '0';

        wait for 2*tck;
        ck_en <= '1';

        for i in 0 to 20*osr loop
            wait for tck;
            input <= one;
            wait for tck;
            input <= zero;
        end loop;

        for i in 0 to 20*osr loop
            wait for tck;
            input <= one;
            wait for tck;
            input <= one;
            wait for tck;
            input <= one;
            wait for tck;
            input <= zero;
        end loop;

        for i in 0 to 20*osr loop
            wait for tck;
            input <= zero;
            wait for tck;
            input <= zero;
            wait for tck;
            input <= zero;
            wait for tck;
            input <= one;
        end loop;

        assert false report "End of testbench" severity failure;
    
    end process test_sig;

end behavioral;