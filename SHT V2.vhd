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
Type state is (T_S, address, measurement, idle, broadcast1, broadcast2, ACK, ACK2, ACK3);
	Signal pr_state, nx_state: state;
--General signals:
	Signal loop_rst						: std_logic;
	Signal modul						: std_logic_vector (63 downto 0);
	Signal cout							: std_logic;
	Signal data_temp 					: std_logic_vector(15 downto 0);
	Signal data_RH 						: std_logic_vector(15 downto 0);
	Signal command_in					: std_logic_vector(7 downto 0);
	Signal aux_clk, bus_clk				: std_logic:='0';
	SHARED VARIABLE i, j				: NATURAL range 0 to 120;
	--signal check						: std_logic_vector(15 downto 0);
	Signal flag							: std_logic;
	signal idle_event 					: std_logic := '0';
	Signal count1						: NATURAL RANGE 0 TO 60;
	Signal count						: NATURAL RANGE 0 to 500;
	Signal SDA_arch, SCK_arch			: std_logic;
	
	Begin
--Зададим на вход команду
	command_in <= M_Temp;
	data(0) <= loop_rst;
--	timer <= 0;
--State and command:
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
	

--На борде 50 МГц, датчику нужно 100 кГц, рабочик клок формируем в 4 раза больше (сделал в 5 раз):
	Process (sclk)
	BEGIN
		IF (sclk'EVENT AND sclk='1') THEN
			count <= count + 1;
			count1 <= count1 + 1;
			IF (count1 = 49) THEN
				aux_clk <= NOT aux_clk;
				count1 <= 0;
			END IF;
			If  (count = 499) then
				bus_clk <= NOT bus_clk;
				count <= 0;
			end if;
		END IF;
	End process;
	Process(aux_clk, loop_rst, rst, en)
	Begin		
		If (en = '1') then
			IF (rst='0' or loop_rst = '1') THEN	
				pr_state <= T_S;
			elsif falling_edge(aux_clk) then
				pr_state <= nx_state;
			end if;
			If falling_edge(aux_clk) then
				SCK <= '0';
				SDA <= '1';
				CASE pr_state is
					WHEN T_S =>
						if falling_edge(aux_clk) then
							 j := j + 1;
							 SCK <= bus_clk;
							 SDA <= '1';
							 if (j > 80) then
								--i := i + 1;
							
								Case j is
									When 85 =>
										SCK <= '1';
									When 88 =>
										SDA <= '0';
									When 90 =>
										SCK <= '0';
									When 110 =>
										SCK <= '1';
									When 113 =>
										SDA <= '1';
									When 115 =>
										SCK <= '0';
									When others => null;
								End case;
							elsif  j > 115 then
								i := 0;
								j := 0;
							end if;
						end if;
					When others =>
						SDA <='1';
						SCK <='0';
				end case;
			end if;	
		end if;
	end process;
end architecture;