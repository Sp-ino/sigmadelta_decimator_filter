-- -------------------------------------------------------------
-- 
-- File Name: hdlsrc\cic_top_v2\cic_top_v2.vhd
-- Created: 2024-06-26 11:24:34
-- 
-- Generated by MATLAB 9.14 and HDL Coder 4.1
-- 
-- 
-- -------------------------------------------------------------
-- Rate and Clocking Details
-- -------------------------------------------------------------
-- Model base rate: 0.2
-- Target subsystem base rate: 0.2
-- 
-- 
-- Clock Enable  Sample Time
-- -------------------------------------------------------------
-- ce_out        0.2
-- -------------------------------------------------------------
-- 
-- 
-- Output Signal                 Clock Enable  Sample Time
-- -------------------------------------------------------------
-- output                          ce_out        0.2
-- -------------------------------------------------------------
-- 
-- -------------------------------------------------------------


-- -------------------------------------------------------------
-- 
-- Module: cic_top_v2
-- Source Path: cic_top_v2
-- Hierarchy Level: 0
-- 
-- -------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cic_top_v2 is
  port( clk: in std_logic;
        reset: in std_logic;
        clk_enable: in std_logic;
        input: in std_logic_vector(1 downto 0);  -- int8
        ce_out: out std_logic;
        output: out std_logic_vector(22 downto 0)  -- sfix23
        );
end cic_top_v2;


architecture rtl of cic_top_v2 is

  -- Component Declarations
  component cic_core_v2
    port( clk: in std_logic;
          enb_1_1_1: in std_logic;
          reset: in std_logic;
          CIC_Decimation1_in: in std_logic_vector(1 downto 0);  -- 1 bit
          CIC_Decimation1_out: out std_logic_vector(22 downto 0)  -- sfix23
          );
  end component;

  -- Component Configuration Statements
  for all : cic_core_v2
    use entity work.cic_core_v2(rtl);

  -- Signals
  signal enb_1_1_1: std_logic;
  signal CIC_Decimation1_out1: std_logic_vector(22 downto 0);  -- ufix30

begin
  core_v2 : cic_core_v2
    port map( clk => clk,
              enb_1_1_1 => enb_1_1_1,
              reset => reset,
              CIC_Decimation1_in => input,  -- int8
              CIC_Decimation1_out => CIC_Decimation1_out1  -- sfix23
              );

  enb_1_1_1 <= clk_enable;

  ce_out <= enb_1_1_1;

  output <= CIC_Decimation1_out1;

end rtl;

