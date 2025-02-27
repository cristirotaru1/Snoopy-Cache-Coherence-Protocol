library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity cache_data_path is
  Port (
    clk             : IN STD_LOGIC;
    reset           : IN STD_LOGIC;
    addr            : IN STD_LOGIC_VECTOR(7 DOWNTO 0); -- Physical address
    -- Address scheme:
    -- |tag ~4bits|index ~3bits|offset ~1bit|
    --  7        4 3          1 0
    data_in         : IN STD_LOGIC_VECTOR(15 DOWNTO 0); -- Data from CPU
    func            : IN STD_LOGIC_VECTOR(2 downto 0);  -- Processor Read/Write and Bus Read/Write or Wait
    invalidate_in   : IN STD_LOGIC;   -- Invalidate the cache line from the other cache

    bus_addr_in     : IN STD_LOGIC_VECTOR(7 DOWNTO 0);  -- Bus address from the other cache
    bus_addr_out    : OUT STD_LOGIC_VECTOR(7 DOWNTO 0); -- Bus address to the other cache
    bus_data_in     : IN STD_LOGIC_VECTOR(15 DOWNTO 0); -- Bus data from the other cache
    bus_data_out    : OUT STD_LOGIC_VECTOR(15 DOWNTO 0); -- Bus data to the other cache

    snoop_addr_in   : IN STD_LOGIC_VECTOR(7 downto 0);  -- Snoop address from the other cache
    snoop_addr_out  : OUT STD_LOGIC_VECTOR(7 downto 0); -- Snoop address to the other cache
    snoop_data_in   : IN STD_LOGIC_VECTOR(15 downto 0); -- Snoop data from the other cache
    snoop_data_out  : OUT STD_LOGIC_VECTOR(15 downto 0);    -- Snoop data to the other cache
    snoop_hit_in    : IN STD_LOGIC;     -- Snoop hit from the other cache
    snoop_hit_out   : OUT STD_LOGIC;    -- Snoop hit from this cache
    snoop_ready_out : OUT STD_LOGIC;    -- Snoop ready to send data
    snoop_req_in    : IN STD_LOGIC;     -- Snoop request from the other cache
    snoop_req_out   : IN STD_LOGIC;    -- Snoop request from this cache

    
    data_out        : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    read_hit        : OUT STD_LOGIC;
    invalidate_out  : OUT STD_LOGIC;    -- Request from this cache to invalidate 
                                        -- the cache line from the other cache  
    stat            : OUT STD_LOGIC_VECTOR(1 DOWNTO 0)   -- State of the cache line
   );
end cache_data_path;

architecture Behavioral of cache_data_path is    

    type cache_line is record
        tag     : STD_LOGIC_VECTOR(3 downto 0);
        data    : STD_LOGIC_VECTOR(31 downto 0);
        valid   : STD_LOGIC_VECTOR(1 downto 0);
        dirty   : STD_LOGIC_VECTOR(1 downto 0);
    end record;
    
    type cache_array is array (0 to 7) of cache_line;
    signal cache : cache_array := (others => (
        tag => (others => 'Z'),
        data => (others => 'Z'),
        valid => "00",
        dirty => "00"
    ));
    
    -- Function constants
    constant p_read     : STD_LOGIC_VECTOR(2 downto 0) := "000";
    constant p_write    : STD_LOGIC_VECTOR(2 downto 0) := "001";
    constant b_read     : STD_LOGIC_VECTOR(2 downto 0) := "010";
    constant b_write    : STD_LOGIC_VECTOR(2 downto 0) := "011";
    constant s_wait     : STD_LOGIC_VECTOR(2 downto 0) := "100";
    constant c_wait     : STD_LOGIC_VECTOR(2 downto 0) := "111";

    -- Address elements
    signal tag      : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
    signal index    : INTEGER range 0 to 7;
    signal offset   : STD_LOGIC := '0';
    signal offset_index : INTEGER range 0 to 1;

    signal bus_tag  : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
    signal bus_index: INTEGER range 0 to 7;
    signal bus_offset : STD_LOGIC := '0';
    signal bus_offset_index : INTEGER range 0 to 1;

    signal sn_tag   : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
    signal sn_index : INTEGER range 0 to 7;
    signal sn_offset: STD_LOGIC := '0';
    signal sn_offset_index : INTEGER range 0 to 1;
    
    signal read_hit_tmp : STD_LOGIC := '0';
    signal invalidate_out_tmp : STD_LOGIC := '0';
    
    signal snoop_addr_out_tmp : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');

