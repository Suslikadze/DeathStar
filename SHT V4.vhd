Library ieee;
USE ieee.std_logic_1164.all;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
use ieee.numeric_std.all;
-------------------------------------------------

Entity SHT is
Port(
--System signals:
	sclk, rst		: in std_logic;
	en				: in std_logic;
	data			: out std_logic_vector(15 downto 0);
	--command		: in std_logic_vector(7 downto 0);
	
--I2C signals:
	SCK 			: out std_logic;
	SDA				: inout std_logic);
END SHT;
-------------------------------------------------
Architecture SHI_arch of SHT is
--SDA commands:
	CONSTANT M_Temp			: STD_logic_vector(7 downto 0) := "00000011";
	CONSTANT M_RH			: STD_logic_vector(7 downto 0) := "00000101";
	CONSTANT Read_SR		: STD_logic_vector(7 downto 0) := "00000111";
	CONSTANT WRITE_SR 		: STD_logic_vector(7 downto 0) := "00000010";
	CONSTANT SOFT_reset		: STD_logic_vector(7 downto 0) := "00011110";
--component counter:
	COMPONENT count_n_modul is
	generic (n: integer);
	Port(
		clk		: in std_logic;
		reset	: in std_logic;
		en		: in std_logic;
		modul	: in std_logic_vector (n-1 downto 0);
		cout	: out std_logic);
	end component;
--State machine signals:
Type state is (T_S, T_S2, address, measurement, broadcast1, broadcast2, ACK, ACK2, ACK3);
	Signal pr_state, nx_state: state;
--General signals:
	Signal loop_rst						: std_logic;
	Signal modul						: std_logic_vector (63 downto 0);
	Signal cout							: std_logic;
	Signal data_temp 					: std_logic_vector(15 downto 0);
	Signal data_RH 						: std_logic_vector(15 downto 0);
	Signal command_in					: std_logic_vector(7 downto 0);
	Signal aux_clk, bus_clk				: std_logic:='0';
	SHARED VARIABLE i				: NATURAL range 0 to 2;
	Signal j							: NATURAL range 0 to 8200;
	--signal check						: std_logic_vector(15 downto 0);
	Signal flag							: std_logic;
	signal idle_event 					: std_logic := '0';
	Signal count1						: NATURAL RANGE 0 TO 500;
	Signal count						: NATURAL RANGE 0 to 500;
	Signal SDA_arch, SCK_arch			: std_logic;
	
	Begin
--Зададим на вход команду
	command_in <= M_Temp;
	data(0) <= loop_rst;
--	timer <= 0;
--State and command:
	--Берем отдельно сделанный счетчик, и сбрасываем все по его переполнению:
	modul <= std_logic_vector(to_unsigned(18000,64));
	counter	:count_n_modul
	Generic map(64)
	port map(
		clk		=> aux_clk,
		reset	=> '0',
		en		=> '1',
		modul	=> modul,
		cout	=> loop_rst);
	

