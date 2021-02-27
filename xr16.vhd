library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity xr16 is
	port (
		clk	:	in	std_logic;
		rst	:	in	std_logic
	);
end entity xr16;

architecture comportamental of xr16 is

------------------------------------------------------------------
--   REGISTER |                     USE                         --
------------------------------------------------------------------
--  	r0    | sempre zero                                     --
--      r1    | reservado para o assembler                      --
--	r2    | retorno do valor da funcao                      --
--     r3-r5  | argumentos da funcao                            --
--     r6-r9  | temporarios                                     --
--    r10-r12 | variaveis de registros                          --
--     r13    | apontador de pilha(sp)                          --
--     r14    | endereco de retorno de interrupcao              --
--     r15    | endereco de retorno                             --
------------------------------------------------------------------
type reg_file is array (0 to 15) of std_logic_vector(15 downto 0);
signal r : reg_file := (
	others => "0000000000000000"
	);

----------------------------------------------------------------------
--                           MEMORIA                                -- 
----------------------------------------------------------------------
type datamemory is array (0 to 65535) of std_logic_vector(7 downto 0); 
signal memory : datamemory := (
	"11010111",
	"11111111",--D7FF 	imm 7FF0
	"00101101",
	"00001110",--2D0E	addi r13,r0,-2
	"11000000",
	"00000001",--C001	call 0010
	"10100000",
	"00000000",--A000	jal r0,0(r0)
	"00000000",
	"00000000",--0000	add r0,r0,r0
	"00000000",
	"00000000",--0000	add r0,r0,r0
	"00000000",
	"00000000",--0000	add r0,r0,r0
	"00000000",
	"00000000",--0000	add r0,r0,r0
	"00101101",
	"11011010",--2DDA 	addi r13,r13,-6
	"10001010",
	"11010000",--8AD0 	sw r10,0(r13)
	"10001011",
	"11010010",--8BD2 	sw r11,2(r13)
	"10001100",
	"11010100",--8CD4 	sw r12,4(r13)
	"00101010",
	"00000001",--2A01 	addi r10,r0,1
	"00101100",
	"00000001",--2C01 	addi r12,r0,1
	"00101011",
	"00000001",--2B01 	addi r11,r0,1
	"10110000",
	"00000010",--B002 	br 0026
	"00001011",
	"10101100",--0BAC 	add r11,r10,r12
	"00001010",
	"11000000",--0AC0 	add r10,r12,r0
	"00001100",
	"10110000",--0CB0 	add r12,r11,r0
	"11011101",
	"10001111",--DD8F 	imm D8F0
	"00100000",
	"10110000",--20B0 	addi r0,r11,0
	"10111000",
	"11111001",--B8F9 	blt 0020
	"00000010",
	"10100000",--02A0 	add r2,r10,r0
	"01011010",
	"11010000",--5AD0 	lw r10,0(r13)
	"01011011",
	"11010010",--5BD2 	lw r11,2(r13)
	"01011100",
	"11010100",--5CD4 	lw r12,4(r13)
	"00101101",
	"11010110",--2DD6 	addi r13,r13,6
	"10100000",
	"11110000",--A0F0	jal r0,0(r15)
	others => "00000000"
	);

