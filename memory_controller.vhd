library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity memory_controller is
    Port (
        clk             : IN STD_LOGIC;
        bus1_addr_in    : IN STD_LOGIC_VECTOR(7 downto 0);
        bus1_addr_out   : OUT STD_LOGIC_VECTOR(7 downto 0);
        bus2_addr_in    : IN STD_LOGIC_VECTOR(7 downto 0);
        bus2_addr_out   : OUT STD_LOGIC_VECTOR(7 downto 0);
        bus1_data_in    : IN STD_LOGIC_VECTOR(15 downto 0);
        bus1_data_out   : OUT STD_LOGIC_VECTOR(15 downto 0);
        bus2_data_in    : IN STD_LOGIC_VECTOR(15 downto 0);
        bus2_data_out   : OUT STD_LOGIC_VECTOR(15 downto 0);
        
        mem_cs1   : IN STD_LOGIC;
        mem_rd1   : IN STD_LOGIC;
        mem_wr1   : IN STD_LOGIC;
        
        mem_cs2   : IN STD_LOGIC;
        mem_rd2   : IN STD_LOGIC;
        mem_wr2   : IN STD_LOGIC;
        
        mem_ready : IN STD_LOGIC;
        controller_ready: OUT STD_LOGIC;

        mem_addr      : OUT STD_LOGIC_VECTOR(7 downto 0);
        mem_data_in   : IN STD_LOGIC_VECTOR(15 downto 0);
        mem_data_out  : OUT STD_LOGIC_VECTOR(15 downto 0);
        mem_enable    : OUT STD_LOGIC;
        rd, wr        : OUT STD_LOGIC
    );
end memory_controller;

architecture Behavioral of memory_controller is

begin

    process(clk)
    begin
        

        if rising_edge(clk) then
            if mem_cs1 = '1' then
                mem_addr <= bus1_addr_in;
                mem_data_out <= bus1_data_in;
                
                mem_enable <= '1';
                if mem_rd1 = '1' then
                    rd <= '1';
                elsif mem_wr1 = '1' then
                    wr <= '1';
                end if;
                   
                -- TODO SA OUI SI ADRESA
                if mem_ready = '1' then
                    controller_ready <= '1';
                    bus1_addr_out <= bus1_addr_in;
                    bus1_data_out <= mem_data_in;
                end if;
                
            elsif mem_cs2 = '1' then
                mem_addr <= bus2_addr_in;
                mem_data_out <= bus2_data_in;
                mem_enable <= '1';
                if mem_rd2 = '1' then
                    rd <= '1';
                elsif mem_wr2 = '1' then
                    wr <= '1';
                end if;
                
                if mem_ready = '1' then
                    controller_ready <= '1';
                    bus2_addr_out <= bus2_addr_in;
                    bus2_data_out <= mem_data_in;
                end if;
                
            else
                mem_addr <= (others => 'Z');
                mem_data_out <= (others => 'Z');
                mem_enable <= '0';
                controller_ready <= '0';
                bus1_data_out <= (others => 'Z');
                bus2_data_out <= (others => 'Z');
                rd <= '0';
                wr <= '0'; 
            end if;
        end if;
    end process;


end Behavioral;