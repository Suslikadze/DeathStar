LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY tb IS
END tb;

ARCHITECTURE behavior OF tb IS 

    -- CRC Component Declaration for testing.
    COMPONENT CRC8
    port( Clk: in std_logic; 
        reset : in std_logic;
        size_data : in unsigned(15 downto 0);
        Data_in : in std_logic;
        crc_out : out unsigned(7 downto 0);
        crc_ready : out std_logic
        );
    END COMPONENT;    

   --Inputs
   signal Clk : std_logic := '0';
   signal reset : std_logic := '0';
   signal Data_in : std_logic := '0';
    signal size_data : unsigned(15 downto 0) := (others => '0');
    --Outputs
   signal crc_out : unsigned(7 downto 0);
   signal crc_ready : std_logic;
   -- Clock period definitions
   constant Clk_period : time := 10 ns;

BEGIN

    -- Instantiate the Unit Under Test (UUT)
   uut: CRC8 PORT MAP (
          Clk => Clk,
          reset => reset,
          size_data => size_data,
          Data_in => Data_in,
          crc_out => crc_out,
			 crc_temp => crc_temp,
          crc_ready => crc_ready
        );

   -- Clock process definitions
   Clk_process :process
   begin
        Clk <= '0';
        wait for Clk_period/2;
        Clk <= '1';
        wait for Clk_period/2;
   end process;

   -- Stimulus process
   stim_proc: process
   begin        
      reset <= '1'; 
        wait for 100 ns;
        --Data stream(in hex) : 78
        size_data <= to_unsigned(8,16);  --data stream is 8 bits in size
        wait until falling_edge(Clk);
        reset <= '0';
        Data_in <= '0'; wait for Clk_period;
        Data_in <= '1'; wait for Clk_period;
        Data_in <= '1'; wait for Clk_period;
        Data_in <= '1'; wait for Clk_period;
        Data_in <= '1'; wait for Clk_period;
        Data_in <= '0'; wait for Clk_period;
        wait until crc_ready = '1'; wait for Clk_period;
        reset <= '1';
        
        wait for 100 ns;
        --Data stream(in hex) : B800
        size_data <= to_unsigned(16,16); --data stream is 16 bits in size
        wait until falling_edge(Clk);
        reset <= '0';
        Data_in <= '1'; wait for Clk_period;
        Data_in <= '0'; wait for Clk_period;
        Data_in <= '1'; wait for Clk_period;
        Data_in <= '1'; wait for Clk_period;
        Data_in <= '1'; wait for Clk_period;
        Data_in <= '0'; wait for Clk_period;
        wait until crc_ready = '1'; wait for Clk_period;
        reset <= '1';
      wait;
   end process;

END;
