library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

library xil_defaultlib;

entity tb is
end tb;

architecture behavioral of tb is

    component cic_top_v0 is
        port (
            clk: in std_logic;
            reset: in std_logic;
            clk_enable: in std_logic;
            input: in std_logic_vector(7 downto 0);  -- int8
            clk_decimated: out std_logic;
            output: out std_logic_vector(29 downto 0)  -- sfix30
        );
    end component;

    constant tck: time := 10 ns;
    constant osr: integer := 160;
    constant input_len: integer := 256; --2^14

    -- Useful when the input is an 8-bit number
    constant one: std_logic_vector (7 downto 0) := "01111111";
    constant zero: std_logic_vector (7 downto 0) := "10000001";

    signal ck: std_logic := '0';
    signal rst: std_logic := '0';
    signal ck_en: std_logic := '0';
    signal clk_decimated: std_logic;
    signal ce_out: std_logic;
    signal input: std_logic_vector (7 downto 0) := (others => '0');
    signal input_2bit: std_logic_vector (1 downto 0) := "00";
    -- signal output_dut: std_logic_vector (22 downto 0);
    signal output_dut: std_logic_vector (29 downto 0);

    file output_file : text open write_mode is "../../../../../src/tb/cic_filter_out_impulseresp.txt";

begin

    dut: cic_top_v0
        port map (
            clk => ck,
            reset => rst,
            clk_enable => ck_en,
            clk_decimated => clk_decimated,
            input => input,
            output => output_dut
        );

    ck_gen: process
    begin
        ck <= '1';
        wait for tck/2;
        ck <= '0';
        wait for tck/2;
    end process ck_gen;

    test_sig: process
        variable input_line : line;
        variable output_line : line;
        variable input_value : integer;
        variable count : integer;
    begin
        wait for tck/2;
        rst <= '1';
        wait for 2*tck;
        rst <= '0';

        wait for 2*tck;
        ck_en <= '1';

        for k in 0 to osr*input_len-1 loop
            if k = 0 then
                input <= one;
            else
                input <= zero;
            end if;

            if clk_decimated = '1' then
                write(output_line, to_integer(signed(output_dut)));
                writeline(output_file, output_line);
            end if;

            wait for tck;
        end loop;

        for count in 0 to 4*osr loop
            if clk_decimated = '1' then
                write(output_line, to_integer(signed(output_dut)));
                writeline(output_file, output_line);
            end if;
            wait for tck;
        end loop;
    
        -- Terminate simulation
        assert false report "End of testbench" severity failure;
    end process;

end behavioral;
