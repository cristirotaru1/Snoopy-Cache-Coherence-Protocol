library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity cache_controller is
    Port (
        clk             : IN STD_LOGIC;
        reset           : IN STD_LOGIC;
        read_hit        : IN STD_LOGIC;
        cpu_req         : IN STD_LOGIC;  -- Request from the processor to enable the cache
        cpu_func        : IN STD_LOGIC;  -- Processor operations: Read / Write
                                         --                          0 / 1
        stat            : IN STD_LOGIC_VECTOR(1 downto 0);  -- Invalid | Shared | Modified
                                                            --      00 |     10 |       11
        mem_ready       : IN STD_LOGIC;
        snoop_ready_in  : IN STD_LOGIC;
        snoop_hit_in    : IN STD_LOGIC;
        
        func            : OUT STD_LOGIC_VECTOR(2 downto 0); -- Operation the cache datapath should perform
        snoop_req_out   : OUT STD_LOGIC;    -- Snoop request to the other cache
        mem_cs          : OUT STD_LOGIC;
        mem_wr          : OUT STD_LOGIC;
        mem_rd          : OUT STD_LOGIC;
        cache_ready     : OUT STD_LOGIC;
        
        state           : INOUT STD_LOGIC_VECTOR(2 downto 0);
        next_state      : INOUT STD_LOGIC_VECTOR(2 downto 0)
    );
end cache_controller;

architecture Behavioral of cache_controller is
    constant b_read  : STD_LOGIC_VECTOR(2 downto 0) := "010";
    constant b_write : STD_LOGIC_VECTOR(2 downto 0) := "011";
    constant s_wait  : STD_LOGIC_VECTOR(2 downto 0) := "100";
    constant c_wait  : STD_LOGIC_VECTOR(2 downto 0) := "111";

    constant INVALID_s  : STD_LOGIC_VECTOR(1 downto 0) := "00";
    constant SHARED_s   : STD_LOGIC_VECTOR(1 downto 0) := "10";
    constant MODIFIED_s : STD_LOGIC_VECTOR(1 downto 0) := "11";

--    type state_type is (IDLE, CHECK_CACHE, WRITE_BACK, SNOOP_WAIT, MEM_READ);
--    signal state, next_state : state_type := IDLE;
    
    constant IDLE           : STD_LOGIC_VECTOR(2 downto 0) := "000";
    constant CHECK_CACHE    : STD_LOGIC_VECTOR(2 downto 0) := "001";
    constant WRITE_BACK     : STD_LOGIC_VECTOR(2 downto 0) := "010";
    constant SNOOP_WAIT    : STD_LOGIC_VECTOR(2 downto 0) := "011";
    constant MEM_READ    : STD_LOGIC_VECTOR(2 downto 0) := "100";
    
--    signal state, next_state : STD_LOGIC_VECTOR(2 downto 0) := IDLE;


begin

    -- State transition logic
    process(clk, reset)
    begin
        if reset = '1' then
            state <= IDLE;
        elsif rising_edge(clk) then
            state <= next_state;
        end if;
    end process;


    -- Next-state logic
    process(reset, state, cpu_req, cpu_func, read_hit, stat, mem_ready, snoop_ready_in, snoop_hit_in)
    begin
        
        if reset = '1' then
            mem_cs <= '0';
            mem_wr <= '0';
            mem_rd <= '0';
            snoop_req_out <= '0';
            cache_ready <= '0';
            func  <= "000";
            next_state <= state;
            
        else
            case state is
                when IDLE =>
                    cache_ready <= '1';     -- Cache is ready to accept requests
                    func <= c_wait;
                    if cpu_req = '1' then
                        next_state <= CHECK_CACHE;
                        cache_ready <= '0';
                    end if;
    
                when CHECK_CACHE =>
                    if read_hit = '1' then  -- Cache hit, do processor operation
                        if stat = MODIFIED_S then
                            next_state <= WRITE_BACK;
                        else
                            func <= "00" & cpu_func;
    --                        cache_ready <= '1'; -- Solves infinite loop
                            next_state <= IDLE;
                        end if;
                        
                    elsif read_hit = '0' and stat = MODIFIED_s then
    --                    func <= b_write;
                        next_state <= WRITE_BACK;
                    elsif read_hit = '0' and (stat = SHARED_s or stat = INVALID_s) then
--                        func <= b_read;
                        next_state <= SNOOP_WAIT;
--                        snoop_req_out <= '1';
                    end if;
    
                when WRITE_BACK =>
                    func <= b_write;
                    if stat = SHARED_s then
                        mem_wr <= '1';
                        mem_cs <= '1';
                    end if;

                    if mem_ready = '1' then
                        next_state <= CHECK_CACHE;
                        mem_cs <= '0';
                        mem_wr <= '0';
                    end if;
    
                when SNOOP_WAIT =>
                    func <= s_wait;
                    snoop_req_out <= '1';
                    if snoop_hit_in = '1' then
                        mem_cs <= '0';
                        snoop_req_out <= '0';
                        if snoop_ready_in = '1' then
                            next_state <= CHECK_CACHE;
                        end if;
                    elsif snoop_hit_in = '0' and snoop_ready_in = '1' then 
                        next_state <= MEM_READ;
                        snoop_req_out <= '0';
                    end if;
    
                when MEM_READ =>
                    func <= b_read;
                    mem_cs <= '1';
                    mem_rd <= '1';
                    if mem_ready = '1' then
                        next_state <= CHECK_CACHE;  -- On all cases, if we want to get data from Main Memory we want to do something with it (read or write)
                        mem_cs <= '0';
                        mem_rd <= '0';
                    end if;
                    
                 when others =>
                    next_state <= IDLE;
            end case;
        
        end if;


    end process;

end Behavioral;