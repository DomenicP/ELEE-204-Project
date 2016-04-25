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

-- WashingMachineController is the top level entity for the washer control system.
entity WashingMachineController is
	port(CLOCK_50 : in  std_logic;
		  KEY      : in  std_logic_vector(3  downto 0);
		  SW       : in  std_logic_vector(17 downto 0);
		  LEDR     : out std_logic_vector(17 downto 0);
		  LEDG	  : out std_logic_vector(3 downto 0);
		  HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7 : out std_logic_vector(0 to 6));
end;

-- Architecture definition for the washer control system
architecture WashingMachineController_arch of WashingMachineController is
	-- Decoder for the 7-segment hex display on the DE2 board
	component SevenSegDecoder
		port(hex     : in std_logic_vector(3 downto 0);
			  display : out std_logic_vector(0 to 6));
	end component;

	type payment_state_type is (zero, twentyfive, fifty, seventyfive, onedollar, dollartwentyfive, coin_jam);
		-- The numbered states indicate how much money has been placed into the machine
		-- coin_jam is a state to handle a mechanical coin jam condition

	type cycle_state_type is (cycle_select, fill, wash, wash_ext, rinse, spin, done, refund, error);
		-- cycle_select is the state where the machine waits for payment and for the user to select a cycle
		-- fill is the state where the machine is filling with water
		-- wash is the state where the machine "agitates" the load to clean the clothing
		-- wash_ext is an extended wash state for SuperCycle
		-- rinse is the state where additional water is run through the machine
		-- spin is the state where the water is spun out of the machine
		-- coin_jam is an error state to handle coin jams
		-- refund is a state to handle user refunds
		-- error is a general error state

	type cycle_type is (hot, warm, cold);
		-- cycle_type represents the different water temperature wash cycles

	signal quarter, whites, colors, brights, override : std_logic;
		-- quarter represents a quarter input
		-- whites represents selecting a hot water cycle
		-- colors represents selecting a warm water cycle
		-- brights represents selecting a cold water cycle
		-- override represents a request from the user to stop the wash cycle

	signal jam_sensor, balance_sensor, water_sensor : std_logic;
		-- jam_sensor is 1 when the system detects a coin jam, and 0 otherwise
		-- balance_sensor is 1 when the sensor detects the washer is out of balance, and 0 otherwise
		-- water_sensor is 1 when the system detects a water level related error, and 0 otherwise

	signal reset : std_logic;
		-- reset is used to manually reset the system after entering an error state_type
		
	signal hot_water, warm_water, cold_water, door_lock, agitate, drain, coin_return : std_logic;
		-- [hot/warm/cold]_water are active high signals to fill the machine with the appropriate temperature water
		-- door_lock is '0' when the door is unlocked, and '1' when the door is locked
		-- agitate is an active high signal that controls the motor during the wash state
		-- drain is an active high signal to spin the water out from the machine
		-- coin_return is an active high signal that indicates funds should be returned to the user

	signal payment_state : payment_state_type := zero;
		-- Represents the current state of the payment FSM

	signal current_cycle_state, next_cycle_state : cycle_state_type;
		-- cur_state represents the current state of the washer cycle control FSM
		-- next_state represents the next state that should be transitioned to

	signal selected_cycle : cycle_type;
		-- selected_cycle stores the information regarding the selected water type

	signal hex0_dat, hex1_dat, hex2_dat, hex3_dat, hex4_dat, hex5_dat, hex6_dat, hex7_dat : std_logic_vector(3 downto 0);
		-- hexN_dat are signals to hold the data for the hex displays on the DE2 board

	signal counter : integer := 0;
	signal counter_bits : std_logic_vector(7 downto 0);
	signal reset_counter: std_logic;

