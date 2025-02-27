library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity main is
  Port (
    clk             : IN STD_LOGIC;
    reset           : IN STD_LOGIC;
    enable1         : IN STD_LOGIC;
    enable2         : IN STD_LOGIC;
    
    cache1_op_out   : INOUT STD_LOGIC;
    cache1_addr_out : INOUT STD_LOGIC_VECTOR(7 downto 0);
    cache1_data_out : OUT STD_LOGIC_VECTOR(15 downto 0);
    cache1_stat     : INOUT STD_LOGIC_VECTOR(1 downto 0);
    cache1_controller_state    : INOUT STD_LOGIC_VECTOR(2 downto 0);
    
    bus1_addr_mem_in, bus2_addr_mem_in : INOUT STD_LOGIC_VECTOR(7 downto 0);
    bus1_addr_mem_01, bus2_addr_mem_10 : INOUT STD_LOGIC_VECTOR(7 downto 0);
    bus_data_mem_01, bus_data_mem_10   : INOUT STD_LOGIC_VECTOR(15 downto 0);
    bus1_data_mem_in, bus2_data_mem_in : INOUT STD_LOGIC_VECTOR(15 downto 0);
    
    snoop_addr_01, snoop_addr_10 : INOUT STD_LOGIC_VECTOR(7 downto 0);
    snoop_data_01, snoop_data_10 : INOUT STD_LOGIC_VECTOR(15 downto 0);
    snoop_hit_01, snoop_hit_10 : INOUT STD_LOGIC;
    snoop_req_01, snoop_req_10 : INOUT STD_LOGIC;
    snoop_ready_01, snoop_ready_10: INOUT STD_LOGIC;
    
    mem_cs1, mem_rd1, mem_wr1 : INOUT STD_LOGIC;
    mem_cs2, mem_rd2, mem_wr2 : INOUT STD_LOGIC;
    mem_enable, ram_ready, rd, wr : INOUT STD_LOGIC;
    mem_addr_in : INOUT STD_LOGIC_VECTOR(7 downto 0);
    mem_data_in : INOUT STD_LOGIC_VECTOR(15 downto 0);
    data_out    : INOUT STD_LOGIC_VECTOR(15 downto 0);
    
    invalidate_01, invalidate_10 : INOUT STD_LOGIC;
    
    cache2_op_out   : INOUT STD_LOGIC;
    cache2_addr_out : INOUT STD_LOGIC_VECTOR(7 downto 0);
    cache2_data_out : OUT STD_LOGIC_VECTOR(15 downto 0);
    cache2_stat     : INOUT STD_LOGIC_VECTOR(1 downto 0);
    cache2_controller_state    : INOUT STD_LOGIC_VECTOR(2 downto 0) 
   );
end main;

architecture Behavioral of main is

    component cache1 is
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
    end component;
    
    component cache2 is
        Port (
            clk             : IN STD_LOGIC;
            reset           : IN STD_LOGIC;
            enable          : IN STD_LOGIC;
            mem_ready       : IN STD_LOGIC;
    
            bus_addr_mem_in : IN STD_LOGIC_VECTOR(7 downto 0);
            bus_addr_mem_10 : OUT STD_LOGIC_VECTOR(7 downto 0);
            bus_data_mem_in : IN STD_LOGIC_VECTOR(15 downto 0);
            bus_data_mem_10 : OUT STD_LOGIC_VECTOR(15 downto 0);
    
            snoop_addr_01   : IN STD_LOGIC_VECTOR(7 downto 0);
            snoop_addr_10   : OUT STD_LOGIC_VECTOR(7 downto 0);
            snoop_data_01   : IN STD_LOGIC_VECTOR(15 downto 0);
            snoop_data_10   : OUT STD_LOGIC_VECTOR(15 downto 0);
            snoop_hit_01    : IN STD_LOGIC;
            snoop_hit_10    : OUT STD_LOGIC;
            snoop_req_01    : IN STD_LOGIC;
            snoop_req_10    : OUT STD_LOGIC;
            snoop_ready_10  : OUT STD_LOGIC;
            snoop_ready_01  : IN STD_LOGIC;            
    
            invalidate_in   : IN STD_LOGIC;
            invalidate_out  : OUT STD_LOGIC;
    
            mem_cs2         : OUT STD_LOGIC;
            mem_rd2         : OUT STD_LOGIC;
            mem_wr2         : OUT STD_LOGIC;
            
            
            stat            : INOUT STD_LOGIC_VECTOR(1 downto 0);
            cpu_func        : INOUT STD_LOGIC;
            func            : INOUT STD_LOGIC_VECTOR(2 downto 0);
            state           : INOUT STD_LOGIC_VECTOR(2 downto 0);
    --        next_state      : INOUT STD_LOGIC_VECTOR(2 downto 0);
    --        cpu_req         : INOUT STD_LOGIC;
            cache_ready     : INOUT STD_LOGIC;
            addr            : INOUT STD_LOGIC_VECTOR(7 downto 0);
            cache2_data_out  : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
        );
    end component;
    
    component memory_controller is
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
    end component;
    
    component ram_memory is
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
    end component;
    
--    signal bus1_addr_mem_in, bus2_addr_mem_in : STD_LOGIC_VECTOR(7 downto 0);
--    signal bus1_addr_mem_01, bus2_addr_mem_10 : STD_LOGIC_VECTOR(7 downto 0);
--    signal bus_data_mem_01, bus_data_mem_10 : STD_LOGIC_VECTOR(15 downto 0);
--    signal bus1_data_mem_in, bus2_data_mem_in : STD_LOGIC_VECTOR(15 downto 0);

