-------------------------------------------------------------------------------
--
--  Title      Modular VHDL peripheral
--             https://github.com/the-moog/vhdl_modular_blocks
--  File       bitio_op.vhd
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
@brief   MODULAR PERIPHERAL: An arbitrary output register.
@details This is an example of a typical modular bus peripheral<BR>
		 Implements a bank of registered outputs
		 <BR>
		 All peripherals have the same bus interface, but an atbitrary bus size
*/
entity bitio_op is
  generic (npins : integer := 16;
          rst_value : std_logic_vector(npins - 1 downto 0) := (others => '0'));
  port (
    clk  : in std_logic;
    rst  : in std_logic;
    module : in module_t;
    addr : in std_logic_vector;
    data : inout std_logic_vector; --Sampled on the rising edge of clk
    op_pins : out std_logic_vector(npins - 1 downto 0);
    size : out positive;
    cs : in std_logic;      --Module enable active high, sampled on the rising edge of clk
    rd_nwr : in std_logic); --Read/not Write
end entity;

/*!
@brief	  Typical implementation of a modular bus peripheral
@details  Note now the data bus and address bus are of arbitrary size
*/
architecture behavior of bitio_op is

type std_lv_array is array (natural range <>) of std_logic_vector(data'range);

constant ZZZ : std_logic_vector(data'range) := (others => 'Z');
constant nbanks : integer := log2(npins / data'length);

signal op_reg  : std_lv_array(0 to nbanks - 1);
signal rd_data : std_logic_vector(data'range);

constant sizei : positive := nbanks;    --need to use an intermediate constant here to keep synplicity happy
constant addrbits : positive := log2(nbanks);

begin

  data <= rd_data when rd_nwr = '1' and cs = '1' else ZZZ;

  size <= sizei;

  do_read : process (all) is
  variable address : unsigned(addrbits - 1 downto 0);
  variable bank : integer;
  begin
    address := unsigned(addr(address'range)) - module.base;
    bank := conv_integer(address);

    rd_data <= (others => '0');
    case conv_integer(address) is
      when 0 =>
        rd_data <= op_reg(bank);   
      when others =>
        null;
    end case;
    
    
  end process;

  do_write : process(all) is
  variable address : unsigned(addrbits - 1 downto 0);
  variable bank : integer;
  variable nbit : integer; 
  begin
    address := unsigned(addr(address'range)) - module.base;

    if rst = '1' then
      for pin in op_pins'range loop
        bank := pin / data'length;
        nbit := pin mod data'length;
        op_reg(bank)(pin) <= rst_value(pin);
      end loop;
    elsif rising_edge(clk) then --Process regs on rising edge
      --Handle write
      bank := conv_integer(address);
      if cs = '1' and bank < nbanks and rd_nwr = '0' then
        op_reg(bank) <= data;
      end if;
    end if;
  end process;

  do_op : process (all)
  variable bank : integer;
  variable nbit : integer;
  begin
    for pin in op_pins'range loop
      --Map the register bit to a pin
      --Registers are numbered 15 downto 0
      --Pins are numbered 0 to N
      --Bit 0 (LSB/RHS) is mapped to output 0 (LHS), Bit 1 to output 1 etc.
      bank := pin / data'length;
      nbit := pin mod data'length;
      op_pins(pin) <= op_reg(bank)(nbit);
    end loop;
  end process;

end architecture;
