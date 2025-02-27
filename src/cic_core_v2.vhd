-- ------------------------------------------------------------
-- 
-- File Name: hdlsrc\CIC\cic_core_v2
-- Created: 2024-06-26 11:24:32
-- Generated by MATLAB 9.14 and HDL Coder 4.1
-- 
-- ------------------------------------------------------------
-- 
-- 
-- ------------------------------------------------------------
-- 
-- Module: cic_core_v2
-- Source Path: /cic_core_v2
-- 
-- ------------------------------------------------------------
-- 
-- HDL Implementation    : Fully parallel



library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cic_core_v2 is
   PORT( clk                             :   in    std_logic; 
         enb_1_1_1                       :   in    std_logic; 
         reset                           :   in    std_logic; 
         CIC_Decimation1_in              :   in    std_logic_vector(1 downto 0); -- int2
         CIC_Decimation1_out             :   out   std_logic_vector(22 downto 0)  -- sfix23
         );

end cic_core_v2;


----------------------------------------------------------------
--Module Architecture: cic_core_v2
----------------------------------------------------------------
architecture rtl of cic_core_v2 is
  -- Local Functions
  -- Type Definitions
  -- Constants
  -- Signals
  signal input_typeconvert                : signed(1 downto 0); -- int2
  signal current_count                    : unsigned(7 downto 0); -- ufix8
  signal phase_0                          : std_logic; -- boolean
  --   -- Section 1 Signals 
  signal section_in1                      : signed(1 downto 0); -- int2
  signal section_cast1                    : signed(22 downto 0); -- sfix23
  signal sum1                             : signed(22 downto 0); -- sfix23
  signal section_out1                     : signed(22 downto 0); -- sfix23
  signal add_cast                         : signed(22 downto 0); -- sfix23
  signal add_cast_1                       : signed(22 downto 0); -- sfix23
  signal add_temp                         : signed(23 downto 0); -- sfix31
  --   -- Section 2 Signals 
  signal section_in2                      : signed(22 downto 0); -- sfix23
  signal sum2                             : signed(22 downto 0); -- sfix23
  signal section_out2                     : signed(22 downto 0); -- sfix23
  signal add_cast_2                       : signed(22 downto 0); -- sfix23
  signal add_cast_3                       : signed(22 downto 0); -- sfix23
  signal add_temp_1                       : signed(23 downto 0); -- sfix31
  --   -- Section 3 Signals 
  signal section_in3                      : signed(22 downto 0); -- sfix23
  signal sum3                             : signed(22 downto 0); -- sfix23
  signal section_out3                     : signed(22 downto 0); -- sfix23
  signal add_cast_4                       : signed(22 downto 0); -- sfix23
  signal add_cast_5                       : signed(22 downto 0); -- sfix23
  signal add_temp_2                       : signed(23 downto 0); -- sfix31

  --   -- Decimation
  signal decimated                        : signed(22 downto 0); -- sfix23

  --   -- Section 4 Signals 
  signal section_in4                      : signed(22 downto 0); -- sfix23
  signal diff1                            : signed(22 downto 0); -- sfix23
  signal section_out4                     : signed(22 downto 0); -- sfix23
  signal s4_out_registered                : signed(22 downto 0); -- sfix23
  signal sub_cast                         : signed(22 downto 0); -- sfix23
  signal sub_cast_1                       : signed(22 downto 0); -- sfix23
  signal sub_temp                         : signed(23 downto 0); -- sfix31
  --   -- Section 5 Signals 
  signal section_in5                      : signed(22 downto 0); -- sfix23
  signal diff2                            : signed(22 downto 0); -- sfix23
  signal section_out5                     : signed(22 downto 0); -- sfix23
  signal s5_out_registered                : signed(22 downto 0); -- sfix23
  signal sub_cast_2                       : signed(22 downto 0); -- sfix23
  signal sub_cast_3                       : signed(22 downto 0); -- sfix23
  signal sub_temp_1                       : signed(23 downto 0); -- sfix31
  --   -- Section 6 Signals 
  signal section_in6                      : signed(22 downto 0); -- sfix23
  signal diff3                            : signed(22 downto 0); -- sfix23
  signal section_out6                     : signed(22 downto 0); -- sfix23
  signal sub_cast_4                       : signed(22 downto 0); -- sfix23
  signal sub_cast_5                       : signed(22 downto 0); -- sfix23
  signal sub_temp_2                       : signed(23 downto 0); -- sfix31
  signal regout                           : signed(22 downto 0); -- sfix23
  signal muxout                           : signed(22 downto 0); -- sfix23


