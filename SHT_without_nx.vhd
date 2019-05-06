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
	Signal pr_state: state;
--General signals:
	Signal loop_rst						: std_logic;
	Signal modul						: std_logic_vector (63 downto 0);
	Signal cout							: std_logic;
	Signal data_temp 					: std_logic_vector(15 downto 0);
	Signal data_RH 						: std_logic_vector(15 downto 0);
	Signal command_in					: std_logic_vector(7 downto 0);
	Signal aux_clk, data_clk, bus_clk	: std_logic:='0';
	Signal count_clk					: std_logic:='0';
	Signal timer						: NATURAL range 0 to 80;
	SHARED VARIABLE i					: NATURAL range 0 to 100;
	--signal check						: std_logic_vector(15 downto 0);
	Signal flag							: std_logic;
	signal idle_event 					: std_logic := '0';
	Signal count1						: NATURAL RANGE 0 TO 25;
	Signal count						: NATURAL RANGE 0 to 8;
	Signal SDA_arch, SCK_arch, ts		: std_logic;
	SHARED VARIABLE j					: NATURAL range 0 to 25;

	Begin
--Зададим на вход команду
	command_in <= M_Temp;
	data(0) <= loop_rst;
--	timer <= 0;
--State and command:M_
	--command_in <= "000" and command;
	--Берем отдельно сделанный счетчик, и сбрасываем все по его переполнению:
	modul <= std_logic_vector(to_unsigned(8000,64));
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
	--VARIABLE count: NATURAL RANGE 0 TO 25;
	BEGIN
		IF (sclk'EVENT AND sclk='1') THEN
			count1 <= count1 + 1;
			IF (count1=4) THEN
				aux_clk <= NOT aux_clk;
				count1 <= 0;
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
	--Variable count: NATURAL RANGE 0 to 3;
	BEGIN	
		IF (aux_clk'EVENT AND aux_clk='1') THEN
			count <= count + 1;
			IF (count=0) THEN
				bus_clk <= '1';
				data_clk <= '0';
			ELSIF (count=1) THEN
				data_clk <= '1';
				bus_clk <= '1';
			ELSIF (count=2) THEN
				bus_clk <= '0';
				data_clk <= '1';
			elsif (count = 3) then
				bus_clk <= '0';
				data_clk <= '1';				
			elsif (count = 4) then
				bus_clk <= '1';
				data_clk <= '1';
			elsif (count = 5) then
				bus_clk <= '1';
				data_clk <= '0';
			elsif (count = 6) then
				bus_clk <= '0';
				data_clk <= '0';
			elsif (count = 7) then
				bus_clk <= '0';
				data_clk <= '0';
				count <= 0;
			END IF;
		END IF;
	END PROCESS;
--Синхронные процессы, которые надо описать отдельно от асинхронных:
	Process (en, pr_state, bus_clk, aux_clk)
	Begin
		if (bus_clk'event and bus_clk = '1') then
			If (pr_state = Idling) then
				if (en = '1') then
					idle_event <= '1';
				else
					idle_event <= '0';
				END IF;
			end if;
		end if;
		If (rising_edge(aux_clk) and pr_state = T_S) then 
			IF (bus_clk = '0' and data_clk = '0') then
				if (j = 2) then
					ts <= '0';
					j := 0;
				else 
					j := j + 1;
					ts <= '1';
				END IF;
			end if;
		END If;
	END PROCESS;
--Нижняя секция FMS:	
	PROCESS (bus_clk, rst, loop_rst)
	BEGIN

		IF (rst='0' or loop_rst = '1') THEN	
			pr_state <= Idling;
			i := 0;
			timer <= 16;
		elsif (bus_clk'EVENT AND bus_clk='1') 
			then 
				If (pr_state /= ACK and pr_state /= ACK2 and pr_state /= ACK3) then
					If (i=timer-2) THEN -- проверить сначала с -2, потом вставить в каждое состояние. В ACK не работает, так как там 1 такт (проблема - смещение на такт)
						i := 0;
						flag <= '1';
					ELSE
						i := i + 1;
					END IF;
				end if;
		-- END IF;
		--If (data_clk'EVENT AND data_clk='1') then
			CASE pr_state is
				WHEN Idling => 
				--	timer <= 3; -- таймер задавать на следующее состояние, а не на это, плюс все ифы срабатывают только после того, как таймер заполниться.
					SCK_arch <= '0';
					SDA_arch <= '1';
					IF (flag = '1') then
						if (idle_event = '1') then
							pr_state <= T_S;
							timer <= 11;
							SCK_arch <= '0';
							SDA_arch <= '1';
						else
							pr_state <= Idling;
							timer <= 16;
						end if;
						flag <= '0';
					end if;
				WHEN T_S =>
					--if (ts = '1') then
						SCK_arch <= bus_clk;
						SDA_arch <= data_clk;
					--end if;
					IF (flag = '1') then
						pr_state <= address;
						flag <= '0';
						timer <= 9;
					END IF;
				WHEN address =>
					SCK_arch <= bus_clk;
					SDA_arch <= command_in(7 - i);
					IF (flag = '1') then
						pr_state <= ACK;
						flag <= '1';
						SDA_arch <= 'Z';
						SCK_arch <= bus_clk;
					END IF; 
				WHEN ACK =>
					IF (flag = '1') then
						pr_state <= measurement;
						flag <= '0';
						timer <= 80;
					END IF; 
				WHEN measurement =>
					SCK_arch <= bus_clk;
					SDA_arch <= '0';
					IF (flag = '1') then
						pr_state <= idle;
						flag <= '0';
						timer <= 4;
					END IF; 
				WHEN idle => 
					SCK_arch <= bus_clk;
					SDA_arch <= '0';
					IF (flag = '1') then
						pr_state <= broadcast1;
						flag <= '0';
						timer <= 4;
					END IF; 
				WHEN broadcast1 =>
					SCK_arch <= bus_clk;
					CASE command_in is
						WHEN M_temp =>
							data_temp(4 - i) <= SDA; --в даташите показаны сразу 4 бита данных, если перед SDA будут нули, не сместятся ли данные?
						WHEN M_RH =>
							data_RH(4 - i) <= SDA;
						WHEN others => null;
						--WHEN Read_SR =>
						--WHEN WRITE_SR =>
					END CASE;
					IF (flag = '1') then
						pr_state <= ACK2;
						flag <= '1';
					END IF; 
				WHEN ACK2 =>
					SCK_arch <= bus_clk;
					SDA_arch <= 'Z'; 
					IF (flag = '1') then
						pr_state <= broadcast2;
						flag <= '0';
						timer <= 8;
					END IF; 
				WHEN broadcast2 =>
					SCK_arch <= bus_clk;
					CASE command_in is
						WHEN M_temp =>
							data_temp(7 - i) <= SDA; 
						WHEN M_RH =>
							data_RH(7 - i) <= SDA;
						WHEN others => null;
					END CASE;
					IF (flag = '1') then
						pr_state <= ACK3;
						flag <= '1';
					END IF; 
				WHEN ACK3 =>
					SDA_arch <= 'Z';
					SCK_arch <= bus_clk;
					IF (flag = '1') then
						pr_state <= Idling;
						flag <= '0';
						timer <= 16;
					END IF; 
			END CASE;
		END IF;
	-- END IF;
	END PROCESS;
	
	Process (bus_clk, rst)
	Begin
		if rising_edge(bus_clk) then
			If (rst = '0') then
				SDA <= '0';
				SCK <= '0';
			else
				SDA <= SDA_arch;
				SCK <= SCK_arch;
			end if;
		END IF;
	END PROCESS;
END architecture;