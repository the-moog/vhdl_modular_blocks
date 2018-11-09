-------------------------------------------------------------------------------
--
--  Title      Modular VHDL peripheral
--             https://github.com/the-moog/vhdl_modular_blocks
--  File       utils.vhd
--  Author     Jason Morgan
--
--  Copyright  © Jason Morgan 2018
--  License    This work is licensed under a Creative Commons Attribution-NoDerivatives 4.0 International License.
--             CC-BY-ND, see LICENSE.TXT
--
-------------------------------------------------------------------------------
--
--  Date       17/7/2018
--  Version    2
--
--  ChangeLog
--  =========
--  Version	   By 				Date 		Change
-- 
--  1		   J A Morgan       2009        Initial version
--  2		   J A Morgan		17/7/18		Updated to VHDL2008
--
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;     

--! @brief Globally used type definitions
package types is


  subtype bus8 is std_logic_vector(7 downto 0);
  subtype bus16 is std_logic_vector(15 downto 0);
  subtype bus32 is std_logic_vector(31 downto 0);
  subtype bus25 is std_logic_vector(24 downto 0);
  type memory8 is array (natural range <>) of bus8;
  type memory16 is array (natural range <>) of bus16;
  type memory32 is array (natural range <>) of bus32;
  
  type logic_vector_array is array (natural range <>) of std_logic_vector;               

  type txt is array (natural range <>) of character;

end package;

package body types is 
 
end package body;