begin

  -- Block Statements
  --   ------------------ CE Output Generation ------------------

  counter : process (clk, reset)
  begin
    if reset = '1' then
      current_count <= to_unsigned(0, 8);
    elsif rising_edge(clk) then
      if enb_1_1_1 = '1' then
        if current_count >= to_unsigned(159, 8) then
          current_count <= to_unsigned(0, 8);
        else
          current_count <= current_count + to_unsigned(1, 8);
        end if;
      end if;
    end if; 
  end process counter;

  phase_0 <= '1' when current_count = to_unsigned(0, 8) and enb_1_1_1 = '1' else '0';

  input_typeconvert <= signed(CIC_Decimation1_in);

  --   ------------------ Section # 1 : Integrator ------------------

  section_in1 <= input_typeconvert;

  section_cast1 <= resize(section_in1, 23);

  add_cast <= section_cast1;
  add_cast_1 <= section_out1;
  add_temp <= resize(add_cast, 24) + resize(add_cast_1, 24);
  sum1 <= add_temp(22 downto 0);

  integrator_delay_section1 : process (clk, reset)
  begin
    if reset = '1' then
      section_out1 <= (others => '0');
    elsif rising_edge(clk) then
      if enb_1_1_1 = '1' then
        section_out1 <= sum1;
      end if;
    end if; 
  end process integrator_delay_section1;

  --   ------------------ Section # 2 : Integrator ------------------

  section_in2 <= section_out1;

  add_cast_2 <= section_in2;
  add_cast_3 <= section_out2;
  add_temp_1 <= resize(add_cast_2, 24) + resize(add_cast_3, 24);
  sum2 <= add_temp_1(22 downto 0);

  integrator_delay_section2 : process (clk, reset)
  begin
    if reset = '1' then
      section_out2 <= (others => '0');
    elsif rising_edge(clk) then
      if enb_1_1_1 = '1' then
        section_out2 <= sum2;
      end if;
    end if; 
  end process integrator_delay_section2;

  --   ------------------ Section # 3 : Integrator ------------------

  section_in3 <= section_out2;

  add_cast_4 <= section_in3;
  add_cast_5 <= section_out3;
  add_temp_2 <= resize(add_cast_4, 24) + resize(add_cast_5, 24);
  sum3 <= add_temp_2(22 downto 0);

  integrator_delay_section3 : process (clk, reset)
  begin
    if reset = '1' then
      section_out3 <= (others => '0');
    elsif rising_edge(clk) then
      if enb_1_1_1 = '1' then
        section_out3 <= sum3;
      end if;
    end if; 
  end process integrator_delay_section3;


  --   ------ Decimation between integrator and comb ----------

  decimator : process (clk, reset)
  begin
    if reset = '1' then
      decimated <= (others => '0');
    elsif rising_edge(clk) then
      if phase_0 = '1' then
        decimated <= section_out3;
      end if;
    end if; 
  end process decimator;

  --   ------------------ Section # 4 : Comb ------------------

  section_in4 <= decimated;

  sub_cast <= section_in4;
  sub_cast_1 <= diff1;
  sub_temp <= resize(sub_cast, 24) - resize(sub_cast_1, 24);
  section_out4 <= sub_temp(22 downto 0);

  comb_delay_section4 : process (clk, reset)
  begin
    if reset = '1' then
      diff1 <= (others => '0');
    elsif rising_edge(clk) then
      if phase_0 = '1' then
        diff1 <= section_in4;
      end if;
    end if; 
  end process comb_delay_section4;

  comb_sect4_out_reg : process (clk, reset)
  begin
    if reset = '1' then
      s4_out_registered <= (others => '0');
    elsif rising_edge(clk) then
      s4_out_registered <= section_out4;
    end if;
  end process;

  --   ------------------ Section # 5 : Comb ------------------

  section_in5 <= s4_out_registered;

  sub_cast_2 <= section_in5;
  sub_cast_3 <= diff2;
  sub_temp_1 <= resize(sub_cast_2, 24) - resize(sub_cast_3, 24);
  section_out5 <= sub_temp_1(22 downto 0);

  comb_delay_section5 : process (clk, reset)
  begin
    if reset = '1' then
      diff2 <= (others => '0');
    elsif rising_edge(clk) then
      if phase_0 = '1' then
        diff2 <= section_in5;
      end if;
    end if; 
  end process comb_delay_section5;

  comb_sect5_out_reg : process (clk, reset)
  begin
    if reset = '1' then
      s5_out_registered <= (others => '0');
    elsif rising_edge(clk) then
      s5_out_registered <= section_out5;
    end if;
  end process;

  --   ------------------ Section # 6 : Comb ------------------

  section_in6 <= s5_out_registered;

  sub_cast_4 <= section_in6;
  sub_cast_5 <= diff3;
  sub_temp_2 <= resize(sub_cast_4, 24) - resize(sub_cast_5, 24);
  section_out6 <= sub_temp_2(22 downto 0);

  comb_delay_section6 : process (clk, reset)
  begin
    if reset = '1' then
      diff3 <= (others => '0');
    elsif rising_edge(clk) then
      if phase_0 = '1' then
        diff3 <= section_in6;
      end if;
    end if; 
  end process comb_delay_section6;

  DataHoldRegister_process : process (clk, reset)
  begin
    if reset = '1' then
      regout <= (others => '0');
    elsif rising_edge(clk) then
      if phase_0 = '1' then
        regout <= section_out6;
      end if;
    end if; 
  end process DataHoldRegister_process;

  muxout <= section_out6 when ( phase_0 = '1' ) else
            regout;
  -- Assignment Statements
  CIC_Decimation1_out <= std_logic_vector(muxout);
end rtl;
