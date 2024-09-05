library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;




entity cic_top_v3 is
  port (
        clk: in std_logic;
        reset: in std_logic;
        clk_enable: in std_logic;
        input: in std_logic_vector(1 downto 0);  -- int2
        ce_out: out std_logic;
        output: out std_logic_vector(22 downto 0)  -- sfix23
    );
end cic_top_v3;



architecture structural of cic_top_v3 is

    component integrator is
        port ( 
            clk : in std_logic;
            rst : in std_logic;
            din : in std_logic_vector(22 downto 0);
            dout : out std_logic_vector(22 downto 0)
        );
    end component;

    component differentiator is
        port ( 
            clk : in std_logic;
            rst : in std_logic;
            phase_0 : in std_logic;
            din : in std_logic_vector(22 downto 0);
            dout : out std_logic_vector(22 downto 0)
        );
    end component;
    
    component counter is
        port (
            rst : in std_logic;
            en : in std_logic;
            clk : in std_logic;
            phase_0 : out std_logic
        );
    end component;

    signal phase_0 : std_logic;

    signal input_signed : signed(1 downto 0);
    signal input_resized : signed(22 downto 0);
    signal sect1_int_in : std_logic_vector(22 downto 0);
    
    signal sect1_int_out : std_logic_vector(22 downto 0);
    signal sect2_int_out : std_logic_vector(22 downto 0);
    signal sect3_int_out : std_logic_vector(22 downto 0);
    signal sect3_int_out_decimated : std_logic_vector(22 downto 0);
    signal sect4_comb_out : std_logic_vector(22 downto 0);
    signal sect5_comb_out : std_logic_vector(22 downto 0);
    signal sect6_comb_out : std_logic_vector(22 downto 0);

begin

    count: counter
    port map (
        rst => reset,
        en => clk_enable,
        clk => clk,
        phase_0 => phase_0
    );

    input_signed <= signed(input);
    input_resized <= resize(input_signed, 23);
    sect1_int_in <= std_logic_vector(input_resized);

    --   ------------------ Section # 1 : Integrator ------------------
    sect1 : integrator
    port map (
        clk => clk,
        rst => reset,
        din => sect1_int_in,
        dout => sect1_int_out
    );

    --   ------------------ Section # 2 : Integrator ------------------
    sect2 : integrator
    port map (
        clk => clk,
        rst => reset,
        din => sect1_int_out,
        dout => sect2_int_out
    );

    --   ------------------ Section # 3 : Integrator ------------------
    sect3 : integrator
    port map (
        clk => clk,
        rst => reset,
        din => sect2_int_out,
        dout => sect3_int_out
    );


    --   ------------------ Decimator ---------------------------------
    decimator : process (clk, reset)
    begin
      if reset = '1' then
        sect3_int_out_decimated <= (others => '0');
      elsif rising_edge(clk) then
        if phase_0 = '1' then
          sect3_int_out_decimated <= sect3_int_out;
        end if;
      end if; 
    end process decimator;
  

    --   ------------------ Section # 4 : Comb ------------------
    comb1 : differentiator
    port map ( 
        clk => clk,
        rst => reset,
        phase_0 => phase_0,
        din => sect3_int_out_decimated,
        dout => sect4_comb_out
    );

    --   ------------------ Section # 5 : Comb ------------------
    comb2 : differentiator
    port map ( 
        clk => clk,
        rst => reset,
        phase_0 => phase_0,
        din => sect4_comb_out,
        dout => sect5_comb_out
    );

    --   ------------------ Section # 6 : Comb ------------------
    comb3 : differentiator
    port map (
        clk => clk,
        rst => reset,
        phase_0 => phase_0,
        din => sect5_comb_out,
        dout => sect6_comb_out
    );

    data_hold_reg : process (clk, reset)
    begin
      if reset = '1' then
        output <= (others => '0');
      elsif rising_edge(clk) then
        if phase_0 = '1' then
          output <= sect6_comb_out;
        end if;
      end if; 
    end process;
  
end structural;