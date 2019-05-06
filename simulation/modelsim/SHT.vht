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

-- ***************************************************************************
-- This file contains a Vhdl test bench template that is freely editable to   
-- suit user's needs .Comments are provided in each section to help the user  
-- fill out necessary details.                                                
-- ***************************************************************************
-- Generated on "04/15/2019 16:25:04"
                                                            
-- Vhdl Test Bench template for design  :  SHT
-- 
-- Simulation tool : ModelSim-Altera (VHDL)
-- 

LIBRARY ieee;                                               
USE ieee.std_logic_1164.all;                                

ENTITY SHT_vhd_tst IS
END SHT_vhd_tst;
ARCHITECTURE SHT_arch OF SHT_vhd_tst IS
-- constants  
	constant T : time := 40 ps;     
	constant M : time := 6.98 ns;
-- signals                                                   
SIGNAL data : STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL en : STD_LOGIC;
SIGNAL rst : STD_LOGIC;
SIGNAL SCK : STD_LOGIC;
SIGNAL sclk : STD_LOGIC;
SIGNAL SDA : STD_LOGIC;
SIGNAL aux_clk : STD_LOGIC;
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
	  
	Process 
    begin
        sclk <= '0';
        wait for T/2;
        sclk <= '1';
        wait for T/2;
    end process;
	
	 rst <= '0', '1' after T/2;
	 en <= '1';
	 
	-- SDA <=  after M 
init : PROCESS                                               
-- variable declarations     
	
BEGIN                                                        
        -- code that executes only once                      
WAIT;                                                       
END PROCESS init;                                           
always : PROCESS                                              
-- optional sensitivity list                                  
-- (        )                                                 
-- variable declarations                                      
BEGIN                                                         
        -- code executes for every event on sensitivity list  
WAIT;                                                        
END PROCESS always;                                          
END SHT_arch;
