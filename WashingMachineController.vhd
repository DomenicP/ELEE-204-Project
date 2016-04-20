--
-- WashingMachineController.vhd
--
-- Top level component for the washing machine control system.
--
-- ELEE 204 Design Project
--   Kaleb Dekker, JD Elsey, David Fritts, Domenic Rodriguez
--
-- April 12, 2016 
--

-- Import requried libraries
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;

-- WashingMachineController is the top level entity for the washer control system.
entity WashingMachineController is
	port(CLOCK_50 : in  std_logic;
		  KEY      : in  std_logic_vector(3  downto 0);
		  SW       : in  std_logic_vector(17 downto 0);
		  LEDR     : out std_logic_vector(17 downto 0);
		  LEDG	  : out std_logic_vector(7 downto 0);
		  HEX0     : out std_logic_vector(0 to 6));
end;

-- Architecture definition for the washer control system
architecture WashingMachineController_arch of WashingMachineController is
	
	-- 7-segment display decoder component definition
	component SevenSegDecoder
		port(hex     : in std_logic_vector(3 downto 0);
		     display : out std_logic_vector(0 to 6));
	end component;

	signal quarter, j, w, s : std_logic;
		-- quarter represents a quarter input
		-- j represents a coin jam
		-- w is the signal to start a wash cycle
		-- s is the signal to perform a super cycle
		
	signal whites, colors, brights, override, refund : std_logic;
		-- whites is the input to start a hot wash cycle
		-- colors is the input to start a warm wash cycle
		-- brights is the input to start a cold wash cycle
		-- override is the signal to manually stop the wash cycle
		-- refund is the signal to indicate that the user should receive a refund
				
	signal payment : integer := 0;
		-- payment stores the amount of money that has been placed into the machine (in cents)
	
	signal x : std_logic_vector(3 downto 0);
		
begin
	-- Map inputs on the DE2 board to signals
	quarter <= KEY(0);
	j <= SW(0);
	whites <= KEY(1);
	colors <= KEY(2);
	brights <= KEY(3);
	override <= SW(1);

	seven_segment : SevenSegDecoder port map (x, HEX0);
	
	-- Simulate quarter input
	insert_coin: process (quarter)
	begin
		if quarter'event and quarter = '1' then
			payment <= payment + 25;
			x <= conv_std_logic_vector(payment / 25, 4);
		end if;
	end process;
	
end WashingMachineController_arch;

-- 7-segment decoder taken from ELEE 252 Lab 5
LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY SevenSegDecoder IS
	PORT (	hex		: IN	STD_LOGIC_VECTOR(3 DOWNTO 0);
				display	: OUT	STD_LOGIC_VECTOR(0 TO 6));
END SevenSegDecoder;

ARCHITECTURE SevenSegDecoder_arch OF SevenSegDecoder IS
BEGIN
	--
	--       0  
	--      ---  
	--     |   |
	--    5|   |1
	--     | 6 |
	--      ---  
	--     |   |
	--    4|   |2
	--     |   |
	--      ---  
	--       3  
	--
	PROCESS (hex)
	BEGIN
		-- a conditional VHDL statement
		CASE hex IS
			WHEN "0000" => display <= "0000001";
			WHEN "0001" => display <= "1001111";
			WHEN "0010" => display <= "0010010";
			WHEN "0011" => display <= "0000110";
			WHEN "0100" => display <= "1001100";
			WHEN "0101" => display <= "0100100";
			WHEN "0110" => display <= "0100000";		
			WHEN "0111" => display <= "0001111";
			WHEN "1000" => display <= "0000000";
			WHEN "1001" => display <= "0001100";
			WHEN "1010" => display <= "0001000";
			WHEN "1011" => display <= "1100000";
			WHEN "1100" => display <= "0110001";
			WHEN "1101" => display <= "1000010";
			WHEN "1110" => display <= "0110000";
			WHEN OTHERS => display <= "0111000";
		END CASE;
	END PROCESS;
END SevenSegDecoder_arch;
