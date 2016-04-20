library IEEE;
use IEEE.std_logic_1164.all;

entity CycleController is
	port (clock, Whites, Colors, Bright_Colors, WALARM, W1ALARM, RALARM, SALARM, Wash, Rinse, Spin, SuperCycle : in std_logic;
	--clock is the standard timing input from the board
	--Whites is the user input that says if the cycle is for mostly white clothing
	--Colors is the user input for a colors cycle
	--Bright_Colors is the user input for a load of bright colors
	--WALARM is the signal that shows if there is an error in the wash stage
	--W1ALARM is the signal that shows if there is an error in the supercycle stage
	--RALARM is the signal that shows if there is an error in the rinse stage
	--SALARM is the signal that shows if there is an error in the spin stage
	
		HW, WW, CW, SP, CD, WE, SCE, RE, SE: out std_logic);
	--HW is the output that signals that the main compartment is being spun
	--WW is the output that signals that the main compartment is being spun
	--CW is the output that signals that the main compartment is being spun
	--SP is the output that signals that the main compartment is being spun
	--CD is the output for the cycle being complete (Cycle Done)
	--WE is the output for an error in the wash stage (Wash Error)
	--SCE is the output for an error in the supercycle stage (SuperCycle Error)
	--RE is the output for an error in the rinse stage (Rinse Error)
	--SE is the output for an error in the spin stage (Spin Error)
	--SC is the output that is to be displayed to the screen to show to the user what cycle the machine is in
	
end;

	--Clock in the altera board is 50 MHz
	--Converting the clock signal to seconds shows that the clock ticks 2E-8 times per second
	--Keeping the whole cycle to two minutes (without supercycle) means that we must have the clock tick 2E9 times before moving to the next state
	--2000000000 in binary is (1110111001101011001010000000000)
	--1000000000 in binary is (0111011100110101100101000000000) (needed for the partial cycles)

architecture CycleController_arch of CycleController is 
type state_type is (Cycle_Select, Hot_Washa, Hot_Washb, Warm_Washa, Warm_Washb, Cold_Washa, Cold_Washb, Additional_Hot_Washa, Additional_Hot_Washb, 
	Additional_Warm_Washa, Additional_Warm_Washb, Additional_Cold_Washa, 
	Additional_Cold_Washb, Hot_Rinse, Warm_Rinse, Cold_Rinse,
	Spin_Cycle, Start, Additional_Wash_Alarm, Wash_Alarm, Rinse_Alarm, Spin_Alarm );
	--Cycle_Select is the state which allows the user to choose which cycle they want and if they want a SuperCycle or not
	--Hot_Washa is the stage of the wash cycle where hot water is added to the compartment
	--Hot_Washb is the stage of the wash cycle where the compartment is spun in order to remove some of the water before the rinse stage
	--Warm_Washa is the stage of the wash cycle where warm water is added to the compatment
	--Warm_Washb is the stage of the wash cycle where the compartment is spun in order to remove some of the water before the rinse stage
	--Cold_Washa is the stage of the wash cycle where cold water is added to the compartment
	--Cold_Washb is the stage of the wash cycle where the compartment is spun in order to remove some of the water before the rinse stage
	--Additional_Hot_Washa is the stage of the 
	--Additional_Warm_Wash is the state for the supercycle's second wash with warm water
	--Additional_Cold_Wash is the state for the supercycle's second wash with cold water
	--Hot_Rinse is the state for the rinse with hot water
	--Warm_Rinse is the state for the rinse with warm water
	--Cold_Rinse is the state for the rinse with cold water
	--Spin_Cycle is the state for the spin stage
	--Start is the beginning state for the washing machine, used here for after the cycle is complete
	--Additional_Wash_Alarm is the state for if there is an error in the supercycle's second washing stage
	--Wash_Alarm is the state for if there is an error in the primary washing stage 
	--Rinse_Alarm is the state for if there is an error in the rinsing stage
	--Spin_Alarm is the state for if there is an error in the spin stage of the cycle
	
	signal cur_state, next_state : state_type;
	--cur_state is the state that the FSM is currently in
	--next_state is teh state that the FSM is going to move to at the next rising clock signal
	signal counter, counter_next: integer := 0; --Counter variables to help keep track of where in a cycle the machine currently is
begin

process (clock) --internal input that helps move the FSM from one state to another while also helping timing the stages of the cycle

begin 

	if clock'event and clock = '1' then --when the clock is on it's rising edge then the FSM will move to the next state
		cur_state <= next_state;
		counter <= counter_next;
	end if ;
	
end process;

