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
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;

/*!
 @brief    A random collection of useful procedures and functions
*/
package utils is

  --! @brief Return the number of logic 1 values in a given std_logic_vector
  function count_ones(x : std_logic_vector) return integer;
  
  --! @brief Return the base 2 log of a given integer
  function log2(v: in integer) return natural;
  
  --! @brief Return the ordinal position of the first logic 1 in a std_logic_vector, -1 if no bits are set
  function first_one(x : std_logic_vector) return integer;
  
--  function "sll"(x : unsigned; y : integer) return unsigned;

  --! @brief Return a std_logic representation of a boolean value
  function to_std_logic(x : boolean) return std_logic;
  
  --! @brief Set all the bits of a std_logic_vector to a given value, e.g. 0, 1, Z, etc
  procedure setall(signal   x : out std_logic_vector; constant v : std_logic := '0');
  
  --! @brief Retrun the N'th nibble (4 bits) of a std_logic_vector as a hex digit in ASCII
  function to_hex(v : std_logic_vector; nibble : integer) return character;
  
  --! @brief Return a std_logic_vector representation of the ASCII position of a character
  function char2byte(c : in character) return std_logic_vector;
  
  --! @brief Convert a string into an arbitrary length std_logic_vector of string'length * 8
  procedure str2bitstring(s : string; signal v : out std_logic_vector);
  
  --! @brief Return the bits of a standard logic vector in reverse order
  function reverse(x : std_logic_vector) return std_logic_vector;
  
  --! @brief Convert a boolean type to a std_logic zero or one
  pure function to_01(constant x: boolean) return std_logic;
  
  --! @brief Return the maximum of two integers
  pure function max(constant x: integer; constant y: integer) return integer; 
  
  --! @brief Return the minimum of two integers
  pure function min(constant x: integer; constant y: integer) return integer;  
  
  --! @brief Return a new string with all the characters of the supplied string in upper case
  function ucase(v : string) return string;
  
  --! @brief Return a new string with all the characters of the supplied string in lower case
  function lcase(v : string) return string; 
  
  --! @brief Return the supplied character mapped to upper case
  function ucase(c : character) return character;
  
  --! @brief Return the supplied character mapped to lower case
  function lcase(c : character) return character;
  
  --! @brief Pad a short string to n characters length with a given character
  function pads(constant s : string; length : positive; padchar:character:=' ') return string;
  
  --! @brief Returns a new string with a given character replaced
  function str_replace_char(constant s : string; constant find : character; constant replace : character) return string;  
  
  --! @brief Limit strings to 0..9 and A..Z with underscore
  function str_simplify(constant s : string) return string;
end package;