begin

	process(clk,rst)
	type	 interup	is	(true,false);
	variable has_imm_prefix					: interup;
	variable pc						: std_logic_vector(15 downto 0);
	variable inst, oper_d, oper_a, oper_b, aux_a, aux_b	: std_logic_vector(15 downto 0);
	variable op, d, a, b					: std_logic_vector(3  downto 0);
	variable immed, target					: std_logic_vector(15 downto 0);
	variable disp						: std_logic_vector(7  downto 0);
	variable imm_prefix					: std_logic_vector(11 downto 0);
	variable disp_ext, aux					: std_logic_vector(15 downto 0) := "0000000000000000";
	variable dois						: std_logic_vector(15 downto 0) := "0000000000000010";
	variable um						: std_logic_vector(15 downto 0) := "0000000000000001";
	begin
		if rst = '1' then
			pc := "0000000000000000";
			has_imm_prefix := false;
		elsif rising_edge(clk) then
			r(0) <= (others => '0');

			inst := memory(to_integer(unsigned(pc)))&memory(to_integer(unsigned(pc))+1);

			op := inst(15 downto 12);
			d  := inst(11 downto 8);
			a  := inst(7  downto 4);
			b  := inst(3  downto 0);
                                   
			report  CR & LF &
				"PC = " & integer'image(to_integer(unsigned(pc))) & CR & LF &
				"OP = " & integer'image(to_integer(unsigned(op))) & CR & LF &
				"d = "  & integer'image(to_integer(unsigned(d)))  & " " &
				"rd = " & integer'image(to_integer(unsigned(r(to_integer(unsigned(d))))))  & CR & LF &
				"a = "  & integer'image(to_integer(unsigned(a)))  & " " &
				"ra = " & integer'image(to_integer(unsigned(r(to_integer(unsigned(a)))))) & CR & LF &
				"b = "  & integer'image(to_integer(unsigned(b))) & " " &
				"rb = " & integer'image(to_integer(unsigned(r(to_integer(unsigned(b)))))) ;

			case op is
				-- add rd,ra,rb r[rd] = r[ra] + r[rb];
				when "0000" => 
					pc := std_logic_vector(unsigned(pc) + unsigned(dois));
					has_imm_prefix := false;
					oper_a := r(to_integer(unsigned(a)));
					oper_b := r(to_integer(unsigned(b)));
					r(to_integer(unsigned(d))) <= std_logic_vector(signed(oper_a) + signed(oper_b));
				-- addi rd,ra,imm r[rd] = r[ra] + immed; -- nao pode ser interrompida!!				
				when "0010" => 
					pc := std_logic_vector(unsigned(pc) + unsigned(dois));
					if (has_imm_prefix = true) then
						immed(15 downto 4):= imm_prefix;
						immed(3 downto 0):= b;
					else
						immed(15 downto 4) := (others => b(3));
						immed(3 downto 0) := b;
					end if;
					has_imm_prefix := false;
					oper_a := r(to_integer(unsigned(a)));
					oper_b := immed;
					r(to_integer(unsigned(d))) <= std_logic_vector(signed(oper_a) + signed(oper_b));						
				-- lw rd,imm(ra) r[rd] = load_word(r[ra] + immed);
				when "0101" => 
					pc := std_logic_vector(unsigned(pc) + unsigned(dois));
					if (has_imm_prefix = true) then
						immed(15 downto 4):= imm_prefix;
						immed(3 downto 0):= b;
					else
						immed(15 downto 5) := (others => '0');
						immed(4) := b(0);
						immed(3 downto 1) := b(3 downto 1);
						immed(0) := '0';
					end if;
					has_imm_prefix := false;
					aux_a := r(to_integer(unsigned(a)));
					r(to_integer(unsigned(d))) <= memory(to_integer(unsigned(aux_a) + unsigned(immed)))&memory(to_integer(unsigned(aux_a) + unsigned(immed) + unsigned(um)));
                                -- sw rd,imm(ra) store_word(r[rd], r[ra] + immed);
				when "1000" => 
					pc := std_logic_vector(unsigned(pc) + unsigned(dois));
					if (has_imm_prefix = true) then
						immed(15 downto 4):= imm_prefix;
						immed(3 downto 0):= b;
					else
						immed(15 downto 5) := (others => '0');
						immed(4) := b(0);
						immed(3 downto 1) := b(3 downto 1);
						immed(0) := '0';
					end if;
					has_imm_prefix := false;
					aux_a := r(to_integer(unsigned(a)));
					aux_b := r(to_integer(unsigned(d)));
					memory(to_integer(unsigned(aux_a)+unsigned(immed))) <= aux_b(15 downto 8);
					memory(to_integer(unsigned(aux_a)+unsigned(immed)+unsigned(um))) <= aux_b(7 downto 0);					
				-- jal rd,imm(ra) target = r[ra] + immed; r[rd] = pc; pc = target;
				when "1010" => 
					pc := std_logic_vector(unsigned(pc) + unsigned(dois));
					if (has_imm_prefix = true) then
						immed(15 downto 4):= imm_prefix;
						immed(3 downto 0):= b;
					else
						immed(15 downto 5) := (others => '0');
						immed(4) := b(0);
						immed(3 downto 1) := b(3 downto 1);
						immed(0) := '0';
					end if;
					has_imm_prefix := false;
					aux_a := r(to_integer(unsigned(a)));
					target := std_logic_vector(unsigned(aux_a)+unsigned(immed));
					target(0) := '0';
					r(to_integer(unsigned(d))) <= pc;
					pc := target;
				when "1011" =>
					case d is
					-- br label pc += 2×sign_ext(disp) + 2;
					when "0000" => 
						pc := std_logic_vector(unsigned(pc) + unsigned(dois));
						has_imm_prefix := false;
						disp := inst(7 downto 0);
						disp_ext(15 downto 8) := (others => disp(7));
						disp_ext(7 downto 0) := disp;
						disp_ext(15 downto 0) := disp_ext(14 downto 0) & '0';
						pc := std_logic_vector(unsigned(pc) + unsigned(disp_ext) + unsigned(dois));
                                        -- blt label if ((signed)<) pc += 2×sign_ext(disp) + 2;
					when "1000" => 
						pc := std_logic_vector(unsigned(pc) + unsigned(dois));
						has_imm_prefix := false;
						if to_integer(signed(oper_a)) < to_integer(signed (NOT(oper_b))) then
							disp := inst(7 downto 0);
							disp_ext(15 downto 8) := (others => disp(7));
							disp_ext(7 downto 0) := disp;
							disp_ext(15 downto 0) := disp_ext(14 downto 0) & '0';
							pc := std_logic_vector(unsigned(pc) + unsigned(disp_ext) + unsigned(dois));
						end if;			
					end case;
                                -- call function r[15] = pc; pc = imm1211:0 || 03:0;
				when "1100" => 
					pc := std_logic_vector(unsigned(pc) + unsigned(dois));
					has_imm_prefix := false;
					r(15) <= pc;
					pc := inst(11 downto 0) & "0000";
                                -- imm imm12 immed(next)15:4 = imm12;
				when "1101" => 
					pc := std_logic_vector(unsigned(pc) + unsigned(dois));
					has_imm_prefix := false;
					has_imm_prefix := true;
					imm_prefix := inst(11 downto 0);
			end case;
		end if;
	end process;

end architecture comportamental;

