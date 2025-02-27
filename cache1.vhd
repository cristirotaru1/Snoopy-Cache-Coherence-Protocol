library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity cache1 is
    Port (
        clk             : IN STD_LOGIC;
        reset           : IN STD_LOGIC;
        enable          : IN STD_LOGIC;
        mem_ready       : IN STD_LOGIC;

        bus_addr_mem_in : IN STD_LOGIC_VECTOR(7 downto 0);
        bus_addr_mem_01 : OUT STD_LOGIC_VECTOR(7 downto 0);
        bus_data_mem_in : IN STD_LOGIC_VECTOR(15 downto 0);
        bus_data_mem_01 : OUT STD_LOGIC_VECTOR(15 downto 0);

        snoop_addr_10   : IN STD_LOGIC_VECTOR(7 downto 0);
        snoop_addr_01   : OUT STD_LOGIC_VECTOR(7 downto 0);
        snoop_data_10   : IN STD_LOGIC_VECTOR(15 downto 0);
        snoop_data_01   : OUT STD_LOGIC_VECTOR(15 downto 0);
        snoop_hit_10    : IN STD_LOGIC;
        snoop_hit_01    : OUT STD_LOGIC;
        snoop_req_10    : IN STD_LOGIC;
        snoop_req_01    : OUT STD_LOGIC;
        snoop_ready_01  : OUT STD_LOGIC;
        snoop_ready_10  : IN STD_LOGIC;


        invalidate_in   : IN STD_LOGIC;
        invalidate_out  : OUT STD_LOGIC;

        mem_cs1         : OUT STD_LOGIC;
        mem_rd1         : OUT STD_LOGIC;
        mem_wr1         : OUT STD_LOGIC;
        
        -- For testbenching
        stat            : INOUT STD_LOGIC_VECTOR(1 downto 0);
        cpu_func        : INOUT STD_LOGIC;
        func            : INOUT STD_LOGIC_VECTOR(2 downto 0);
        state           : INOUT STD_LOGIC_VECTOR(2 downto 0);
--        next_state      : INOUT STD_LOGIC_VECTOR(2 downto 0);
--        cpu_req         : INOUT STD_LOGIC;
        cache_ready     : INOUT STD_LOGIC;
        addr            : INOUT STD_LOGIC_VECTOR(7 downto 0);
        cache1_data_out : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
--        data_out        : INOUT STD_LOGIC_VECTOR(15 downto 0)
    );
end entity;

architecture Behavioral of cache1 is
    
    component processor_core1 is 
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
    end component;

    component cache_controller is
        Port (
            clk             : IN STD_LOGIC;
            reset           : IN STD_LOGIC;
            read_hit        : IN STD_LOGIC;
            cpu_req         : IN STD_LOGIC;
            cpu_func        : IN STD_LOGIC;
            stat            : IN STD_LOGIC_VECTOR(1 downto 0);
            mem_ready       : IN STD_LOGIC;
            snoop_ready_in  : IN STD_LOGIC;
            snoop_hit_in    : IN STD_LOGIC;
            
            func            : OUT STD_LOGIC_VECTOR(2 downto 0);
            snoop_req_out   : OUT STD_LOGIC;
            mem_cs          : OUT STD_LOGIC;
            mem_wr          : OUT STD_LOGIC;
            mem_rd          : OUT STD_LOGIC;
            cache_ready     : OUT STD_LOGIC;
            
            -- For testbenching
            state           : INOUT STD_LOGIC_VECTOR(2 downto 0);
            next_state      : INOUT STD_LOGIC_VECTOR(2 downto 0)
        );
    end component;

    component cache_data_path is
        Port (
          clk             : IN STD_LOGIC;
          reset           : IN STD_LOGIC;
          addr            : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
          data_in         : IN STD_LOGIC_VECTOR(15 DOWNTO 0); 
          func            : IN STD_LOGIC_VECTOR(2 downto 0); 
          invalidate_in   : IN STD_LOGIC;   
      
          bus_addr_in     : IN STD_LOGIC_VECTOR(7 DOWNTO 0); 
          bus_addr_out    : OUT STD_LOGIC_VECTOR(7 DOWNTO 0); 
          bus_data_in     : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
          bus_data_out    : OUT STD_LOGIC_VECTOR(15 DOWNTO 0); 
      
          snoop_addr_in   : IN STD_LOGIC_VECTOR(7 downto 0);  
          snoop_addr_out  : OUT STD_LOGIC_VECTOR(7 downto 0); 
          snoop_data_in   : IN STD_LOGIC_VECTOR(15 downto 0); 
          snoop_data_out  : OUT STD_LOGIC_VECTOR(15 downto 0);    
          snoop_hit_in    : IN STD_LOGIC;     
          snoop_hit_out   : OUT STD_LOGIC; 
          snoop_ready_out : OUT STD_LOGIC; 
          snoop_req_in    : IN STD_LOGIC;     
          snoop_req_out   : IN STD_LOGIC; 
      
          
          data_out        : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
          read_hit        : OUT STD_LOGIC;
          invalidate_out  : OUT STD_LOGIC;    
          stat            : OUT STD_LOGIC_VECTOR(1 DOWNTO 0)
         );
      end component;

