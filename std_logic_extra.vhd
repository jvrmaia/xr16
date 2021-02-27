--
-- functions to convert std_logic to/from character and
--           to convert std_logic_vector to/from string
--


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package std_logic_extra is
    function to_character(arg: std_logic) return character;
    function to_string(arg: std_logic_vector) return string;

end package;

package body std_logic_extra is

    function to_character(arg: std_logic) return character is
    begin
	    case arg is
		when '0' => return '0';
		when '1' => return '1';
		when 'L' => return 'L';
		when 'H' => return 'H';
		when 'X' => return 'X';
		when 'U' => return 'U';
		when '-' => return '-';
		when 'W' => return 'W';
		when 'Z' => return 'Z';
		when others => return '*';
		end case;
    end function to_character;

    function to_string(arg: std_logic_vector) return string IS
    variable S: string(1 TO arg'length) := (others=>'*');
    variable J: integer;
    begin
	    J := 1;
	    for I in arg'range  loop
		    S(J) := to_character(arg(I));
		    J := J + 1;
	    end loop;
	    return S;
    end function to_string;

end package body std_logic_extra;