--На борде 50 МГц, датчику нужно 100 кГц, рабочик клок формируем в 4 раза больше (сделал в 5 раз):
	Process (sclk)
	BEGIN
		IF (sclk'EVENT AND sclk='1') THEN
			count <= count + 1;
			count1 <= count1 + 1;
			IF (count1 = 124) THEN
				aux_clk <= NOT aux_clk;
				count1 <= 0;
			END IF;
			If  (count = 249) then
				bus_clk <= NOT bus_clk;
				count <= 0;
			end if;
		END IF;
	End process;
	Process(aux_clk, loop_rst, rst, en, pr_state)
	Begin		
		If (en = '1') then
			IF (rst='0' or loop_rst = '1') THEN	
				pr_state <= T_S;
				i := 0;
				j <= 0;
			elsIf rising_edge(aux_clk) then
				CASE pr_state is
					WHEN T_S =>
							 j <= j + 1;
							 SCK <= bus_clk;
							 SDA <= '0';
							 if (j = 15) then
								--i := i + 1;
								j <= 0;
								SDA <= '1';
								SCK <= '0';
								pr_state <= T_S2;
							end if;
					WHEN T_S2 =>
						j <= j + 1;
						SCK <= '0';
						SDA <= '1';
						Case j is
							When 1 =>
								SCK <= '1';
								SDA <= '1';
							When 2 =>
								SDA <= '0';
								SCK <= '1';
							When 3 =>
								SCK <= '0';
								SDA <= '0';
							When 4 =>
								SCK <= '1';
								SDA <= '0';
							When 5 =>
								SDA <= '1';
								SCK <= '1';
							When 6 =>
								SCK <= '0';
								SDA <= '1';
							When 7 =>
								SCK <= '0';
								SDA <= '1';
							When others => null;
						End case;
						if j = 8 then
							j <= 0;
							pr_state <= address;
							SDA <= command_in(7);
							SCK <= bus_clk;
						end if;
					When address =>
						SCK <= bus_clk;
							i := i + 1;
							if i = 2 and j /= 7 then
								j <= j + 1;
								i := 0;
								SDA <= command_in(6 - j);
							elsIf j = 7 then
								if i = 2 then
									j <= 0;
									i := 0;
									pr_state <= ACK;
									SDA <= 'Z';
									SCK <= bus_clk;
								--	SDA <= '1';
								end if;
							end if;
					WHEN ACK =>
						j <= j + 1;
						SDA <= 'Z';
						
						if j = 2 then
							pr_state <= measurement;
							j <= 0;
						SDA <= 'Z';
						SCK <= '0';
						end if;
					When measurement =>
						i := i + 1;
						SDA <= 'Z';
						SCK <= '0';
						if i = 2 then
							j <= j + 1;
							i := 0;
						elsif j = 8000*5 then --8000
							j <= 0;
							pr_state <= broadcast1;
							-- SDA <= '0';
							SCK <= bus_clk;
							i := 0;
						end if;
					-- WHEN idle =>
						-- i := i + 1;
						-- If i = 5 then
							-- j <= j + 1;
							-- i := 0;
						-- elsif j = 5 and i = 4 then
							-- pr_state <= broadcast1;
							-- j <= 0;
							-- i := 0;
						-- end if;
					When broadcast1 =>
						i := i + 1;
						SCK <= bus_clk;
						if i = 2 and j /= 8 then
							j <= j + 1;
							i := 0;					
						CASE command_in is
							WHEN M_temp =>
								data_temp(15 - j) <= SDA; 
							WHEN M_RH =>
								data_RH(15 - j) <= SDA;
							WHEN others => null;
						end case;
						end if;
						if j = 8 and i = 2 then
							j <= 0;
							i := 0;
							pr_state <= ACK2;
							SDA <= 'Z';
							SCK <= bus_clk;
						end if;
					WHEN ACK2 =>
						j <= j + 1;
						SDA <= 'Z';
						SCK <= bus_clk;
						if j = 1 then
							pr_state <= broadcast2;
							j <= 0;
							SDA <= '1';
						end if;
					WHEN broadcast2 =>
						SCK <= bus_clk;
						i := i + 1;
						if i = 2 and j /= 8 then
							j <= j + 1;
							i := 0;
						CASE command_in is
							WHEN M_temp =>
								data_temp(7 - j) <= SDA; 
							WHEN M_RH =>
								data_RH(7 - j) <= SDA;
							WHEN others => null;
						end case;
						end if;
						if j = 8 and i = 2 then
							j <= 0;
							i := 0;
							pr_state <= ACK3;
							SDA <= 'Z';
							SCK <= bus_clk;
						end if;
					WHEN ACK3 =>
						j <= j + 1;
						SDA <= 'Z';
						SCK <= bus_clk;
						if j = 1 then
							pr_state <= T_S;
							j <= 0;
							SDA <= '1';
						end if;	
					When others =>
						SDA <='1';
						SCK <='0';
				end case;
			end if;	
		end if;
	end process;
end architecture;