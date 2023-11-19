library IEEE;
use IEEE.std_logic_1164.all;  
use IEEE.numeric_std.all;    

entity cpu_TLB_data is
   port 
   (
      clk93                : in  std_logic;
      reset                : in  std_logic;
                           
      TLBWI                : in  std_logic;
      TLBWR                : in  std_logic;
                           
      TLB_Req              : in  std_logic;
      TLB_IsWrite          : in  std_logic;
      TLB_AddrIn           : in  unsigned(63 downto 0);
      TLB_Stall            : out std_logic := '0';
      TLB_UnStall          : out std_logic := '0';
      TLB_AddrOut          : out unsigned(31 downto 0) := (others => '0');
                           
      TLB_fetchReq         : out std_logic := '0';
      TLB_fetchIsWrite     : out std_logic := '0';
      TLB_fetchAddrIn      : out unsigned(63 downto 0) := (others => '0');
      TLB_fetchDone        : in  std_logic;
      TLB_fetchExcInvalid  : in  std_logic;
      TLB_fetchExcDirty    : in  std_logic;
      TLB_fetchExcNotFound : in  std_logic;
      TLB_fetchCached      : in  std_logic;
      TLB_fetchAddrOut     : in  unsigned(31 downto 0)
   );
end entity;

architecture arch of cpu_TLB_data is
 
   type tstate is
   (
      IDLE,
      REQUEST
   );
   signal state : tstate := IDLE;

begin 

   TLB_Stall <= '1' when (TLB_Req = '1') else '0';

   process (clk93)
   begin
      if (rising_edge(clk93)) then
      
         TLB_UnStall   <= '0';
         TLB_fetchReq  <= '0';
      
         if (reset = '1') then
         
            state <= IDLE;
           
         else
         
            case (state) is
            
               when IDLE =>
                  if (TLB_Req = '1') then
                     state            <= REQUEST;
                     TLB_fetchReq     <= '1';
                     TLB_fetchIsWrite <= TLB_IsWrite;
                     TLB_fetchAddrIn  <= TLB_AddrIn; 
                  end if;
                 
               when REQUEST =>
                  if (TLB_fetchDone = '1') then
                     state       <= IDLE;
                     TLB_UnStall <= '1';
                     TLB_AddrOut <= TLB_fetchAddrOut;
                  end if;
            
            end case;

         end if;
      end if;
   end process;
   
end architecture;
