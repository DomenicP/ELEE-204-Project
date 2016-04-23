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

entity WashingMachineController is
	port(CLOCK_50 : in  std_logic;
		  KEY      : in  std_logic_vector(3  downto 0);
		  SW       : in  std_logic_vector(17 downto 0);
		  LEDR     : out std_logic_vector(17 downto 0);
		  LEDG	  : out std_logic_vector(3 downto 0);
		  HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7 : out std_logic_vector(0 to 6));
end;

architecture WashingMachineController_arch of WashingMachineController is
	-- Decoder for the 7-segment hex display on the DE2 board
	component SevenSegDecoder
		port(hex     : in std_logic_vector(3 downto 0);
			  display : out std_logic_vector(0 to 6));
	end component;

	type payment_state_type is (zero, twentyfive, fifty, seventyfive, onedollar, dollartwentyfive, coin_jam);
		-- zero
		-- twentyfive
		-- fifty
		-- seventyfive
		-- onedollar
		-- dollartwentyfive
		
	type cycle_state_type is (cycle_select, wash, wash_ext, rinse, spin, refund, error);
		-- wash
		-- wash_ext
		-- rinse
		-- spin
		-- coin_jam
		-- refund
		-- error
		
	type cycle_type is (hot_cycle, warm_cycle, cold_cycle);
		-- cycle_type represents the different water temperature wash cycles
		
	signal quarter, whites, colors, brights, override : std_logic;
		-- quarter represents a quarter input
		-- whites represents selecting a hot water cycle
		-- colors represents selecting a warm water cycle
		-- brights represents selecting a cold water cycle
		-- override represents a request from the user to stop the wash cycle
	
	signal jam, balance, water : std_logic;
		-- jam is 1 when the system detects a coin jam, and 0 otherwise
		-- balance is 1 when the sensor detects the washer is out of balance, and 0 otherwise
		-- water is 1 when the system detects a water level related error, and 0 otherwise
		
	signal reset : std_logic;
		-- reset is used to manually reset the system after entering an error state_type
	
	signal payment_state : payment_state_type := zero;
		-- Represents the current state of the payment FSM
	
	signal cycle_state, next_cycle_state : cycle_state_type;
		-- cur_state represents the current state of the washer cycle control FSM
		-- next_state represents the next state that should be transitioned to
		
	signal selected_cycle : cycle_type;
		-- selected_cycle stores the information regarding the selected water type
		
	signal hex0_dat, hex1_dat, hex2_dat, hex3_dat, hex4_dat, hex5_dat, hex6_dat, hex7_dat : std_logic_vector(3 downto 0);
	
begin
	
	-- Assign names input signals
	quarter <= KEY(0);
	whites <= KEY(3);
	colors <= KEY(2);
	brights <= KEY(1);
	
	override <= SW(0);
	jam <= SW(9);
	balance <= SW(10);
	water <= SW(11);
	reset <= SW(17);
	
	-- Instantiate the hex-display decoders
	hex0_decoder : SevenSegDecoder port map (hex0_dat, HEX0);
	hex1_decoder : SevenSegDecoder port map (hex1_dat, HEX1);
	hex2_decoder : SevenSegDecoder port map (hex2_dat, HEX2);
	hex3_decoder : SevenSegDecoder port map (hex3_dat, HEX3);
	
	-- Handle quarter inputs
	insert_quarter: process (quarter, jam)
	begin
		-- Check for a coin jam
		if jam = '1' then
			payment_state <= coin_jam;
		else
			-- No coin jam; check for a button press and advance the FSM
			if quarter'event and quarter = '1' then
				case payment_state is
					when zero => 					payment_state <= twentyfive;
					when twentyfive => 			payment_state <= fifty;
					when fifty => 					payment_state <= seventyfive;
					when seventyfive => 			payment_state <= onedollar;
					when onedollar => 			payment_state <= dollartwentyfive;
					when dollartwentyfive => 	payment_state <= dollartwentyfive;
					when others => 				payment_state <= zero;
				end case;
			end if;
		end if;
	end process insert_quarter;

	-- Update the hex display that shows the payment state
	update_payment_display: process (payment_state)
	begin
		case payment_state is
			when zero =>
				hex0_dat <= x"0";
				hex1_dat <= x"0";
				hex2_dat <= x"0";
				
			when twentyfive =>
				hex0_dat <= x"5";
				hex1_dat <= x"2";
				hex2_dat <= x"0";
				
			when fifty =>
				hex0_dat <= x"0";
				hex1_dat <= x"5";
				hex2_dat <= x"0";
				
			when seventyfive =>
				hex0_dat <= x"5";
				hex1_dat <= x"7";
				hex2_dat <= x"0";
				
			when onedollar =>
				hex0_dat <= x"0";
				hex1_dat <= x"0";
				hex2_dat <= x"1";
				
			when dollartwentyfive =>
				hex0_dat <= x"5";
				hex1_dat <= x"2";
				hex2_dat <= x"1";
			
			when others =>
				hex0_dat <= x"0";
				hex1_dat <= x"0";
				hex2_dat <= x"0";
			
		end case;
		hex3_dat <= x"0";
	end process update_payment_display;
	
	-- Set output LEDs
	LEDG(0) <= '1' when payment_state = onedollar or payment_state = dollartwentyfive else '0';
	LEDG(1) <= '1' when payment_state = dollartwentyfive else '0';
	
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