--    signal cache_ready  : STD_LOGIC;
--    signal cpu_func     : STD_LOGIC;
    signal cpu_req      : STD_LOGIC;
--    signal addr         : STD_LOGIC_VECTOR(7 downto 0);
    signal data_out     : STD_LOGIC_VECTOR(15 downto 0);

    signal read_hit     : STD_LOGIC;
    signal snoop_ready  : STD_LOGIC;
--    signal stat         : STD_LOGIC_VECTOR(1 downto 0);
--    signal func         : STD_LOGIC_VECTOR(2 downto 0);
    signal next_state   : STD_LOGIC_VECTOR(2 downto 0);

    signal snoop_req_01_tmp : STD_LOGIC;

begin
    
    proc_core1: processor_core1
        port map(
            clk         => clk,
            reset       => reset,
            enable      => enable,
            cache_ready => cache_ready,
            cpu_func    => cpu_func,
            cpu_req     => cpu_req,
            address     => addr,
            data_out    => data_out
        );

    cache_ctrl: cache_controller
        port map(
            clk            => clk,
            reset          => reset,
            read_hit       => read_hit,
            cpu_req        => cpu_req,
            cpu_func       => cpu_func,
            stat           => stat,
            mem_ready      => mem_ready,
            snoop_ready_in => snoop_ready_10,
            snoop_hit_in   => snoop_hit_10,
            func           => func,
            snoop_req_out  => snoop_req_01_tmp,
            mem_cs         => mem_cs1,
            mem_wr         => mem_wr1,
            mem_rd         => mem_rd1,
            cache_ready    => cache_ready,
            state          => state,
            next_state     => next_state
        );

        cache_data: cache_data_path
            port map(
                clk             => clk,
                reset           => reset,
                addr            => addr,
                data_in         => data_out,
                func            => func,
                invalidate_in   => invalidate_in,
                bus_addr_in     => bus_addr_mem_in,
                bus_addr_out    => bus_addr_mem_01,
                bus_data_in     => bus_data_mem_in,
                bus_data_out    => bus_data_mem_01,
                snoop_addr_in   => snoop_addr_10,
                snoop_addr_out  => snoop_addr_01,
                snoop_data_in   => snoop_data_10,
                snoop_data_out  => snoop_data_01,
                snoop_hit_in    => snoop_hit_10,
                snoop_hit_out   => snoop_hit_01,
                snoop_ready_out => snoop_ready_01,
                snoop_req_in    => snoop_req_10,
                snoop_req_out   => snoop_req_01_tmp,
                data_out        => cache1_data_out,
                read_hit        => read_hit,
                invalidate_out  => invalidate_out,
                stat            => stat
            );
        
    snoop_req_01 <= snoop_req_01_tmp;
    


end architecture Behavioral;
