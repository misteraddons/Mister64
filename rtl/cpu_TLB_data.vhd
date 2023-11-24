library IEEE;
use IEEE.std_logic_1164.all;  
use IEEE.numeric_std.all;    

entity cpu_TLB_data is
   port 
   (
      clk93                : in  std_logic;
      reset                : in  std_logic;
                           
      TLBInvalidate        : in  std_logic;
                           
      TLB_Req              : in  std_logic;
      TLB_IsWrite          : in  std_logic;
      TLB_AddrIn           : in  unsigned(63 downto 0);
      TLB_useCache         : out std_logic := '0';  
      TLB_Stall            : out std_logic := '0';
      TLB_UnStall          : out std_logic := '0';
      TLB_AddrOut          : out unsigned(31 downto 0) := (others => '0');
      
      TLB_ExcRead          : out std_logic := '0';
      TLB_ExcWrite         : out std_logic := '0';
      TLB_ExcDirty         : out std_logic := '0';
      TLB_ExcMiss          : out std_logic := '0';
      
      TLB_fetchReq         : out std_logic := '0';
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
      REQUEST,
      EXCEPTION
   );
   signal state : tstate := IDLE;
   
   signal TLB_fetchIsWrite  : std_logic := '0';
   
   signal mini_cached : std_logic := '0';

begin 

   TLB_Stall <= '1' when (TLB_Req = '1') else '0';
   
   TLB_useCache <= mini_cached;

   process (clk93)
   begin
      if (rising_edge(clk93)) then
      
         TLB_UnStall   <= '0';
         TLB_fetchReq  <= '0';
         
         TLB_ExcRead  <= '0';
         TLB_ExcWrite <= '0';
         TLB_ExcDirty <= '0';
         TLB_ExcMiss  <= '0';
         
         if (reset = '1') then
         
            state <= IDLE;
           
         else
         
            case (state) is
            
               when IDLE =>
                  TLB_fetchAddrIn  <= TLB_AddrIn;
                  TLB_fetchIsWrite <= TLB_IsWrite;
                  if (TLB_Req = '1') then
                     state            <= REQUEST;
                     TLB_fetchReq     <= '1';
                  end if;
                 
               when REQUEST =>
                  if (TLB_fetchDone = '1') then
                     if (TLB_fetchExcInvalid = '0' and TLB_fetchExcNotFound = '0' and (TLB_fetchExcDirty = '0' or TLB_fetchIsWrite = '0')) then
                        state         <= IDLE;
                        TLB_UnStall   <= '1';
                     else
                        state         <= EXCEPTION;
                     end if;
                     TLB_AddrOut  <= TLB_fetchAddrOut;
                     mini_cached  <= TLB_fetchCached;
                     TLB_ExcRead  <= (TLB_fetchExcInvalid or TLB_fetchExcNotFound) and (not TLB_fetchIsWrite);
                     TLB_ExcWrite <= (TLB_fetchExcInvalid or TLB_fetchExcNotFound) and TLB_fetchIsWrite;
                     TLB_ExcMiss  <= TLB_fetchExcNotFound;
                     if (TLB_fetchExcDirty = '1' and TLB_fetchIsWrite = '1') then
                        TLB_ExcDirty <= '1';
                        if (TLB_fetchExcInvalid = '0') then
                           TLB_ExcRead  <= '0';
                           TLB_ExcWrite <= '0';
                        end if;
                     end if;
                  end if;
            
               when EXCEPTION =>
                  state       <= IDLE;
                  TLB_UnStall <= '1';
            
            end case;

         end if;
      end if;
   end process;
   
end architecture;
