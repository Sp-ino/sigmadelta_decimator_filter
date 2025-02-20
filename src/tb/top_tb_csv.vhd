library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

--library xil_defaultlib;
library work;

entity tb is
end tb;

architecture behavioral of tb is

    component cic_top_v3 is
        port (
            clk: in std_logic;
            reset: in std_logic;
            clk_enable: in std_logic;
            input: in std_logic_vector(1 downto 0);  -- int2
            clk_decimated: out std_logic;
            output: out std_logic_vector(22 downto 0)  -- sfix30
        );
    end component;

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
    signal ck: std_logic := '0';
    signal rst: std_logic := '0';
    signal ck_en: std_logic := '0';
    signal clk_decimated: std_logic;
    signal ce_out: std_logic;
    signal input: std_logic_vector (7 downto 0) := (others => '0');
    signal input_2bit: std_logic_vector (1 downto 0) := "00";
    -- signal output_v0: std_logic_vector (29 downto 0);
    signal output_ref: std_logic_vector (29 downto 0);
    signal output_dut: std_logic_vector (22 downto 0);

    -- Open file
    -- file input_file : text open read_mode is "/home/valerio/phd/lavori/sigmadelta_decimator_filter/src/tb/mod2_out.txt";
    file input_file : text open read_mode is "../../../../../src/tb/mod2_out_long.txt";
    file output_file : text open write_mode is "../../../../../src/tb/cicv3_filter_out.txt";

    signal input_valid : boolean := false;

begin

    dut: cic_top_v3
        port map (
            clk => ck,
            reset => rst,
            clk_enable => ck_en,
            clk_decimated => clk_decimated,
            input => input_2bit,
            output => output_dut
        );

    ref: cic_top_v0
        port map (
            clk => ck,
            reset => rst,
            clk_enable => ck_en,
            clk_decimated => clk_decimated,
            input => input,
            output => output_ref
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

        -- Read input data from CSV
        while not endfile(input_file) loop
            readline(input_file, input_line);
            -- report "The length of input_line is " & integer'image(input_line'length);
            read(input_line, input_value);
            -- report "input_value is " & integer'image(input_value);
            input <= std_logic_vector(to_signed(input_value, 8));
            input_2bit <= std_logic_vector(to_signed(input_value, 2));

            input_valid <= true;

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

        -- Terminate simulation after reading all inputs
        assert false report "End of testbench" severity failure;
    end process;

end behavioral;
