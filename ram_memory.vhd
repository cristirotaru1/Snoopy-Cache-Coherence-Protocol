library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ram_memory is
  Port (
    reset       : IN STD_LOGIC;
    clk         : IN STD_LOGIC;
    RD, WR      : IN STD_LOGIC;
    addr        : IN STD_LOGIC_VECTOR(7 downto 0);
    data_in     : IN STD_LOGIC_VECTOR(15 downto 0);
    enable      : IN STD_LOGIC;
    
    data_out    : OUT STD_LOGIC_VECTOR(15 downto 0);
    ram_ready   : OUT STD_LOGIC
   );
end ram_memory;

architecture Behavioral of ram_memory is

    type memory_array is array (0 to 63) of STD_LOGIC_VECTOR(15 downto 0);
    signal mem : memory_array := (others => (others => '0'));

begin

    -- memory operations
    process(clk, reset)
    begin
        if reset = '1' then
            mem <= (others => (others => '0'));
            ram_ready <= '0';
        
        elsif rising_edge(clk) then
            ram_ready <= '0';
            
            if enable = '1' then
                if (rd = '1' and wr = '0') then
                    data_out <= mem(to_integer(unsigned(addr)));
                    ram_ready <= '1';
                elsif (rd = '0' and wr = '1') then
                    data_out <= (others => 'Z');
                    mem(to_integer(unsigned(addr))) <= data_in;
                    ram_ready <= '1';
                end if;
            else
                data_out <= (others => 'Z');
            end if;
        end if;
    end process;


end Behavioral;
