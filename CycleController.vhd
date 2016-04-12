--
-- CycleController.vhd
--
-- Finite-state machine to control the wash cycles of a washing machine.
--
-- ELEE 204 Design Project
--   Kaleb Dekker, JD Elsey, David Fritts, Domenic Rodriguez
--
-- April 12, 2016 
--

-- Import required libraries
library IEEE;
use IEEE.std_logic_1164.all;

entity CycleController is
	port(clk, whites, colors, brights, override : in std_logic;
			-- clk is the clock signal to drive the FSM
			-- whites is the asynchronous input to select a hot wash cycle
			-- colors is the asynchronous input to select a warm wash cycle
			-- brights is the asynchronous input to select a cold wash cycle
			-- override is an asynchronous input to indicate that the user would
			--   like to manually stop the wash cycle
		  refund, is_running : out std_logic);
			-- refund indicates that the user should be refunded their payment
			-- is_running indicates if the washing machine is currently running
end;

architecture CycleController_arch of CycleController is
type state_type is (state1, state2);
	-- State descriptions go here

signal cur_state, next_state : state_type;
	-- cur_state indicates the current state
	-- next_state is the state that will be active on the next clock cycle

begin

-- Move to the next state on each rising clock edge
process (clk)
begin
	if clk'event and clk = '1' then
		cur_state <= next_state;
	end if;
end process;

end CycleController_arch;
