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
	Case cur_state is
		when A => 		IF (q => '1' AND j => '0') THEN next_state <= B;
							ELSIF (q => '0' AND j => '0') THEN next_state <= A;
							ELSE next_state <= ERROR 
							END IF;
							
		when B =>		IF (q => '1' AND j => '0') THEN next_state <= C;
							ELSIF (q => '0' AND j => '0') THEN next_state <= B;
							ELSE next_state <= ERROR 
							END IF;
							
		when C =>		IF (q => '1' AND j => '0') THEN next_state <= D;
							ELSIF (q => '0' AND j => '0') THEN next_state <= C;
							ELSE next_state <= ERROR 
							END IF;
							
		when D =>		IF (q => '1' AND j => '0') THEN next_state <= E;
							ELSIF (q => '0' AND j => '0') THEN next_state <= D;
							ELSE next_state <= ERROR 
							END IF;
							
		when E =>		IF (q => '1' AND j => '0') THEN next_state <= F;
							ELSIF (q => '0' AND j => '0') THEN next_state <= E;
							ELSIF (n => '1' AND j => '0')next_state <= NORMAL_CYCLE -- ???
							ELSE next_state <= ERROR 
							END IF;
							
		when F =>		IF (q => '1' AND j => '0') THEN next_state <= R;
							ELSIF (q => '0' AND j => '0') THEN next_state <= F;
							ELSIF (s => '1' AND j => '0')next_state <= SUPER_CYCLE -- ???
							ELSE next_state <= ERROR 
							END IF;
							
		when R => 		IF (r => '1' AND j => '0') THEN next_state <= REFUND; -- ???
							ELSE next_state <= ERROR 
							END IF;
							
		when ERR =>		next_state <= ERROR 
		
		-- Move to the next state on each rising clock edge
process (clk)
begin
	if clk'event and clk = '1' then
		cur_state <= next_state;
	end if;
end process;

end PaymentController_arch;