--    signal mem_cs1, mem_rd1, mem_wr1 : STD_LOGIC;
--    signal mem_cs2, mem_rd2, mem_wr2 : STD_LOGIC;
--    signal mem_enable, rd, wr : STD_LOGIC;

    signal mem_ready : STD_LOGIC;

--    signal snoop_addr_01, snoop_addr_10 : STD_LOGIC_VECTOR(7 downto 0);
--    signal snoop_data_01, snoop_data_10 : STD_LOGIC_VECTOR(15 downto 0);
--    signal snoop_hit_01, snoop_hit_10 : STD_LOGIC;
--    signal snoop_req_01, snoop_req_10 : STD_LOGIC;

--    signal invalidate_01, invalidate_10 : STD_LOGIC;

--    signal data_out : STD_LOGIC_VECTOR(15 downto 0);
--    signal mem_addr_in : STD_LOGIC_VECTOR(7 downto 0);
--    signal mem_data_in : STD_LOGIC_VECTOR(15 downto 0);


begin

    c1: cache1
        port map(
            clk             => clk,
            reset           => reset,
            enable          => enable1,
            mem_ready       => ram_ready,
            bus_addr_mem_in => bus1_addr_mem_in,
            bus_addr_mem_01 => bus1_addr_mem_01,
            bus_data_mem_in => bus1_data_mem_in,
            bus_data_mem_01 => bus_data_mem_01,
            snoop_addr_10   => snoop_addr_10,
            snoop_addr_01   => snoop_addr_01,
            snoop_data_10   => snoop_data_10,
            snoop_data_01   => snoop_data_01,
            snoop_hit_10    => snoop_hit_10,
            snoop_hit_01    => snoop_hit_01,
            snoop_req_10    => snoop_req_10,
            snoop_req_01    => snoop_req_01,
            snoop_ready_01  => snoop_ready_01,
            snoop_ready_10  => snoop_ready_10,
            invalidate_in   => invalidate_01,
            invalidate_out  => invalidate_10,
            mem_cs1         => mem_cs1,
            mem_rd1         => mem_rd1,
            mem_wr1         => mem_wr1,
            stat            => cache1_stat,
            cpu_func        => cache1_op_out,
            -- func            => func,
            state           => cache1_controller_state,
            -- next_state      => next_state,
            -- cpu_req         => cpu_req,
            -- cache_ready     => cache_ready,
            addr            => cache1_addr_out,
            cache1_data_out        => cache1_data_out
        );

    c2: cache2
        port map(
            clk             => clk,
            reset           => reset,
            enable          => enable2,
            mem_ready       => ram_ready,
            bus_addr_mem_in => bus2_addr_mem_in,
            bus_addr_mem_10 => bus2_addr_mem_10,
            bus_data_mem_in => bus2_data_mem_in,
            bus_data_mem_10 => bus_data_mem_10,
            snoop_addr_01   => snoop_addr_01,
            snoop_addr_10   => snoop_addr_10,
            snoop_data_01   => snoop_data_01,
            snoop_data_10   => snoop_data_10,
            snoop_hit_01    => snoop_hit_01,
            snoop_hit_10    => snoop_hit_10,
            snoop_req_01    => snoop_req_01,
            snoop_req_10    => snoop_req_10,
            snoop_ready_10  => snoop_ready_10,
            snoop_ready_01  => snoop_ready_01,
            invalidate_in   => invalidate_10,
            invalidate_out  => invalidate_01,
            mem_cs2         => mem_cs2,
            mem_rd2         => mem_rd2,
            mem_wr2         => mem_wr2,
            stat            => cache2_stat,
            cpu_func        => cache2_op_out,
            state           => cache2_controller_state,
            addr            => cache2_addr_out,
            cache2_data_out => cache2_data_out
        );

    mc: component memory_controller
        port map(
            clk           => clk,
            bus1_addr_in  => bus1_addr_mem_01,
            bus1_addr_out => bus1_addr_mem_in,
            bus2_addr_in  => bus2_addr_mem_10,
            bus2_addr_out => bus2_addr_mem_in,
            bus1_data_in  => bus_data_mem_01,
            bus1_data_out => bus1_data_mem_in,
            bus2_data_in  => bus_data_mem_10,
            bus2_data_out => bus2_data_mem_in,
            mem_cs1       => mem_cs1,
            mem_rd1       => mem_rd1,
            mem_wr1       => mem_wr1,
            mem_cs2       => mem_cs2,
            mem_rd2       => mem_rd2,
            mem_wr2       => mem_wr2,
            mem_ready     => mem_ready,
            controller_ready => ram_ready,
            mem_addr      => mem_addr_in,
            mem_data_in   => data_out,
            mem_data_out  => mem_data_in,
            mem_enable    => mem_enable,
            rd            => rd,
            wr            => wr
        );
    

    ram: component ram_memory
        port map(
            reset     => reset,
            clk       => clk,
            RD        => rd,
            WR        => wr,
            addr      => mem_addr_in,
            data_in   => mem_data_in,
            enable    => mem_enable,
            data_out  => data_out,
            ram_ready => mem_ready
        );
    
    
    
    


end Behavioral;
