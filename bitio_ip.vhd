-------------------------------------------------------------------------------
--
--  Title      Modular VHDL peripheral
--             https://github.com/the-moog/vhdl_modular_blocks
--  File       bitio_ip.vhd
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
use work.utils.log2;     
use work.types.all;
use work.modules.all;

/*!
@brief   MODULAR PERIPHERAL: An arbitrary input register.
@details This is an example of a typical modular bus peripheral<BR>
		 Implements a bank of registered inputs
		 <BR>
		 All peripherals have the same bus interface, but an atbitrary bus size
*/
entity bitio_ip is
  generic (npins : integer := 16);
  port (
    clk  : in std_logic;
    rst  : in std_logic; 
    module : in module_t;
    addr : in std_logic_vector;
    data : inout std_logic_vector; --Sampled on the rising edge of clk
    ip_pins : in std_logic_vector(npins - 1 downto 0);
    ip_data : out std_logic_vector(npins - 1 downto 0);
    size : out positive;
    cs : in std_logic;      --Module enable active high, sampled on the rising edge of clk
    rd_nwr : in std_logic); --Read/not Write
end entity;


/*!
@brief	  Typical implementation of a modular bus peripheral
@details  Note now the data bus and address bus are of arbitrary size
*/
architecture behavior of bitio_ip is


constant ZZZ : std_logic_vector(data'range) := (others => 'Z');
constant nbanks : integer := log2(npins / data'length);

signal rd_data : std_logic_vector(data'range);

signal ip_reg  : logic_vector_array(0 to nbanks - 1)(data'range);

constant sizei : positive := nbanks;    --need to use an intermediate constant here to keep synplicity happy
constant addrbits : positive := log2(sizei);

begin

  data <= rd_data when rd_nwr = '1' and cs = '1' else ZZZ; 
  
  size <= sizei;                   

  do_read : process (all) is
  variable address : unsigned(addrbits - 1 downto 0);
  variable bank : integer;
  variable nbit : integer;
  begin
    address := unsigned(addr(address'range)) - module.base;
    bank := conv_integer(address);
    rd_data <= (others => '0');
    if bank < nbanks then
      rd_data <= ip_reg(bank);
    end if;
  end process;

  do_input : process(clk, rst, ip_pins)
  variable bank : integer;
  variable nbit : integer;
  begin
    if rst = '1' then
      for bank in 0 to nbanks - 1 loop
        ip_reg(bank) <= (others => '0');
      end loop;
    elsif falling_edge(clk) then --Process pins on falling
      for pin in ip_pins'range loop
        bank := pin / data'length;
        nbit := pin mod data'length;
        --Read pin
        --Map the register bit to a pin
        --Registers are numbered 15 downto 0
        --Pins are numbered 0 to N
        --Bit 0 (LSB/RHS) is mapped to output 0 (LHS), Bit 1 to output 1 etc.
        ip_reg(bank)(nbit) <= ip_pins(pin);
      end loop;
    end if;
  end process;
  
  --combinatorial process to unwrap the register banks back into pins
  do_ipreg : process(ip_reg) 
  variable bank : integer;
  variable nbit : integer;
  begin       
      for pin in ip_pins'range loop
        bank := pin / data'length;
        nbit := pin mod data'length;
        ip_data(pin) <= ip_reg(bank)(nbit);
      end loop;
  end process;
  
 
  
end architecture;