begin

	-- Assign names input signals
	quarter <= KEY(0);
	whites <= KEY(3);
	colors <= KEY(2);
	brights <= KEY(1);

	override <= SW(0); 
	jam_sensor <= SW(9);
	balance_sensor <= SW(10);
	water_sensor <= SW(11);
	reset <= SW(17);

	-- Instantiate the hex-display decoders
	hex0_decoder : SevenSegDecoder port map (hex0_dat, HEX0);
	hex1_decoder : SevenSegDecoder port map (hex1_dat, HEX1);
	hex2_decoder : SevenSegDecoder port map (hex2_dat, HEX2);
	hex3_decoder : SevenSegDecoder port map (hex3_dat, HEX3);
	hex4_decoder : SevenSegDecoder port map (hex4_dat, HEX4);
	hex5_decoder : SevenSegDecoder port map (hex5_dat, HEX5);
	hex6_decoder : SevenSegDecoder port map (hex6_dat, HEX6);
	hex7_decoder : SevenSegDecoder port map (hex7_dat, HEX7);

	-- Handle quarter inputs
	insert_quarter: process (quarter, jam_sensor, current_cycle_state, reset)
	begin
		-- Check for a coin jam
		if reset = '1' then
			payment_state <= zero;
		elsif jam_sensor = '1' then
			if current_cycle_state = cycle_select then
				payment_state <= zero;
			else
				payment_state <= payment_state;
			end if;
		elsif current_cycle_state = done then
			payment_state <= zero;
		else
			-- No coin jam; check for a button press and advance the FSM
			if quarter'event and quarter = '1' and current_cycle_state = cycle_select and jam_sensor = '0' then
				case payment_state is
					when zero =>
						payment_state <= twentyfive;
					
					when twentyfive =>
						payment_state <= fifty;
						
					when fifty =>
						payment_state <= seventyfive;
						
					when seventyfive =>
						payment_state <= onedollar;
						
					when onedollar =>
						payment_state <= dollartwentyfive;

					when dollartwentyfive =>
						payment_state <= dollartwentyfive;
					
					when others =>
						payment_state <= zero;

				end case;
			end if;
		end if;
	end process insert_quarter;

	-- Update the hex display to show the payment state
	update_payment_display: process (payment_state)
	begin
		case payment_state is
			when zero =>
				hex2_dat <= x"0";
				hex1_dat <= x"0";
				hex0_dat <= x"0";

			when twentyfive =>
				hex2_dat <= x"0";
				hex1_dat <= x"2";
				hex0_dat <= x"5";

			when fifty =>
				hex2_dat <= x"0";
				hex1_dat <= x"5";
				hex0_dat <= x"0";

			when seventyfive =>
				hex2_dat <= x"0";
				hex1_dat <= x"7";
				hex0_dat <= x"5";

			when onedollar =>
				hex2_dat <= x"1";
				hex1_dat <= x"0";
				hex0_dat <= x"0";

			when dollartwentyfive =>
				hex2_dat <= x"1";
				hex1_dat <= x"2";
				hex0_dat <= x"5";

			when others =>
				hex2_dat <= x"0";
				hex1_dat <= x"0";
				hex0_dat <= x"0";

		end case;
		hex3_dat <= x"0";
	end process update_payment_display;

	-- Figure out what the next state for the cycle FSM should be
	determine_next_cycle_state: process (whites, brights, colors, override, balance_sensor, water_sensor, reset, current_cycle_state, payment_state, selected_cycle, counter)
	begin
		case current_cycle_state is
			when cycle_select =>
				-- Check if payment is sufficient
				if payment_state = twentyfive then
					coin_return <= '0';
				end if;
				if jam_sensor = '1' then
					next_cycle_state <= error;
				elsif payment_state = onedollar or payment_state = dollartwentyfive then
					-- Check if any of the cycle select buttons are pressed
					if whites = '0' then
						next_cycle_state <= fill;
						selected_cycle <= hot;
					elsif colors = '0' then
						next_cycle_state <= fill;
						selected_cycle <= warm;
					elsif brights = '0' then
						next_cycle_state <= fill;
						selected_cycle <= cold;
					else
						next_cycle_state <= cycle_select;
						selected_cycle <= selected_cycle;
					end if;
				else
					next_cycle_state <= cycle_select;
					selected_cycle <= selected_cycle;
				end if;
				reset_counter <= '1';

			when fill =>
				-- Fill the washer with water for 30 seconds
				if counter > 1500000000 then
					next_cycle_state <= wash;
					reset_counter <= '1';
				else
					if balance_sensor = '1' OR water_sensor = '1' then
						next_cycle_state <= error;
						reset_counter <= '0';
					elsif	override = '1' then
						next_cycle_state <= spin;
						reset_counter <= '1';
					else 
						next_cycle_state <= fill;
						reset_counter <= '0';
					end if;
				end if;
				selected_cycle <= selected_cycle;

			when wash =>
				-- Run the wash stage for 30 seconds
				if counter > 1500000000 then
					-- Check for a super cycle
					if payment_state = dollartwentyfive then
						next_cycle_state <= wash_ext;
					else
						next_cycle_state <= rinse;
					end if;
					reset_counter <= '1';
				else
					if balance_sensor = '1' OR water_sensor = '1' then
						next_cycle_state <= error;
					elsif override = '1' then
						next_cycle_state <= spin;
						reset_counter <= '0';
					else 
						next_cycle_state <= wash;
					end if;
					reset_counter <= '0';
				end if;
				selected_cycle <= selected_cycle;

			when wash_ext =>
				-- Additional wash time for the super cycle
				if counter > 1500000000 then
					next_cycle_state <= rinse;
					reset_counter <= '1';
				else
					if balance_sensor = '1' OR water_sensor = '1' then
						next_cycle_state <= error;
					elsif override = '1' then
						next_cycle_state <= spin;
						reset_counter <= '0';
					else 
						next_cycle_state <= wash_ext;
					end if;
					reset_counter <= '0';
				end if;
				selected_cycle <= selected_cycle;

			when rinse =>
				-- Run the rinse cycle for 30 seconds
				if counter > 1500000000 then
					next_cycle_state <= spin;
					reset_counter <= '1';
				else
					if balance_sensor = '1' OR water_sensor = '1' then
						next_cycle_state <= error;
					elsif override = '1' then
						next_cycle_state <= spin;
						reset_counter <= '0';
					else
						next_cycle_state <= rinse;
					end if;
					reset_counter <= '0';
				end if;
				selected_cycle <= selected_cycle;

			when spin =>
				-- Spin out and drain the water from the machine
				if counter > 1500000000 then
					next_cycle_state <= done;
					reset_counter <= '1';
				else
					if balance_sensor = '1' OR water_sensor = '1' then
						next_cycle_state <= error;
					else 
						next_cycle_state <= spin;
					end if;
					reset_counter <= '0';
				end if;
				selected_cycle <= selected_cycle;

			when done =>
				next_cycle_state <= cycle_select;
				reset_counter <= '1';
				selected_cycle <= selected_cycle;
			
			when error =>
				-- Handle error conditions
				if reset = '1' then
					next_cycle_state <= cycle_select;
					coin_return <= '0';
				else
					next_cycle_state <= error;
					coin_return <= '1';
				end if;
				reset_counter <= '1';
				selected_cycle <= selected_cycle;

			when others =>
				-- Unknown state
				next_cycle_state <= error;
				reset_counter <= '1';
				selected_cycle <= selected_cycle;
				
		end case;
	end process determine_next_cycle_state;
	
	-- Show the value of the timer on the 7-segment displays
	update_cycle_timer: process (counter)
	begin
		-- Brute force check the value of the counter, and set the 7-segment display
		-- to appropriate values to count down from 30. Ugly, but it works.
		if counter > 0 and counter <= 50000000 then
			hex5_dat <= x"3";
			hex4_dat <= x"0";
		elsif counter > 50000000 and counter <= 100000000 then
			hex5_dat <= x"2";
			hex4_dat <= x"9";
		elsif counter > 100000000 and counter <= 150000000 then
			hex5_dat <= x"2";
			hex4_dat <= x"8";
		elsif counter > 150000000 and counter <= 200000000 then
			hex5_dat <= x"2";
			hex4_dat <= x"7";
		elsif counter > 200000000 and counter <= 250000000 then
			hex5_dat <= x"2";
			hex4_dat <= x"6";
		elsif counter > 250000000 and counter <= 300000000 then
			hex5_dat <= x"2";
			hex4_dat <= x"5";
		elsif counter > 300000000 and counter <= 350000000 then
			hex5_dat <= x"2";
			hex4_dat <= x"4";
		elsif counter > 350000000 and counter <= 400000000 then
			hex5_dat <= x"2";
			hex4_dat <= x"3";
		elsif counter > 400000000 and counter <= 450000000 then
			hex5_dat <= x"2";
			hex4_dat <= x"2";
		elsif counter > 450000000 and counter <= 500000000 then
			hex5_dat <= x"2";
			hex4_dat <= x"1";
		elsif counter > 500000000 and counter <= 550000000 then
			hex5_dat <= x"2";
			hex4_dat <= x"0";
		elsif counter > 550000000 and counter <= 600000000 then
			hex5_dat <= x"1";
			hex4_dat <= x"9";
		elsif counter > 600000000 and counter <= 650000000 then
			hex5_dat <= x"1";
			hex4_dat <= x"8";
		elsif counter > 650000000 and counter <= 700000000 then
			hex5_dat <= x"1";
			hex4_dat <= x"7";
		elsif counter > 700000000 and counter <= 750000000 then
			hex5_dat <= x"1";
			hex4_dat <= x"6";
		elsif counter > 750000000 and counter <= 800000000 then
			hex5_dat <= x"1";
			hex4_dat <= x"5";
		elsif counter > 800000000 and counter <= 850000000 then
			hex5_dat <= x"1";
			hex4_dat <= x"4";
		elsif counter > 850000000 and counter <= 900000000 then
			hex5_dat <= x"1";
			hex4_dat <= x"3";
		elsif counter > 900000000 and counter <= 950000000 then
			hex5_dat <= x"1";
			hex4_dat <= x"2";
		elsif counter > 950000000 and counter <= 1000000000 then
			hex5_dat <= x"1";
			hex4_dat <= x"1";
		elsif counter > 1000000000 and counter <= 1050000000 then
			hex5_dat <= x"1";
			hex4_dat <= x"0";
		elsif counter > 1050000000 and counter <= 1100000000 then
			hex5_dat <= x"0";
			hex4_dat <= x"9";
		elsif counter > 1100000000 and counter <= 1150000000 then
			hex5_dat <= x"0";
			hex4_dat <= x"8";
		elsif counter > 1150000000 and counter <= 1200000000 then
			hex5_dat <= x"0";
			hex4_dat <= x"7";
		elsif counter > 1200000000 and counter <= 1250000000 then
			hex5_dat <= x"0";
			hex4_dat <= x"6";
		elsif counter > 1250000000 and counter <= 1300000000 then
			hex5_dat <= x"0";
			hex4_dat <= x"5";
		elsif counter > 1300000000 and counter <= 1350000000 then
			hex5_dat <= x"0";
			hex4_dat <= x"4";
		elsif counter > 1350000000 and counter <= 1400000000 then
			hex5_dat <= x"0";
			hex4_dat <= x"3";
		elsif counter > 1400000000 and counter <= 1450000000 then
			hex5_dat <= x"0";
			hex4_dat <= x"2";
		elsif counter > 1450000000 and counter <= 1500000000 then
			hex5_dat <= x"0";
			hex4_dat <= x"1";
		else
			hex5_dat <= x"0";
			hex4_dat <= x"0";
		end if;
	end process update_cycle_timer;
	
	-- Handles the displaying of error codes on the hex7 and hex6 displays DF
	display_error_code: process (current_cycle_state, balance_sensor, water_sensor)
	begin
		if current_cycle_state = cycle_select then
			hex7_dat <= x"1";
			hex6_dat <= x"0";
		elsif current_cycle_state = fill then
			hex7_dat <= x"2";
			hex6_dat <= x"0";
		elsif current_cycle_state = wash then
			hex7_dat <= x"3";
		elsif current_cycle_state = rinse then
			hex7_dat <= x"4";
		elsif current_cycle_state = spin then
			hex7_dat <= x"5";
		elsif current_cycle_state = wash_ext then
			hex7_dat <= x"E";
		elsif current_cycle_state = error or jam_sensor = '1'then
			hex7_dat <= x"0";
			if water_sensor = '1' then
				hex6_dat <= x"A";
			elsif balance_sensor = '1' then
				hex6_dat <= x"B";
			elsif jam_sensor = '1' and current_cycle_state = cycle_select then
				hex6_dat <= x"C";
			else 
				hex6_dat <= x"0";
			end if;
		end if;
	end process display_error_code;
	
	-- Handle updates that occur on the clock cycle
	update_clock: process (CLOCK_50)
	begin
		if CLOCK_50'event and CLOCK_50 = '1' then
			-- Move the cycle controller to the next state
			current_cycle_state <= next_cycle_state;

			-- Advance the counter
			if reset_counter = '1' then
				counter <= 0;
			else
				counter <= counter + 1;
			end if;
		end if;
	end process update_clock;
	
	-- Determine washer output signals
	hot_water  <= '1' when (current_cycle_state = fill or current_cycle_state = rinse) and selected_cycle = hot else '0';
	warm_water <= '1' when (current_cycle_state = fill or current_cycle_state = rinse) and selected_cycle = warm else '0';
	cold_water <= '1' when (current_cycle_state = fill or current_cycle_state = rinse) and selected_cycle = cold else '0';
	
	door_lock <= '0' when current_cycle_state = cycle_select or
								 current_cycle_state = error or
								 current_cycle_state = done
						  else '1';
						  
	agitate <= '1' when current_cycle_state = wash or
							  current_cycle_state = wash_ext
					   else '0';
						
	drain <= '1' when current_cycle_state = spin else '0';
	
	-- Show payment status
	LEDG(0) <= '1' when payment_state = onedollar or payment_state = dollartwentyfive else '0';
	LEDG(1) <= '1' when payment_state = dollartwentyfive else '0';
	
	-- Show washer controller outputs
	LEDR(0) <= door_lock;
	LEDR(1) <= cold_water;
	LEDR(2) <= warm_water;
	LEDR(3) <= hot_water;
	LEDR(4) <= agitate;
	LEDR(5) <= drain;
	LEDR(6) <= coin_return;
	
	-- Display the cycle controller state
	LEDR(17) <= '1' when current_cycle_state = cycle_select 	else '0';
	LEDR(16) <= '1' when current_cycle_state = fill 			else '0';
	LEDR(15) <= '1' when current_cycle_state = wash 			else '0';
	LEDR(14) <= '1' when current_cycle_state = wash_ext 		else '0';
	LEDR(13) <= '1' when current_cycle_state = rinse 			else '0';
	LEDR(12) <= '1' when current_cycle_state = spin 			else '0';
	LEDR(11) <= '1' when current_cycle_state = error 			else '0';

end WashingMachineController_arch;

 -- 7-segment decoder taken from ELEE 252 Lab 5
 library IEEE;
 use IEEE.std_logic_1164.all;

 entity SevenSegDecoder is
     port (hex        : in  std_logic_vector(3 downto 0);
           display    : out std_logic_vector(0 to 6));
 END SevenSegDecoder;

 architecture SevenSegDecoder_arch of SevenSegDecoder is
 begin
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
     process (hex)
     begin
         -- a conditional VHDL statement
         case hex is
             when "0000" => display <= "0000001";
             when "0001" => display <= "1001111";
             when "0010" => display <= "0010010";
             when "0011" => display <= "0000110";
             when "0100" => display <= "1001100";
             when "0101" => display <= "0100100";
             when "0110" => display <= "0100000";
             when "0111" => display <= "0001111";
             when "1000" => display <= "0000000";
             when "1001" => display <= "0001100";
             when "1010" => display <= "0001000";
             when "1011" => display <= "1100000";
             when "1100" => display <= "0110001";
             when "1101" => display <= "1000010";
             when "1110" => display <= "0110000";
             when others => display <= "0111000";
         end case;
     end process;
 end SevenSegDecoder_arch;