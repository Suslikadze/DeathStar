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
	--en_start		: in std_logic;
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
Type state is (T_S, address, measurement, idling, idle, broadcast1, broadcast2, ACK, ACK2, ACK3);
	Signal pr_state, nx_state: state;
--General signals:
	Signal loop_rst						: std_logic;
	Signal modul						: std_logic_vector (63 downto 0);
	Signal cout							: std_logic;
	Signal data_temp 					: std_logic_vector(15 downto 0);
	Signal data_RH 						: std_logic_vector(15 downto 0);
	Signal command_in					: std_logic_vector(7 downto 0);
	Signal aux_clk, data_clk, bus_clk	: std_logic;
	Signal timer						: NATURAL range 0 to 16;
	SHARED VARIABLE i					: NATURAL range 0 to 16;
	signal check						: std_logic_vector(15 downto 0);
	signal idle_event 					: std_logic := '0';
	
	
Begin
--Зададим на вход команду
	command_in <= M_Temp;
	data(0) <= loop_rst;
--	timer <= 0;
--State and command:M_
	--command_in <= "000" and command;
	--Берем отдельно сделанный счетчик, и сбрасываем все по его переполнению:
	modul<= std_logic_vector(to_unsigned(500,64));
	counter	:count_n_modul
	Generic map(64)
	port map(
		clk		=> sclk,
		reset	=> '0',
		en		=> '1',
		modul	=> modul,
		cout	=> loop_rst);
	

--Делаем частоту 1 МГц для датчика: -- 512 МГц у нас с ПЛИСа, нужно сделать меньше в два раза
	Process (sclk)
	VARIABLE count: NATURAL RANGE 0 TO 25;
	BEGIN
		IF (sclk'EVENT AND sclk='1') THEN
			count := count + 1;
			IF (count=4) THEN
				aux_clk <= NOT aux_clk;
				count := 0;
			END IF;
		END IF;
		-- If (cout = '1') then
		-- loop_rst <= '1';
	-- else
		-- loop_rst <= '0';
	-- end if;
	END PROCESS;
	
	
		
--СДВИГ ФАЗЫ частоты, описание клоков для SDA и SCK:
	Process(aux_clk)
	Variable count: NATURAL RANGE 0 to 3;
	BEGIN	
		IF (aux_clk'EVENT AND aux_clk='1') THEN
			count:= count + 1;
			IF (count=0) THEN
				bus_clk <= '0';
			ELSIF (count=1) THEN
				data_clk <= '1';
			ELSIF (count=2) THEN
				bus_clk <= '1';
			ELSE
				data_clk <= '0';
			END IF;
		END IF;
	END PROCESS;
--Синхронные процессы, которые надо описать отдельно от асинхронных:
	Process (en, pr_state)
	Begin
		if (data_clk'event and data_clk = '1') then
			If (pr_state = Idling) then
				if (en= '1') then
					idle_event <= '1';
				else
					idle_event <= '0';
				END IF;
			END IF;
		END If;
	END PROCESS;
--Нижняя секция FMS:	
	PROCESS (data_clk, rst, loop_rst)
	BEGIN
	If (data_clk'EVENT AND data_clk='1') then
		IF (rst='0' or loop_rst = '1') THEN
			pr_state <= Idling;
			i := 0;
		end if;
		IF (i=timer-1) THEN
				pr_state <= nx_state;
				i := 0;
		ELSE
				i := i + 1;
		END IF;
	END IF;
	End process;
--Верхняя секция FMS:
	Process(pr_state, bus_clk, data_clk, idle_event, SDA) 
	Begin	
		nx_state <= pr_state;
		CASE pr_state is
			WHEN Idling => 
				timer <= 16;
				SCK <= '0';
				SDA <= '1';
				if (idle_event = '1') then
					nx_state <= T_S;
				else
					nx_state <= Idling;
				end if;
			WHEN T_S =>
				timer <= 2;
				SCK <= bus_clk;
				SDA <= data_clk;
				nx_state <= address;
			WHEN address =>
				timer <= 8;
				SCK <= bus_clk;
				SDA <= command_in(8 - i);
				nx_state <= ACK;
			WHEN ACK =>
				timer <= 1;
				SCK <= bus_clk;
				SDA <= 'Z';
				nx_state <= measurement;
			WHEN measurement =>
				timer <= 12;
				SCK <= bus_clk;
				SDA <= 'Z';
				--if (SDA_event = '1') then 
				nx_state <= idle;
				--END IF;
			WHEN idle => 
				timer <= 4;
				SCK <= bus_clk;
				SDA <= '0';
				nx_state <= broadcast1;
			WHEN broadcast1 =>
				timer <= 4;
				SCK <= bus_clk;
				CASE command_in is
					WHEN M_temp =>
						data_temp(4 - i) <= SDA; --в даташите показаны сразу 4 бита данных, если перед SDA будут нули, не сместятся ли данные?
					WHEN M_RH =>
						data_RH(4 - i) <= SDA;
					WHEN others => null;
					--WHEN Read_SR =>
					--WHEN WRITE_SR =>
				END CASE;
				nx_state <= ACK2;
			WHEN ACK2 =>
				timer <= 1;
				SCK <= bus_clk;
				SDA <= 'Z'; 
				nx_state <= broadcast2;
			WHEN broadcast2 =>
				timer <= 8; 
				SCK <= bus_clk;
				CASE command_in is
					WHEN M_temp =>
						data_temp(8 - i) <= SDA; 
					WHEN M_RH =>
						data_RH(8 - i) <= SDA;
					WHEN others => null;
				END CASE;
				nx_state <= ACK3;
			WHEN ACK3 =>
				timer <= 1;
				SDA <= 'Z';
				SCK <= bus_clk;
				nx_state <= Idling;
--			WHEN checksum =>
				--описание компоненты для checksum:
--				component CRC-8
--						port(Clk		: in std_logic; 
--						reset 		: in std_logic; 
--						size_data 	: in unsigned(15 downto 0);  
--						Data_in 	: in std_logic; 
--						crc_out 	: out unsigned(7 downto 0); 
--						crc_ready 	: out std_logic 
--						);
--				END COMPONENT;
--				timer <= 8;
--				SCK <= not aux_clk;
--				port map (clk => sclk, reset => rst, size_data => timer, data_in => SDA, crc_out => check);
--				nx_state => Idling;
		END CASE;
	END PROCESS;
END architecture;
				
				
			
				
					
				
				
	
	
	
