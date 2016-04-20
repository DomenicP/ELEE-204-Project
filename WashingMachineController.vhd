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

entity WashingMachineController is
	port(CLOCK_50 : in  std_logic;
		  KEY      : in  std_logic_vector(3  downto 0);
		  SW       : in  std_logic_vector(17 downto 0);
		  LEDR     : out std_logic_vector(17 downto 0);
		  LEDG	  : out std_logic_vector(7 downto 0));
end;

architecture WashingMachineController_arch of WashingMachineController is
	signal q, j, w, s : std_logic;
		-- q represents a quarter input
		-- j represents a coin jam
		-- w is the signal to start a wash cycle
		-- s is the signal to perform a super cycle
	signal whites, colors, brights, override, refund : std_logic;
		-- whites is the input to start a hot wash cycle
		-- colors is the input to start a warm wash cycle
		-- brights is the input to start a cold wash cycle
		-- override is the signal to manually stop the wash cycle
		-- refund is the signal to indicate that the user should receive a refund
		
	signal is_running : std_logic;
		-- is_running indicates whether the washing machine is actively running
		
	signal payment : integer := 0;
		-- payment stores the amount of money that has been placed into the machine (in cents)
		
begin
	-- Map inputs on the DE2 board to signals
	q <= KEY(0);
	j <= SW(0);
	whites <= KEY(1);
	colors <= KEY(2);
	brights <= KEY(3);
	override <= SW(1);

	-- Instantiate the cycle controller
	--cycle_controller : entity work.CycleController port map(CLOCK_50, whites, colors, brights, override, refund, is_running);

	-- Handle payments asynchronously
	insert_coin: process (q)
	begin
		if q'event and q = '1' then
			payment <= payment + 25;
		end if;
	end process;
	
	LEDG(0) <= w;
	LEDG(1) <= s;
	
end WashingMachineController_arch;
