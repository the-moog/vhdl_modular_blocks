-------------------------------------------------------------------------------
--
--  Title      Modular VHDL peripheral
--             https://github.com/the-moog/vhdl_modular_blocks
--  File       testreg.vhd
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
use IEEE.STD_lOGIC_ARITH.all;
use work.utils.setall;  
use work.utils.str2bitstring;
use work.utils.log2;    
use work.types.all;    
use work.modules.all;

/*!
@brief   MODULAR PERIPHERAL: A simple register for test purposes.
@details This is an example of a typical modular bus peripheral<BR>
		 This has two registers, the first is read only and returns<BR>
		 a fixed 16 bit value<BR>
		 The second is read/write and simply remembers what is written<BR>
		 so that it can be read back later.<BR>
		 <BR>
		 All peripherals have the same bus interface, but an atbitrary bus size
*/
entity testreg is
  port (                  
    clk  : in std_logic;			--! Module clock
    rst  : in std_logic; 			--! Reset, active high
    module : in module_t;			--! Structure to handle the modular bus
    addr : in std_logic_vector;		--! Address bus
    data : inout std_logic_vector;	--! Data bus, sampled on the rising edge of clk
    size : out positive;			--! An output that indicates the size of the used address space
    cs : in std_logic;				--! Module enable active high, sampled on the rising edge of clk
    rd_nwr : in std_logic);			--! Read (high) / Write (low)
end entity;

/*!
@brief	  Typical implementation of a modular bus peripheral
@details  Note now the data bus and address bus are of arbitrary size
*/
architecture behavior of testreg is

constant ZZZ : std_logic_vector(data'length - 1 downto 0) := (others => 'Z');       

signal rd_data : std_logic_vector(data'range);
signal rw_reg  : std_logic_vector(data'range);
signal id_reg : std_logic_vector(data'range);

constant id : string := "TR";  

constant sizei : positive := 2; --need to use an intermediate constant here to keep synplicity happy
constant addrbits : positive := log2(sizei - 1);    
begin                                                       
  
  str2bitstring(id, id_reg);
  
  data <= rd_data when rd_nwr = '1' and cs = '1' else ZZZ;      
  
  size <= sizei;
  
  do_read : process (all) is
  variable address : unsigned(addrbits - 1 downto 0);
  begin                                 
    address := unsigned(addr(address'range)) - module.base;
    rd_data <= (others => '0');
    case conv_integer(address) is
      when 0 =>
        rd_data <= id_reg;
      when 1 =>
        rd_data <= rw_reg;
      when others =>
        null;
    end case;
  end process;
  
  do_write : process(clk, rst, addr, cs, rd_nwr, data) is
  variable address : unsigned(addrbits - 1 downto 0);
  begin 
    address := unsigned(addr(address'range)) - module.base;
    if rst = '1' then
      rw_reg <= (others => '0');
    elsif rising_edge(clk) then --Process regs on rising edge
      --Handle write
      if cs = '1' and rd_nwr = '0' and conv_integer(address) = 1 then
        rw_reg <= data;
      end if;
    end if;    
  end process;  
  
end architecture;
    
    
    
    