process (clock, Whites, Colors, Bright_Colors, WALARM, W1ALARM, RALARM, SALARM, Wash, Rinse, Spin, SuperCycle , cur_state) --Implementation of the FSM for the cycle control 
--takes the inputs from the system and user in order to move from one state to the next
begin 
	case cur_state is --The next state of the FSM is based off of what the current state is
		
		when Cycle_Select => --When the machine is in the Cycle_Select state
			
			if Whites = '1' then --If the user selects for a "Whites" cycle then they will activate a hot wash
				next_state <= Hot_Washa;
			elsif Colors = '1' then --If the user selects a "Colors" cycle then they will activate a warm wash
				next_state <= Warm_Washa;
			elsif Bright_Colors = '1' then --If the user selects a "Bright Colors" cycle then they will activate a cold wash
				next_state <= Cold_Washa;
			end if;
			counter_next <= 0; 
				
		when Hot_Washa => --When the machine is in the Hot_Washa state
		
			if (counter = 1000000000) then 
				next_state <= Hot_Washb;
				counter_next <= 0;
			elsif (WALARM = '1') then --Error handling
				next_state <= Wash_Alarm;
				counter_next <= counter;
			else
				next_state <= Hot_Washa;
				counter_next <= counter + 1;
			end if;
		
		when Hot_Washb => --When the machine is in the Hot_Washb state	
		
			if ((counter = 1000000000) AND (SuperCycle = '1')) then
				next_state <= Additional_Hot_Washa;
				counter_next <= 0;			
			elsif (counter = 1000000000) then
				next_state <= Hot_Rinse;
				counter_next <= 0;
			elsif (WALARM = '1') then
				next_state <= Wash_Alarm;
				counter_next <= counter;
			else
				next_state <= Hot_Washb;
				counter_next <= counter + 1;
			end if;
			
		when Warm_Washa => --When the machine is in the Warm_Washa state
		
			if (counter = 1000000000) then 
				next_state <= Warm_Washb;
				counter_next <= 0;
			elsif (WALARM = '1') then 
				next_state <= Wash_Alarm;
				counter_next <= counter;
			else
				next_state <= Warm_Washa;
				counter_next <= counter + 1;
			end if;
		
		when Warm_Washb => --When the machine is in the Warm_Washb state
		
			if ((counter = 1000000000) AND (SuperCycle = '1')) then
				next_state <= Additional_Warm_Washa;
				counter_next <= 0;
			elsif (counter = 1000000000) then
				next_state <= Warm_Rinse;
				counter_next <= 0;
			elsif (WALARM = '1') then
				next_state <= Wash_Alarm;
				counter_next <= counter;
			else
				next_state <= Warm_Washb;
				counter_next <= counter + 1;
			end if;
			
		when Cold_Washa => --When the machine is in the Cold_Washa state
		
			if (counter = 1000000000) then 
				next_state <= Cold_Washb;
				counter_next <= 0;
			elsif (WALARM = '1') then 
				next_state <= Wash_Alarm;
				counter_next <= counter;
			else
				next_state <= Cold_Washa;
				counter_next <= counter + 1;
			end if;
		
		when Cold_Washb => --When the machine is in the Cold_Washb state
		
			if ((counter = 1000000000) AND (SuperCycle = '1')) then
				next_state <= Additional_Cold_Washa;
				counter_next <= 0;
			elsif (counter = 1000000000) then
				next_state <= Cold_Rinse;
				counter_next <= 0;
			elsif (WALARM = '1') then
				next_state <= Wash_Alarm;
				counter_next <= counter;
			else
				next_state <= Cold_Washb;
				counter_next <= counter + 1;
			end if;
		
		when Additional_Hot_Washa => --When the machine is the in the Additional_Hot_Washa state
		
			if (counter = 1000000000) then 
				next_state <= Additional_Hot_Washb;
				counter_next <= 0;
			elsif (W1ALARM = '1')	then 
				next_state <= Additional_Wash_Alarm;
				counter_next <= counter;
			else
				next_state <= Additional_Hot_Washa;
				counter_next <= counter + 1;
			end if;
		
		when Additional_Hot_Washb => --When the machine is in the Additional_Hot_Washb state
			
			if (counter = 1000000000) then 
				next_state <= Hot_Rinse;
				counter_next <= 0;
			elsif (W1ALARM = '1') then 
				next_state <= Additional_Wash_Alarm;
				counter_next <= counter;
			else
				next_state <= Additional_Hot_Washb;
				counter_next <= counter + 1;
			end if;
			
		when Additional_Warm_Washa => --When the machine is in the Additional_Warm_Washa state
		
			if (counter = 1000000000) then 
				next_state <= Additional_Warm_Washb;
				counter_next <= 0;
			elsif (W1ALARM = '1') then 
				next_state <= Additional_Wash_Alarm;
				counter_next <= counter;
			else
				next_state <= Additional_Hot_Washa;
				counter_next <= counter + 1;
			end if;
		
		when Additional_Warm_Washb => --When the machine is in the Additional_Warm_Washb state
		
			if (counter = 1000000000) then 
				next_state <= Warm_Rinse;
				counter_next <= 0;
			elsif (W1ALARM = '1') then 
				next_state <= Additional_Wash_Alarm;
				counter_next <= counter;
			else
				next_state <= Additional_Warm_Washb;
				counter_next <= counter + 1;
			end if;
		
		when Additional_Cold_Washa => --When the machine is in the Additional_Cold_Washa state
		
			if (counter = 1000000000) then 
				next_state <= Cold_Rinse;
				counter_next <= 0;
			elsif W1ALARM = '1' then 
				next_state <= Additional_Wash_Alarm;
				counter_next <= counter;
			else
				next_state <= Additional_Hot_Washb;
				counter_next <= counter + 1;
			end if;
		
		when Additional_Cold_Washb => --When the machine is in the Additional_Cold_Washb state
		
			if (counter = 1000000000) then 
				next_state <= Cold_Rinse;
				counter_next <= 0;
			elsif (W1ALARM = '1') then 
				next_state <= Additional_Wash_Alarm;
				counter_next <= counter;
			else
				next_state <= Additional_Warm_Washb;
				counter_next <= counter + 1;
			end if;
		
		when Hot_Rinse => --When the machine is in the Hot_Rinse state
		
			if (counter = 2000000000) then 
				next_state <= Spin_Cycle;
				counter_next <= 0;
			elsif (RALARM = '1') then
				next_state <= Rinse_Alarm;
				counter_next <= counter;
			else 
				next_state <= Hot_Rinse;
				counter_next <= counter + 1;
			end if;
				
		when Warm_Rinse => --When the machine is in the Warm_Rinse state
		
			if (counter = 2000000000) then 
				next_state <= Spin_Cycle;
				counter_next <= counter + 1;
			elsif (RALARM = '1') then	
				next_state <= Rinse_Alarm;
				counter_next <= counter;
			else	
				next_state <= Warm_Rinse;
				counter_next <= counter + 1;
			end if;
				
		when Cold_Rinse => --When the machine is in the Cold_Rinse state
		
			if (counter = 2000000000) then
				next_state <= Spin_Cycle;
				counter_next <= 0;
			elsif (RALARM = '1') then
				next_state <= Rinse_Alarm;
				counter_next <= counter;
			else 
				next_state <= Cold_Rinse;
				counter_next <= counter + 1;
			end if;
		
		when Spin_Cycle => --When the machine is in the Spin_Cycle state
		
			if (counter = 2000000000) then 
				next_state <= Start;
				counter_next <= 0;
			elsif (SALARM = '1') then 
				next_state <= Spin_Alarm;
				counter_next <= counter;
			else
				next_state <= Spin_Cycle;
				counter_next <= counter + 1; 
			end if;				
		
		when others => --For some reason if the machine is in some other state, then this will correct the machine to enter the initial Cycle_Select state
			counter_next <= 0;
			next_state <= Start;
		
	end case;
