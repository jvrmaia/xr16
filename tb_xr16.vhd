library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_xr16 is
end tb_xr16;

architecture comportamental of tb_xr16 is
component xr16
	port(
		CLK : in std_logic;
		RST : in std_logic 
	);
end component;
constant	PERIOD	: time := 10 ns;
signal		W_CLK	: std_logic := '0';
signal		W_CLKEN	: std_logic := '1';
signal		W_RST	: std_logic;
begin
	DUT : xr16
	port map (
		CLK => W_CLK,
		RST => W_RST
	);

	W_CLK <= W_CLKEN and not W_CLK after PERIOD/2;

	simulacao : process
	begin
		W_RST	<= '1';
		wait until W_CLK = '1';
		wait until W_CLK = '0';
		W_RST	<= '0';
		wait for 20*PERIOD; --150
		W_CLKEN <= '0';
		wait;      
	end process simulacao;
end comportamental;

configuration cfg_tb_xr16 of tb_xr16 is
	for comportamental
	end for;
end cfg_tb_xr16;

