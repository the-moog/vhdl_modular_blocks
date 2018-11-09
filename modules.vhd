-------------------------------------------------------------------------------
--
--  Title      Modular VHDL peripheral
--             https://github.com/the-moog/vhdl_modular_blocks
--  File       modules.vhd
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
use work.utils.all;
use work.types.all;

--pragma translate_off
use STD.TEXTIO.all; 
--pragma translate_on

--! @brief    A modular approach to building an internal bus structure
--! @details  The modular approach handles the memory map automatically.<BR>
--!           NOTE: Some code is usually non-synthesizable and for test bench use only.
package modules is
  
  --! @brief  A structure to hold details about the module to save lots of signal passing
  type module_t is record 
    --pragma translate_off
    name : string( 1 to 20);
    --pragma translate_on
    BASE : integer;
    SIZE : integer;
    sixteen_bit : boolean;
  end record;     
  
  --pragma translate_off
  
  --The memory map is not synthesizable
  type memory_map_t;
  type memory_map_ptr is access memory_map_t; 
  
  --! @brief An access type is a dynamicly allocated instance of a type
  type module_ptr is access module_t;
  
  --! @brief a helper for creating memory maps
  type memory_map_t is record
    module : module_ptr;
    next_entry : memory_map_ptr;
  end record;
  
  --pragma translate_on
  
  --! @brief  Used to instantiate the module in the target
  impure function create_module(constant name: string; constant prev_module : module_t; signal size : positive; constant sixteen_bit : boolean := False) return module_t;

  --pragma translate_off   
  
  --Memory map functions are no use inside the target hardware
  --! @brief  Print out the memory map
  procedure print_memorymap;
  
  --! @brief Returns the module details as a string
  impure function str_module(constant module : module_t) return string;
  
  --! @brief Returns the module base address as an integer
  impure function get_module_base(module_name : string) return integer; 
  
  --! @brief Returns the module memory map as C header file text
  impure function c_str_module(constant module : module_t) return string;
  
  --! @prints out the C style memory map
  procedure print_c_map; 
  
  --! @Saves the C header file text to a file
  procedure write_c_header(filename : string);

  --pragma translate_on
  
  
	component testreg is
	  port (
		clk  : in std_logic;
		rst  : in std_logic; 
		module : in module_t;
		addr : in std_logic_vector;
		data : inout std_logic_vector; --Sampled on the rising edge of clk
		size : out positive;
		cs : in std_logic;      --Module enable active high, sampled on the rising edge of clk
		rd_nwr : in std_logic); --Read/not Write
	end component;
	
	component bit_io is
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
	end component;


	component bitio_op is
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
	end component;

	component bitio_ip is
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
	end component; 

end package;

package body modules is 
  
  --pragma translate_off
  variable memory_map : memory_map_ptr := new memory_map_t;
  --pragma translate_on

  
  impure function create_module(constant name: string; constant prev_module : module_t; signal size : positive; constant sixteen_bit : boolean := False) return module_t is
  variable module : module_t;
  variable base_binary : std_logic_vector(15 downto 0); 
  --pragma translate_off 
  variable entry : memory_map_ptr := memory_map;
  variable text : line;
  --pragma translate_on
  begin 
    --pragma translate_off
    module.name := ucase(pads(name, module_t.name'length));
    --pragma translate_on
    
    module.base := prev_module.base + prev_module.size;
    module.size := size; 
    module.sixteen_bit := sixteen_bit;
    
    --pragma translate_off                                                           
    --this code is no use during synthisis but it allows us to generate a useful memory map during simulation
      
    if memory_map = null then
      memory_map := new memory_map_t;
    end if;
    
    entry := memory_map;
    
    --Entry points to the start of the map, if it's empty populate it       
    if entry.next_entry = null and entry.module = null then
      entry.module := new module_t'(prev_module);
    end if;
    
    --Find the head entry in the map
    --Or the entry that has a higher address
    entry := memory_map;
    find_head : while entry.next_entry /= null and entry.module /= null and entry.module.name /= module.name loop
        entry := entry.next_entry;                      
    end loop; 
    
    if entry.module.name /= module.name then
      --Add the new entry to the map
      entry.next_entry := new memory_map_t;
      entry := entry.next_entry;
      entry.module := new module_t'(module);
      --write(output, "Creating " & str_module(module));
    else
      --Update an existing entry
      entry.module := new module_t'(module);
      --write(output, "Updating " & str_module(module));
    end if;  
    
    --pragma translate_on

    return module;
  end function;  
  
  
  --pragma translate_off
  impure function get_module_base(module_name : string) return integer is
  variable entry : memory_map_ptr;
  variable module_name_i : string(module_t.name'range) :=  ucase(pads(module_name, module_t.name'length));
  begin 
    entry := memory_map;
    scanmap : loop
      exit scanmap when entry = null;
      exit scanmap when entry.module.name = module_name_i;
      entry := entry.next_entry;
    end loop;                                                                
    if entry=null then
      report "Unknown module: " & module_name severity failure;
      return -1;
    else
      return entry.module.base;
    end if;
  end function;
  --pragma translate_on
  
  
  --pragma translate_off 
  procedure print_memorymap is
  variable entry : memory_map_ptr := memory_map;
  begin 
    scanmap : loop
      write(output, str_module(entry.module.all));
      exit scanmap when entry.next_entry = null;
      entry := entry.next_entry;
    end loop;
  end procedure;    
  
  impure function str_module(constant module : module_t) return string is
  variable base_binary : std_logic_vector(15 downto 0);
  begin
    base_binary := std_logic_vector(conv_unsigned(module.base, base_binary'length));
    return "Module: " & module.name & " (size: " & integer'image(module.size) & ") 0x" & to_hstring(base_binary);
  end function;
  
  
  
  impure function c_str_module(constant module : module_t) return string is    
    variable base_binary : std_logic_vector(15 downto 0); 
  
    function get_c_name(name : string) return string is
     variable ret : integer;
    begin                              
      find_last_non_space : for n in name'reverse_range loop
        ret := n;
        exit find_last_non_space when name(n) /= ' '; 
      end loop;
      return "CPLD_SPI_" & str_simplify(str_replace_char(name(1 to ret), ' ', '_'));
    end function;
  
  begin
    base_binary := std_logic_vector(conv_unsigned(module.base, base_binary'length));
    return "#DEFINE " & pads(get_c_name(module.name), 25) & " 0x" & to_hstring(base_binary);
  end function;  
  
  procedure print_c_map is
  variable entry : memory_map_ptr := memory_map; 
  variable text : line;
  begin           
    write(text, CR & LF);
    scanmap : loop
      write(text, c_str_module(entry.module.all) & CR & LF);
      exit scanmap when entry.next_entry = null;
      entry := entry.next_entry;
    end loop;   
    writeline(output, text);
  end procedure;      
  
  procedure write_c_header(filename : string) is
  file header : std.textio.text;
  variable entry : memory_map_ptr := memory_map; 
  variable op : line;
  begin                   
    file_open(header, filename, write_mode);
    write(op, "#ifdef CPLD_SPI_MAP_H" & CR & LF);
    write(op, "#DEFINE CPLD_SPI_MAP_H" & CR & LF);
    scanmap : loop
      write(op, c_str_module(entry.module.all) & CR & LF);
      exit scanmap when entry.next_entry = null;
      entry := entry.next_entry;
    end loop;       
    write(op, "#endif" & CR & LF);
    writeline(header, op);
  end procedure;  
 
  --pragma translate_on
  
end package body;