begin  
    
    -- Address decomposition
    tag <= addr(7 downto 4);
    index <= to_integer(unsigned(addr(3 downto 1)));
    offset <= addr(0);
    offset_index <= 0 when offset = '0' else 1;
    
    -- Bus address decomposition
    bus_tag <= bus_addr_in(7 downto 4);
    bus_index <= to_integer(unsigned(bus_addr_in(3 downto 1)));
    bus_offset <= bus_addr_in(0);
    bus_offset_index <= 0 when bus_offset = '0' else 1;

    -- Snoop address decomposition
    sn_tag <= snoop_addr_in(7 downto 4);
    sn_index <= to_integer(unsigned(snoop_addr_in(3 downto 1)));
    sn_offset <= snoop_addr_in(0);
    sn_offset_index <= 0 when sn_offset = '0' else 1;
    
    process(clk, reset)
    begin
        if reset = '1' then
            cache <= (others => (
                tag => (others => 'Z'),
                data => (others => 'Z'),
                valid => "00",
                dirty => "00"
            ));
            invalidate_out_tmp <= '0';
            data_out <= (others => 'Z');
            bus_addr_out <= (others => '0');
            bus_data_out <= (others => '0');
            
            snoop_ready_out <= '0';
            snoop_hit_out <= '0';
            snoop_addr_out_tmp <= (others => '0');
            snoop_data_out <= (others => '0');
        
        elsif rising_edge(clk) then 
            invalidate_out_tmp <= '0';
            snoop_ready_out <= '0';
            snoop_hit_out <= '0';
                 
            case func is
                when p_read =>
                    -- Read hit from CPU
                    if read_hit_tmp = '1' then
                        case offset is
                            when '0' => data_out <= cache(index).data(15 downto 0);
                            when '1' => data_out <= cache(index).data(31 downto 16);
                            when others => null; 
                        end case;
                    end if;

                when p_write =>
                    -- Write hit from CPU
                    if read_hit_tmp = '1' then
                        case offset is
                            when '0' => cache(index).data(15 downto 0) <= data_in;
                            when '1' => cache(index).data(31 downto 16) <= data_in;
                            when others => null;
                        end case;
                        cache(index).dirty(offset_index) <= '1';  -- Set dirty bit on write => MODIFIED STATE

                    end if;
                    invalidate_out_tmp <= '1'; -- Invalidate the other cache 

                when b_read =>
                    -- Read from the bus
                    bus_addr_out <= addr;
                    case bus_offset is 
                        when '0' => cache(bus_index).data(15 downto 0) <= bus_data_in;
                        when '1' => cache(bus_index).data(31 downto 16) <= bus_data_in;
                        when others => null;
                    end case;
                    cache(bus_index).tag <= bus_tag;    -- Update the tag  
                    cache(bus_index).valid(offset_index) <= '1';  -- Assign valid data       
                    cache(bus_index).dirty(offset_index) <= '0';  -- Assign clean on data read from bus => SHARED STATE

                when b_write =>
                    -- Write to bus
                    bus_addr_out <= addr;
                    case offset is 
                        when '0' => bus_data_out <= cache(index).data(15 downto 0);
                        when '1' => bus_data_out <= cache(index).data(31 downto 16);
                        when others => null;
                    end case;
                    cache(index).dirty(offset_index) <= '0';  -- Assign clean on write-back    
                    
                when s_wait => 
                    -- Snoop process
                    
                    -- Provide the address to snoop for invalidation or data request
                    if invalidate_out_tmp = '1' or (snoop_req_out = '1' and snoop_addr_out_tmp /= addr) then
                        snoop_addr_out_tmp <= addr;
                    
                    -- Request from the other cache to provide the data it wants if this cache has it
                    elsif snoop_req_in = '1' then
                        if cache(sn_index).valid(sn_offset_index) = '1' and sn_tag = cache(sn_index).tag then 
                            case sn_offset is
                                when '0' => snoop_data_out <= cache(sn_index).data(15 downto 0);
                                when '1' => snoop_data_out <= cache(sn_index).data(31 downto 16);
                                when others => null;
                            end case;
                            snoop_hit_out <= '1';   -- I have the data that the other cache requested
                            snoop_addr_out_tmp <= snoop_addr_in;
                            snoop_ready_out <= '1';
                        else
                            snoop_hit_out <= '0';
                            snoop_ready_out <= '1';
                        end if;
                    
                    -- The other cache has the data that this cache requested
                    elsif snoop_hit_in = '1' then
                        case offset is
                            when '0' => cache(index).data(15 downto 0) <= snoop_data_in;
                            when '1' => cache(index).data(31 downto 16) <= snoop_data_in;
                            when others => null;
                        end case;
                        cache(index).tag <= sn_tag;
                        cache(index).valid(offset_index) <= '1';  -- Assign valid on data read from snoop
                        cache(index).dirty(offset_index) <= '0';  -- Assign clean on data read from snoop => SHARED STATE                   
                        
                    -- Provide the address to snoop for invalidation or data request

                        
                    end if;

                when c_wait => 
                    -- Request from the other cache to provide the data it wants if this cache has it
                    if snoop_req_in = '1' then
                        if cache(sn_index).valid(sn_offset_index) = '1' and sn_tag = cache(sn_index).tag then 
                            case sn_offset is
                                when '0' => snoop_data_out <= cache(sn_index).data(15 downto 0);
                                when '1' => snoop_data_out <= cache(sn_index).data(31 downto 16);
                                when others => null;
                            end case;
                            snoop_hit_out <= '1';   -- I have the data that the other cache requested
                            snoop_addr_out_tmp <= snoop_addr_in;
                            snoop_ready_out <= '1';
                        else
                            snoop_hit_out <= '0';
                            snoop_ready_out <= '1';
                        end if;
                    end if;
                    
                when others => null;
            end case;
            
            -- Request from the other cache to invalidate the cache line
            if invalidate_in = '1' then
                cache(sn_index).valid(sn_offset_index) <= '0';
                cache(sn_index).dirty(sn_offset_index) <= '0';   -- => INVALID STATE;                         
            end if;
                        
        end if;
    end process;

    read_hit_tmp <= '1' when (cache(index).valid(offset_index) = '1' and cache(index).tag = tag and reset = '0') else '0';
    read_hit <= read_hit_tmp;
    
    invalidate_out <= invalidate_out_tmp;
    snoop_addr_out <= snoop_addr_out_tmp;
    
    stat <= cache(index).valid(offset_index) & cache(index).dirty(offset_index);


end Behavioral;
