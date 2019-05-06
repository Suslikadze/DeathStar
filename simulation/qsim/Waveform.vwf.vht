-- Copyright (C) 2018  Intel Corporation. All rights reserved.
-- Your use of Intel Corporation's design tools, logic functions 
-- and other software and tools, and its AMPP partner logic 
-- functions, and any output files from any of the foregoing 
-- (including device programming or simulation files), and any 
-- associated documentation or information are expressly subject 
-- to the terms and conditions of the Intel Program License 
-- Subscription Agreement, the Intel Quartus Prime License Agreement,
-- the Intel FPGA IP License Agreement, or other applicable license
-- agreement, including, without limitation, that your use is for
-- the sole purpose of programming logic devices manufactured by
-- Intel and sold by Intel or its authorized distributors.  Please
-- refer to the applicable agreement for further details.

-- *****************************************************************************
-- This file contains a Vhdl test bench with test vectors .The test vectors     
-- are exported from a vector file in the Quartus Waveform Editor and apply to  
-- the top level entity of the current Quartus project .The user can use this   
-- testbench to simulate his design using a third-party simulation tool .       
-- *****************************************************************************
-- Generated on "04/15/2019 16:07:57"
                                                             
-- Vhdl Test Bench(with test vectors) for design  :          SHT
-- 
-- Simulation tool : 3rd Party
-- 

LIBRARY ieee;                                               
USE ieee.std_logic_1164.all;                                

ENTITY SHT_vhd_vec_tst IS
END SHT_vhd_vec_tst;
ARCHITECTURE SHT_arch OF SHT_vhd_vec_tst IS
-- constants                                                 
-- signals                                                   
SIGNAL data : STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL en : STD_LOGIC;
SIGNAL rst : STD_LOGIC;
SIGNAL SCK : STD_LOGIC;
SIGNAL sclk : STD_LOGIC;
SIGNAL SDA : STD_LOGIC;
COMPONENT SHT
	PORT (
	data : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
	en : IN STD_LOGIC;
	rst : IN STD_LOGIC;
	SCK : OUT STD_LOGIC;
	sclk : IN STD_LOGIC;
	SDA : INOUT STD_LOGIC
	);
END COMPONENT;
BEGIN
	i1 : SHT
	PORT MAP (
-- list connections between master ports and signals
	data => data,
	en => en,
	rst => rst,
	SCK => SCK,
	sclk => sclk,
	SDA => SDA
	);

-- en
t_prcs_en: PROCESS
BEGIN
	en <= '1';
WAIT;
END PROCESS t_prcs_en;

-- rst
t_prcs_rst: PROCESS
BEGIN
	rst <= '0';
	WAIT FOR 4480000 ps;
	rst <= '1';
WAIT;
END PROCESS t_prcs_rst;

-- SDA
t_prcs_SDA: PROCESS
BEGIN
	SDA <= 'Z';
WAIT;
END PROCESS t_prcs_SDA;

-- sclk
t_prcs_sclk: PROCESS
BEGIN
LOOP
	sclk <= '0';
	WAIT FOR 5000 ps;
	sclk <= '1';
	WAIT FOR 5000 ps;
	IF (NOW >= 20000000 ps) THEN WAIT; END IF;
END LOOP;
END PROCESS t_prcs_sclk;
END SHT_arch;
