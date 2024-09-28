----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09/21/2024 12:27:46 PM
-- Design Name: 
-- Module Name: mmcm_12m_14m - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity mmcm_12m_14m is
    Port ( clk_in1 : in STD_LOGIC;
           reset : in STD_LOGIC;
           locked : out STD_LOGIC;
           clk_12m : out STD_LOGIC;
           clk_14m : out STD_LOGIC);
end mmcm_12m_14m;

architecture RTL of mmcm_12m_14m is

-- The following code must appear in the VHDL architecture header:
------------- Begin Cut here for COMPONENT Declaration ------ COMP_TAG
component clk_wiz_0
port
 (-- Clock in ports
  -- Clock out ports
  clk_out1          : out    std_logic;
  clk_out2          : out    std_logic;
  -- Status and control signals
  reset             : in     std_logic;
  locked            : out    std_logic;
  clk_in1           : in     std_logic
 );
end component;

-- COMP_TAG_END ------ End COMPONENT Declaration ------------

begin

-- The following code must appear in the VHDL architecture
-- body. Substitute your own instance name and net names.
------------- Begin Cut here for INSTANTIATION Template ----- INST_TAG
u_clk_wiz_0 : clk_wiz_0
   port map ( 
  -- Clock out ports  
   clk_out1 => clk_12m, -- clk_out1,
   clk_out2 => clk_14m, -- clk_out2,
  -- Status and control signals                
   reset => reset,
   locked => locked,
   -- Clock in ports
   clk_in1 => clk_in1
 );
-- INST_TAG_END ------ End INSTANTIATION Template ------------

end RTL;
