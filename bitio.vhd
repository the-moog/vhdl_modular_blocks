-------------------------------------------------------------------------------
--
--  Title      Modular VHDL peripheral
--             https://github.com/the-moog/vhdl_modular_blocks
--  File       bitio.vhd
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
@brief   MODULAR PERIPHERAL: An arbitrary IO register with direction control.
@details This is an example of a typical modular bus peripheral<BR>
		 Implements a bank of registered IO
		 Direction bits are 0 for input, 1 for output
		 <BR>
		 All peripherals have the same bus interface, but an atbitrary bus size
*/
entity bit_io is
  generic (npins : integer := 16;
          rst_value : std_logic_vector(npins - 1 downto 0) := (others => '0'));
  port (
    clk  : in std_logic;
    rst  : in std_logic;
    module : in module_t;
    addr : in std_logic_vector;
    data : inout std_logic_vector; --Sampled on the rising edge of clk
    io_pins : inout std_logic_vector(npins - 1 downto 0); 
    ip_data : out std_logic_vector(npins - 1 downto 0);
    size : out positive;
    cs : in std_logic;      --Module enable active high, sampled on the rising edge of clk
    rd_nwr : in std_logic); --Read/not Write
end entity;


/*!
@brief	  Typical implementation of a modular bus peripheral
@details  Note now the data bus and address bus are of arbitrary size
*/
architecture behavior of bit_io is


constant ZZZ : std_logic_vector(data'length - 1 downto 0) := (others => 'Z');
constant nbanks : integer := log2(npins / data'length);

signal dir_reg : logic_vector_array(0 to nbanks - 1)(data'range);
signal op_reg  : logic_vector_array(0 to nbanks - 1)(data'range);
signal ip_reg  : logic_vector_array(0 to nbanks - 1)(data'range);
signal rd_data : std_logic_vector(data'length - 1 downto 0);

constant sizei : positive := nbanks * 2;    --need to use an intermediate constant here to keep synplicity happy
constant addrbits : positive := log2(sizei);

begin

  data <= rd_data when rd_nwr = '1' and cs = '1' else ZZZ;

  size <= sizei;

  do_read : process (all) is
  variable address : unsigned(addrbits - 1 downto 0);
  variable bank : integer;
  begin
    address := unsigned(addr(address'range) and std_logic_vector(conv_unsigned(log2(nbanks), addrbits)));
    bank := conv_integer(unsigned(addr(address'range) srl log2(nbanks)));

    rd_data <= (others => '0');
    if bank < nbanks then
      case conv_integer(address) is
        when 0 =>
          rd_data <= dir_reg(bank);
        when 1 =>
          for pin in io_pins'range loop
            if dir_reg(bank)(pin) = '0' then
              rd_data(pin) <= ip_reg(bank)(pin);
            else
              rd_data(pin) <= op_reg(bank)(pin);
            end if;
          end loop;
        when others =>
          null;
      end case;
    end if;
  end process;

  do_write : process(clk, rst, addr, cs, data) is
  variable address : unsigned(addrbits - 1 downto 0);
  variable bank : integer;
  variable nbit : integer;
  begin
    address := unsigned(addr(address'range) and std_logic_vector(conv_unsigned(log2(nbanks), addrbits)));
    bank := conv_integer(unsigned(addr(address'range) srl log2(nbanks)));

    if rst = '1' then
      for pin in io_pins'range loop
        bank := pin / data'length;
        nbit := pin mod data'length;

        op_reg(bank)(nbit) <=  rst_value(pin);
        dir_reg(bank)(nbit) <= '0';
      end loop;
    elsif rising_edge(clk) then --Process regs on rising edge
      --Handle write
      if cs = '1' and bank < nbanks and rd_nwr = '0' then
        case conv_integer(address) is
          when 0 =>
            dir_reg(bank) <= data;
          when 1 =>
            op_reg(bank) <= data;
          when others =>
            null;
        end case;
      end if;
    end if;
  end process;

  do_io : process (clk, rst)
  variable bank : integer;
  variable nbit : integer;
  begin
    if rst = '1' then
      setall(io_pins, 'Z');
      for bank in 0 to nbanks - 1 loop
        ip_reg(bank)<= (others => '0');
      end loop;
    elsif falling_edge(clk) then --Process pins on falling
      --Map the register bit to a pin
      --Registers are numbered 15 downto 0
      --Pins are numbered 0 to N
      --Bit 0 (LSB/RHS) is mapped to output 0 (LHS), Bit 1 to output 1 etc.
      for pin in io_pins'range loop
        bank := pin / data'length;
        nbit := pin mod data'length;

        if dir_reg(bank)(nbit) = '1' then
          --Write pin
          io_pins(pin) <= op_reg(bank)(nbit);
        else
          --Read pin
          io_pins(pin) <= 'Z';
          ip_reg(bank)(nbit) <= io_pins(pin);
        end if;
      end loop;

    end if;
  end process;

  --combinatorial process to unwrap the register banks back into pins
  do_ipreg : process(ip_reg) 
  variable bank : integer;
  variable nbit : integer;
  begin       
      for pin in io_pins'range loop
        bank := pin / data'length;
        nbit := pin mod data'length;
        ip_data(pin) <= ip_reg(bank)(nbit);
      end loop;
  end process;
  
 

end architecture;
