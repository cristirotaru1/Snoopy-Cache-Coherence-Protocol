library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity processor_core2 is 
    Port (
        clk             : in STD_LOGIC;
        reset           : in STD_LOGIC;
        enable          : in STD_LOGIC;
        cache_ready     : in STD_LOGIC;
        
        cpu_func        : OUT STD_LOGIC;
        cpu_req         : OUT STD_LOGIC;
        address         : OUT STD_LOGIC_VECTOR(7 downto 0);
        data_out        : OUT STD_LOGIC_VECTOR(15 downto 0)

    );
end processor_core2;

architecture Behavioral of processor_core2 is

    -- Instruction structure:
    -- |op ~1bit|addr ~8bits|data ~16 bits| ~25bits
    --  24       23       16 15        0
    -- op=1 -> write | op=0 -> read
    type instr_array_t is array (0 to 9) of STD_LOGIC_VECTOR(24 downto 0);
    signal instr_mem : instr_array_t := (
        b"1000000100000000000000010",   -- write 0x02 0x0002
        b"0000000000000000000001000",   -- read  0x00 0x0008
        b"0000000000000000000000000",
        b"0000001010000000000000000",
        b"0000100110000000000000000",
        b"1000000010000000000100000",
        b"1000000000000000001000000",
        b"1000000000000000001000001",
        b"1100000000000000011111111",
        b"1010000001000000011111111"
    );

    signal is_waiting : STD_LOGIC := '0';

begin

    process(clk, reset)
    VARIABLE index : integer range 0 to 9 := 0;
    begin
        if reset = '1' then
            index := 0;
            is_waiting <= '0';
            cpu_req <= '0';
            cpu_func <= '0';
            address <= (others => '0');
            data_out <= (others => '0');
    
        elsif rising_edge(clk) then
            if enable = '1' then
                cpu_req <= '1';
                cpu_func <= instr_mem(index)(24);
                address <= instr_mem(index)(23 downto 16);
                data_out <= instr_mem(index)(15 downto 0);
                if index < 9 then
                    index := index + 1;
                else
                    index := 0;
                end if;
                
            else
                cpu_req <= '0';               
            end if;
            
        end if;
    end process;



end Behavioral;