package body utils is  
  
  function pads(constant s : string; length : positive; padchar:character:=' ') return string is
  variable temp : string(1 to length);
  begin 
    if length > s'length then
      temp(1 to s'length) := s;
      temp(s'length + 1 to length) := (others => padchar);
    else
      temp := s(1 to length);
    end if;
    return temp;
  end function;
  
  function str_replace_char(constant s : string; constant find : character; constant replace : character) return string is
   variable temp : string(s'range);
  begin                           
    for n in s'range loop
      if s(n) /= find then
        temp(n) := s(n);
      else
        temp(n) := replace;
      end if;
    end loop;
    return temp;
  end function;           
  
  function str_simplify(constant s : string) return string is
    variable temp : string(s'range);           
    variable us : unsigned(7 downto 0);
  begin        
    for n in temp'range loop 
      temp(n) := ucase(s(n));
      us := conv_unsigned(character'pos(temp(n)), us'length); 
      if not ((us >= character'pos('A') and us <= character'pos('Z')) or
        us = character'pos('_') or
        (us >= character'pos('0') and us <= character'pos('9'))) then
        temp(n) := '_';
      end if;
    end loop;
    return temp;
  end function;

  
  pure function max(constant x: integer; constant y: integer) return integer is
  begin
    if x >= y then
      return x;
    else
      return y;
    end if;
  end function;		

  pure function min(constant x: integer; constant y: integer) return integer is
  begin
    if x <= y then
      return x;
    else
      return y;
    end if;
  end function;


  --Set all of the bits of a signal to a bit value, e.g. '0', '1', 'Z'
  procedure  setall(signal x : out std_logic_vector; constant v : std_logic := '0') is
	begin
	  for i in x'range loop
	    x(i) <= v;
	  end loop;
	end procedure;

  function to_std_logic(x : boolean) return std_logic is
  begin
    if x then
     return '1';
    else
     return '0';
    end if;
  end function;

  --Shift left logical
--  function "sll"(x : unsigned; y : integer) return unsigned is
--  variable xx : std_logic_vector(x'length-1 downto 0) := std_logic_vector(x);
--  begin
--    return unsigned(xx sll y);
--  end function;

  --Function to count the number of ones in a std_logic_vector
  function count_ones(x : std_logic_vector) return integer is
    variable count : integer := 0;
    variable v : unsigned(0 downto 0);
    variable b : std_logic_vector(0 downto 0);
  begin

    for n in x'range loop
      b(0) := x(n);
      if b = "1" then
        v := "1";
      else
        v := "0";
      end if;
      --v := unsigned(b);
      count := count + conv_integer(v);
    end loop;

    return count;

  end function;			  
  
  --Function to get the base 2 log of a number
  function log2(v: in integer) return natural is
		variable n: natural;
		variable logn: natural;
	begin
		n := 1;
		for i in 0 to 128 loop
			logn := i;
			exit when (n >= abs(v));
			n := n * 2;
		end loop;
		return logn + 1;
	end function log2;


  --Return the index of the first one bit in a bit array
  --If no bit is set, result is negative
  function first_one(x : std_logic_vector) return integer is
  begin
    for i in x'low to x'high loop
      if x(i) = '1' then
        return i;
      end if;
    end loop;
    return -1;
  end function; 
  
  
  function ucase(v : string) return string is
  variable temp : string(v'range);
  begin
    for n in temp'range loop      
      temp(n) := ucase(v(n));
    end loop;
    return temp;
  end function; 
  
  function lcase(v : string) return string is
  variable temp : string(v'range);
  begin
    for n in temp'range loop
      temp(n) := lcase(v(n));
    end loop;
    return temp;
  end function;   
  
  function ucase(c : character) return character is
  variable temp : character;
  variable us : unsigned(7 downto 0);
  begin
    us := conv_unsigned(character'pos(c), us'length); 
    if us >= character'pos('a') and us <= character'pos('z') then
      temp := character'val(conv_integer(unsigned(std_logic_vector(us) and not x"20")));
    else
      temp := c;
    end if;

    return temp;
  end function; 
  
  function lcase(c : character) return character is
  variable temp : character;
  variable us : unsigned(7 downto 0);
  begin
    us := conv_unsigned(character'pos(c), us'length); 
    if us >= character'pos('A') and us <= character'pos('Z') then
      temp := character'val(conv_integer(unsigned(std_logic_vector(us) or x"20")));
    else
      temp := c;
    end if;

    return temp;
  end function; 

  --Convert a nibble of a std_logic_vector to a hex digit
  function to_hex(v : std_logic_vector; nibble : integer) return character is
  variable bcd : unsigned(3 downto 0);
  variable len : integer := ((v'length / 4) + 1) * 4;
  variable extend : std_logic_vector(0 to len - 1);
  begin
    extend := ext(v, len);
    bcd := unsigned(extend(nibble to nibble+3));
    if bcd < 10 then
      return character'val(conv_integer(bcd) + character'pos('0'));
    else
      return character'val(conv_integer(bcd) + character'pos('A'));
    end if;
  end function;

  --Convert a character to a std_logic_vector (ASCII encoded)
  function char2byte(c : in character) return std_logic_vector is
  begin
    return std_logic_vector(conv_unsigned(character'pos(c), 8));
  end function;

  --Convert a string of characters into a string of bits (ASCII encoded)
  procedure str2bitstring(s : string; signal v : out std_logic_vector) is
  variable temp : std_logic_vector(7 downto 0);
  variable count : integer := 0;
  begin
    for n in s'low to s'high loop
      temp := std_logic_vector(conv_unsigned(character'pos(s(n)), temp'length));
      v((count * 8) + 7 downto (count * 8)) <= temp;
      count := count + 1;
    end loop;
  end procedure;

  --Take a std_logic_vector and reverse it's order
  function reverse(x : std_logic_vector) return std_logic_vector is
  variable ret : std_logic_vector(x'range);
  begin
    for n in x'range loop
      ret(ret'high - n + ret'low) := x(n);
    end loop;
    return ret;
  end function;

  pure function to_01(constant x: boolean) return std_logic is
  begin
    if x then
      return '1';
    else
      return '0';
    end if;
  end function;   


end package body;
