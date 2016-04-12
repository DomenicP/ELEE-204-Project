--
-- PaymentController.vhd
--
-- Finite-state machine to control payments for a washing machine.
--
-- ELEE 204 Design Project
--   Kaleb Dekker, JD Elsey, David Fritts, Domenic Rodriguez
--
-- April 12, 2016 
--

-- Import required libraries
library IEEE;
use IEEE.std_logic_1164.all;

entity PaymentController is
	port(clk, q, j, is_running : in std_logic;
			-- clk is the clock signal that drives the FSM
			-- q is an asynchronous signal to indicate that a quarter has been inserted
			-- j is a signal to indicate that there is a physical coin jam
			-- is_running indicates if the washer is currently running
		  w, s : out std_logic);
			-- w is the signal that indicates that the normal cycle is ready to begin
			-- s indicates whether a "super cycle" should run or not
end PaymentController;

architecture PaymentController_arch of PaymentController is
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

end PaymentController_arch;