end process;

--with cur_state select --sets the output of the FSM

	HW <= '1' WHEN (Cur_State = Hot_Washa OR Cur_State = Additional_Hot_Washa OR Cur_State = Hot_Rinse) ELSE '0';		
	WW <= '1' WHEN (Cur_State = Warm_Washa OR Cur_State = Additional_Warm_Washa OR Cur_State = Warm_Rinse) ELSE '0';
	CW <= '1' WHEN (Cur_State = Cold_Washa OR Cur_State = Additional_Cold_Washa OR Cur_State = Cold_Rinse) ELSE	'0';
	SP <= '1' WHEN (Cur_State = Hot_Washb OR Cur_State = Additional_Hot_Washb OR Cur_State = Hot_Rinse OR Cur_State = Warm_Washb OR Cur_State = Additional_Warm_Washb OR Cur_State = Warm_Rinse OR Cur_State = Cold_Washb OR Cur_State = Additional_Cold_Washb OR Cur_State = Cold_Rinse OR Cur_State = Spin_Cycle) ELSE '0';
	CD <= '1' WHEN Cur_State = Start ELSE '0';
	WE <= '1' WHEN Cur_State = Wash_Alarm ELSE '0';
	SCE <= '1' WHEN Cur_State = Additional_Wash_Alarm ELSE'0';
	RE <= '1' WHEN Cur_State = Rinse_Alarm ELSE '0';
	SE <= '1' WHEN Cur_State = Spin_Alarm ELSE '0';
	
end CycleController_arch;