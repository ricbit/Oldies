library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

-- Fudebium: Z80 clone
-- Author: Ricardo Bittencourt
-- Start: 2002.8.9
-- Last update: 2002.8.11

entity fudebium is
    port (
        ADDRESS: out   STD_LOGIC_VECTOR (15 downto 0);
        DATA:    inout STD_LOGIC_VECTOR (07 downto 0);
        DUMMYS:	 out   STD_LOGIC_VECTOR (07 downto 0);
        INT:	 in    STD_LOGIC;
        IORQ:	 out   STD_LOGIC;	
        M1:	 out   STD_LOGIC;
        MREQ:	 out   STD_LOGIC;
        RD:	 out   STD_LOGIC;
        RESET:	 in    STD_LOGIC;
        RFSH:	 out   STD_LOGIC;
        WR:	 out   STD_LOGIC;
        FLAGS:	 out   STD_LOGIC_VECTOR (07 downto 0);	
        CLK:     in    STD_LOGIC        
    );
end fudebium;

architecture fudebium_arch of fudebium is
signal mainfsm_in, mainfsm_out: std_logic_vector (03 downto 0);
signal refresh_in, refresh_out: std_logic;
signal rd_in, rd_out: 		std_logic;
signal wr_in, wr_out: 		std_logic;
signal mreq_in, mreq_out: 	std_logic;
signal m1_in, m1_out: 		std_logic;

signal opcode_in,opcode_out:  	 std_logic_vector (07 downto 0);
signal indirect_in,indirect_out: std_logic_vector (07 downto 0);
signal immed_in,immed_out:	 std_logic_vector (15 downto 0);
signal CB_in,CB_out:	 	 std_logic;

signal increment_PC: std_logic;

signal PC_in,PC_out:   std_logic_vector (15 downto 0);
signal SP_in,SP_out:   std_logic_vector (15 downto 0);
signal A_in,A_out:     std_logic_vector (07 downto 0);
signal B_in,B_out:     std_logic_vector (07 downto 0);
signal C_in,C_out:     std_logic_vector (07 downto 0);
signal D_in,D_out:     std_logic_vector (07 downto 0);
signal E_in,E_out:     std_logic_vector (07 downto 0);
signal F_in,F_out:     std_logic_vector (07 downto 0);
signal H_in,H_out:     std_logic_vector (07 downto 0);
signal L_in,L_out:     std_logic_vector (07 downto 0);
signal R_in,R_out:     std_logic_vector (07 downto 0);
signal I_in,I_out:     std_logic_vector (07 downto 0);

constant Cf: INTEGER := 0;
constant Nf: INTEGER := 1;
constant Pf: INTEGER := 2;
constant Hf: INTEGER := 4;
constant Zf: INTEGER := 6;
constant Sf: INTEGER := 7;

-- fake rom
signal fakeADDRESS: STD_LOGIC_VECTOR (15 downto 0);
signal fakeDATA:    STD_LOGIC_VECTOR (07 downto 0);

begin
  RFSH <= refresh_out;
  RD <= rd_out;
  ADDRESS <= fakeADDRESS;
  DUMMYS <= not D_out;
  M1 <= m1_out;  
  FLAGS <= F_out;
  MREQ <= mreq_out;
  WR <= wr_out;

  process (reset,fakeDATA)
  begin
    if (reset='0') then
      DATA <= (others => 'Z');
    else
      DATA <= fakeDATA;
    end if;
  end process;

  process (reset,clk)
  begin
    if (reset='0') then
      mainfsm_out <= (others => '0');
      PC_out <= (others => '0');
      SP_out <= (others => '1');
      refresh_out <= '1';
      rd_out <= '0';
      wr_out <= '0';
      mreq_out <= '0';
      m1_out <= '0';
      A_out <= (others => '1');
      B_out <= (others => '1');
      C_out <= (others => '1');
      D_out <= (others => '1');
      E_out <= (others => '1');
      F_out <= (others => '1');
      H_out <= (others => '1');
      L_out <= (others => '1');
      R_out <= (others => '0');
      I_out <= (others => '0');
      opcode_out <= (others => '0');
      indirect_out <= (others => '0');
      immed_out <= (others => '0');
      CB_out <= '0';
      
    elsif (clk'event and clk='1') then
      mainfsm_out <= mainfsm_in;
      PC_out <= PC_in;
      SP_out <= SP_in;
      refresh_out <= refresh_in;
      rd_out <= rd_in;
      wr_out <= wr_in;
      mreq_out <= mreq_in;
      m1_out <= m1_in;
      A_out <= A_in;
      B_out <= B_in;
      C_out <= C_in; 
      D_out <= D_in;
      E_out <= E_in;
      F_out <= F_in;
      H_out <= H_in;
      L_out <= L_in;
      R_out <= R_in;
      I_out <= I_in;
      opcode_out <= opcode_in;
      indirect_out <= indirect_in;
      immed_out <= immed_in;
      CB_out <= CB_in;

    end if;
  end process;

  process (fakeADDRESS)
  begin
    case fakeADDRESS is
      when "0000000000000000" => fakeDATA <= "11110011";
      when "0000000000000001" => fakeDATA <= "11000011";
      when "0000000000000010" => fakeDATA <= "11010111";
      when "0000000000000011" => fakeDATA <= "00000010";
      when "0000001011010111" => fakeDATA <= "00111110";
      when "0000001011011000" => fakeDATA <= "10000010";
      when "0000001011011001" => fakeDATA <= "11010011";
      when "0000001011011010" => fakeDATA <= "10101011";
      when "0000001011011011" => fakeDATA <= "10101111";
      when "0000001011011100" => fakeDATA <= "11010011";
      when "0000001011011101" => fakeDATA <= "10101000";
      when "0000001011011110" => fakeDATA <= "00111110";
      when "0000001011011111" => fakeDATA <= "01010000";
      when "0000001011100000" => fakeDATA <= "11010011";
      when "0000001011100001" => fakeDATA <= "10101010";
      when "0000001011100010" => fakeDATA <= "00010001";
      when "0000001011100011" => fakeDATA <= "11111111";
      when "0000001011100100" => fakeDATA <= "11111111";
      when "0000001011100101" => fakeDATA <= "10101111";
      when "0000001011100110" => fakeDATA <= "01001111";
      when "0000001011100111" => fakeDATA <= "11010011";
      when "0000001011101000" => fakeDATA <= "10101000";
      when "0000001011101001" => fakeDATA <= "11001011";
      when "0000001011101010" => fakeDATA <= "00100001";
      when "0000001011101011" => fakeDATA <= "00000110";
      when "0000001011101100" => fakeDATA <= "00000000";
      when "0000001011101101" => fakeDATA <= "00100001";
      when "0000001011101110" => fakeDATA <= "11111111";
      when "0000001011101111" => fakeDATA <= "11111111";
      when "0000001011110000" => fakeDATA <= "00110110";
      when "0000001011110001" => fakeDATA <= "11110000";
      when "0000001011110010" => fakeDATA <= "01111110";
      when "0000001011110011" => fakeDATA <= "11010110";
      when "0000001011110100" => fakeDATA <= "00001111";
      when "0000001011110101" => fakeDATA <= "00100000";
      when "0000001011110110" => fakeDATA <= "00001011";
      when "0000001011110111" => fakeDATA <= "01110111";
      when "0000001011111000" => fakeDATA <= "01111110";
      when "0000001011111001" => fakeDATA <= "00111100";
      when "0000001011111010" => fakeDATA <= "00100000";
      when "0000001011111011" => fakeDATA <= "00000110";
      when "0000001011111100" => fakeDATA <= "00000100";
      when "0000001011111101" => fakeDATA <= "11001011";
      when "0000001011111110" => fakeDATA <= "11000001";
      when "0000001011111111" => fakeDATA <= "00110010";
      when "0000001100000000" => fakeDATA <= "11111111";
      when "0000001100000001" => fakeDATA <= "11111111";
      when "0000001100000010" => fakeDATA <= "00100001";
      when "0000001100000011" => fakeDATA <= "00000000";
      when "0000001100000100" => fakeDATA <= "10111111";
      when "0000001100000101" => fakeDATA <= "01111110";
      when "0000001100000110" => fakeDATA <= "00101111";
      when "0000001100000111" => fakeDATA <= "01110111";
      when "0000001100001000" => fakeDATA <= "10111110";
      when "0000001100001001" => fakeDATA <= "00101111";
      when "0000001100001010" => fakeDATA <= "01110111";
      when "0000001100001011" => fakeDATA <= "00100000";
      when "0000001100001100" => fakeDATA <= "00000111";
      when "0000001100001101" => fakeDATA <= "00101100";
      when "0000001100001110" => fakeDATA <= "00100000";
      when "0000001100001111" => fakeDATA <= "11110101";
      when "0000001100010000" => fakeDATA <= "00100101";
      when "0000001100010001" => fakeDATA <= "11111010";
      when "0000001100010010" => fakeDATA <= "00000101";
      when "0000001100010011" => fakeDATA <= "00000011";
      when "0000001100010100" => fakeDATA <= "00101110";
      when "0000001100010101" => fakeDATA <= "00000000";
      when "0000001100010110" => fakeDATA <= "00100100";
      when "0000001100010111" => fakeDATA <= "01111101";
      when "0000001100011000" => fakeDATA <= "10010011";
      when "0000001100011001" => fakeDATA <= "01111100";
      when "0000001100011010" => fakeDATA <= "10011010";
      when "0000001100011011" => fakeDATA <= "00110000";
      when "0000001100011100" => fakeDATA <= "00001010";
      when "0000001100011101" => fakeDATA <= "11101011";
      when "0000001100011110" => fakeDATA <= "00111010";
      when "0000001100011111" => fakeDATA <= "11111111";
      when "0000001100100000" => fakeDATA <= "11111111";
      when "0000001100100001" => fakeDATA <= "00101111";
      when "0000001100100010" => fakeDATA <= "01101111";
      when "0000001100100011" => fakeDATA <= "11011011";
      when "0000001100100100" => fakeDATA <= "10101000";
      when "0000001100100101" => fakeDATA <= "01100111";
      when "0000001100100110" => fakeDATA <= "11111001";
      when "0000001100100111" => fakeDATA <= "01111000";
      when "0000001100101000" => fakeDATA <= "10100111";
      when "0000001100101001" => fakeDATA <= "00101000";
      when "0000001100101010" => fakeDATA <= "00001010";
      when "0000001100101011" => fakeDATA <= "00111010";
      when "0000001100101100" => fakeDATA <= "11111111";
      when "0000001100101101" => fakeDATA <= "11111111";
      when "0000001100101110" => fakeDATA <= "00101111";
      when "0000001100101111" => fakeDATA <= "11000110";
      when "0000001100110000" => fakeDATA <= "00010000";
      when "0000001100110001" => fakeDATA <= "11111110";
      when "0000001100110010" => fakeDATA <= "01000000";
      when "0000001100110011" => fakeDATA <= "00111000";
      when "0000001100110100" => fakeDATA <= "11001010";
      when "0000001100110101" => fakeDATA <= "11011011";
      when "0000001100110110" => fakeDATA <= "10101000";
      when "0000001100110111" => fakeDATA <= "11000110";
      when "0000001100111000" => fakeDATA <= "01010000";
      when "0000001100111001" => fakeDATA <= "00110000";
      when "0000001100111010" => fakeDATA <= "10101100";
      when "0000001100111011" => fakeDATA <= "00100001";
      when "0000001100111100" => fakeDATA <= "00000000";
      when "0000001100111101" => fakeDATA <= "00000000";
      when "0000001100111110" => fakeDATA <= "00111001";
      when "0000001100111111" => fakeDATA <= "01111100";
      when "0000001101000000" => fakeDATA <= "11010011";
      when "0000001101000001" => fakeDATA <= "10101000";
      when "0000001101000010" => fakeDATA <= "01111101";
      when "0000001101000011" => fakeDATA <= "00110010";
      when "0000001101000100" => fakeDATA <= "11111111";
      when "0000001101000101" => fakeDATA <= "11111111";
      when "0000001101000110" => fakeDATA <= "01111001";
      when "0000001101000111" => fakeDATA <= "00000111";
      when "0000001101001000" => fakeDATA <= "00000111";
      when "0000001101001001" => fakeDATA <= "00000111";
      when "0000001101001010" => fakeDATA <= "00000111";
      when "0000001101001011" => fakeDATA <= "01001111";
      when "0000001101001100" => fakeDATA <= "00010001";
      when "0000001101001101" => fakeDATA <= "11111111";
      when "0000001101001110" => fakeDATA <= "11111111";
      when "0000001101001111" => fakeDATA <= "11011011";
      when "0000001101010000" => fakeDATA <= "10101000";
      when "0000001101010001" => fakeDATA <= "11100110";
      when "0000001101010010" => fakeDATA <= "00111111";
      when "0000001101010011" => fakeDATA <= "11010011";
      when "0000001101010100" => fakeDATA <= "10101000";
      when "0000001101010101" => fakeDATA <= "00000110";
      when "0000001101010110" => fakeDATA <= "00000000";
      when "0000001101010111" => fakeDATA <= "11001011";
      when "0000001101011000" => fakeDATA <= "00000001";
      when "0000001101011001" => fakeDATA <= "00110000";
      when "0000001101011010" => fakeDATA <= "00001010";
      when "0000001101011011" => fakeDATA <= "00000100";
      when "0000001101011100" => fakeDATA <= "00111010";
      when "0000001101011101" => fakeDATA <= "11111111";
      when "0000001101011110" => fakeDATA <= "11111111";
      when "0000001101011111" => fakeDATA <= "00101111";
      when "0000001101100000" => fakeDATA <= "11100110";
      when "0000001101100001" => fakeDATA <= "00111111";
      when "0000001101100010" => fakeDATA <= "00110010";
      when "0000001101100011" => fakeDATA <= "11111111";
      when "0000001101100100" => fakeDATA <= "11111111";
      when "0000001101100101" => fakeDATA <= "00100001";
      when "0000001101100110" => fakeDATA <= "00000000";
      when "0000001101100111" => fakeDATA <= "11111110";
      when "0000001101101000" => fakeDATA <= "01111110";
      when "0000001101101001" => fakeDATA <= "00101111";
      when "0000001101101010" => fakeDATA <= "01110111";
      when "0000001101101011" => fakeDATA <= "10111110";
      when "0000001101101100" => fakeDATA <= "00101111";
      when "0000001101101101" => fakeDATA <= "01110111";
      when "0000001101101110" => fakeDATA <= "00100000";
      when "0000001101101111" => fakeDATA <= "00001001";
      when "0000001101110000" => fakeDATA <= "00101100";
      when "0000001101110001" => fakeDATA <= "00100000";
      when "0000001101110010" => fakeDATA <= "11110101";
      when "0000001101110011" => fakeDATA <= "00100101";
      when "0000001101110100" => fakeDATA <= "01111100";
      when "0000001101110101" => fakeDATA <= "11111110";
      when "0000001101110110" => fakeDATA <= "11000000";
      when "0000001101110111" => fakeDATA <= "00110000";
      when "0000001101111000" => fakeDATA <= "11101111";
      when "0000001101111001" => fakeDATA <= "00101110";
      when "0000001101111010" => fakeDATA <= "00000000";
      when "0000001101111011" => fakeDATA <= "00100100";
      when "0000001101111100" => fakeDATA <= "01111101";
      when "0000001101111101" => fakeDATA <= "10010011";
      when "0000001101111110" => fakeDATA <= "01111100";
      when "0000001101111111" => fakeDATA <= "10011010";
      when "0000001110000000" => fakeDATA <= "00110000";
      when "0000001110000001" => fakeDATA <= "00001010";
      when "0000001110000010" => fakeDATA <= "11101011";
      when "0000001110000011" => fakeDATA <= "00111010";
      when "0000001110000100" => fakeDATA <= "11111111";
      when "0000001110000101" => fakeDATA <= "11111111";
      when "0000001110000110" => fakeDATA <= "00101111";
      when "0000001110000111" => fakeDATA <= "01101111";
      when "0000001110001000" => fakeDATA <= "11011011";
      when "0000001110001001" => fakeDATA <= "10101000";
      when "0000001110001010" => fakeDATA <= "01100111";
      when "0000001110001011" => fakeDATA <= "11111001";
      when "0000001110001100" => fakeDATA <= "01111000";
      when "0000001110001101" => fakeDATA <= "10100111";
      when "0000001110001110" => fakeDATA <= "00101000";
      when "0000001110001111" => fakeDATA <= "00001000";
      when "0000001110010000" => fakeDATA <= "00111010";
      when "0000001110010001" => fakeDATA <= "11111111";
      when "0000001110010010" => fakeDATA <= "11111111";
      when "0000001110010011" => fakeDATA <= "00101111";
      when "0000001110010100" => fakeDATA <= "11000110";
      when "0000001110010101" => fakeDATA <= "01000000";
      when "0000001110010110" => fakeDATA <= "00110000";
      when "0000001110010111" => fakeDATA <= "11001010";
      when "0000001110011000" => fakeDATA <= "11011011";
      when "0000001110011001" => fakeDATA <= "10101000";
      when "0000001110011010" => fakeDATA <= "11000110";
      when "0000001110011011" => fakeDATA <= "01000000";
      when "0000001110011100" => fakeDATA <= "00110000";
      when "0000001110011101" => fakeDATA <= "10110101";
      when "0000001110011110" => fakeDATA <= "00100001";
      when "0000001110011111" => fakeDATA <= "00000000";
      when "0000001110100000" => fakeDATA <= "00000000";
      when "0000001110100001" => fakeDATA <= "00111001";
      when "0000001110100010" => fakeDATA <= "01111100";
      when "0000001110100011" => fakeDATA <= "11010011";
      when "0000001110100100" => fakeDATA <= "10101000";
      when "0000001110100101" => fakeDATA <= "01111101";
      when "0000001110100110" => fakeDATA <= "00110010";
      when "0000001110100111" => fakeDATA <= "11111111";
      when "0000001110101000" => fakeDATA <= "11111111";
      when "0000001110101001" => fakeDATA <= "01111001";
      when "0000001110101010" => fakeDATA <= "00000001";
      when "0000001110101011" => fakeDATA <= "01001001";
      when "0000001110101100" => fakeDATA <= "00001100";
      when "0000001110101101" => fakeDATA <= "00010001";
      when "0000001110101110" => fakeDATA <= "10000001";
      when "0000001110101111" => fakeDATA <= "11110011";
      when "0000001110110000" => fakeDATA <= "00100001";
      when "0000001110110001" => fakeDATA <= "10000000";
      when "0000001110110010" => fakeDATA <= "11110011";
      when "0000001110110011" => fakeDATA <= "00110110";
      when "0000001110110100" => fakeDATA <= "00000000";
      when "0000001110110101" => fakeDATA <= "11101101";
      when "0000001110110110" => fakeDATA <= "10110000";
      when "0000001110110111" => fakeDATA <= "01001111";
      when "0000001110111000" => fakeDATA <= "00000110";
      when "0000001110111001" => fakeDATA <= "00000100";
      when "0000001110111010" => fakeDATA <= "11000011";
      when "0000001110111011" => fakeDATA <= "10111110";
      when "0000001110111100" => fakeDATA <= "01111111";

      when "1111111111111111" => fakeDATA <= "01000001";

      when others             => fakeDATA <= "--------";
    end case;
  end process;

  process (mainfsm_out,refresh_out,m1_out,rd_out,R_out,I_out,PC_out,indirect_out,
  	   opcode_out,fakeDATA,immed_out,CB_out,H_out,L_out)
  begin 
    mainfsm_in <= mainfsm_out;
    refresh_in <= refresh_out;
    m1_in <= m1_out;
    rd_in <= rd_out;
    opcode_in <= opcode_out;
    fakeADDRESS <= (others => '0');
    immed_in <= immed_out;
    increment_PC <= '0'; 
    CB_in <= CB_out;
    indirect_in <= indirect_out;
    
    if (mainfsm_out="0000") then 
      -- just after reset
      mainfsm_in <= "0001";
      refresh_in <= '0';
      m1_in <= '0';
      rd_in <= '0';
      fakeADDRESS <= PC_out;
      opcode_in <= fakeDATA;
      CB_in <= '0';
      
    elsif (mainfsm_out="0001") then 
      -- refresh
      mainfsm_in <= "0010";
      refresh_in <= '1';      
      m1_in <= '1';
      rd_in <= '1';
      fakeADDRESS <= I_out & R_out;
      CB_in <= '0';
      increment_PC <= '1';
      
    elsif (mainfsm_out="0010") then 
      -- fetch
      refresh_in <= '1';
      rd_in <= '0';
      fakeADDRESS <= PC_out;
      opcode_in <= fakeDATA;
      if (fakeDATA="11001011") -- CB prefix
      then
        -- go to CB prefix
        mainfsm_in <= "0110";
        m1_in <= '0';
        increment_PC <= '1'; 
        CB_in <= '1';
      elsif (fakeDATA(7 downto 6) & fakeDATA(2 downto 0) = "01110") or -- LD r,(HL)        
            (fakeDATA = "10111110")				       -- CP (HL)
      then
        -- go to read indirect
        mainfsm_in <= "0111";
        m1_in <= '1';
      elsif (fakeDATA="11000011") or 				  -- JP dddd
         (fakeDATA(7 downto 6) & fakeDATA(3 downto 0) = "000001") -- LD rr,dddd
      then
        -- go to fetch imm16 high
        mainfsm_in <= "0011";
        m1_in <= '1';
        increment_PC <= '1';         
      elsif (fakeDATA(7 downto 6) & fakeDATA(2 downto 0) = "00110") or -- LD r,dd
            (fakeDATA = "11010011") or				       -- OUT (dd),A
            (fakeDATA = "11010110") or				       -- SUB dd
            (fakeDATA(7 downto 5) & fakeDATA(2 downto 0) = "001000")   -- JR cc,dd
      then
        -- go to fetch imm8 
        mainfsm_in <= "0101";
        m1_in <= '1';
        increment_PC <= '1'; 
      else  
        -- fetch opcode
        mainfsm_in <= "0001";
        m1_in <= '0';
      end if;

    elsif (mainfsm_out="0011") then 
      -- fetch imm16 load
      mainfsm_in <= "0100";
      refresh_in <= '1';      
      m1_in <= '1';
      rd_in <= '0';
      fakeADDRESS <= PC_out;
      immed_in(7 downto 0) <= fakeDATA;
      increment_PC <= '1'; 

    elsif (mainfsm_out="0100") then 
      -- fetch imm16 high
      mainfsm_in <= "0001";
      refresh_in <= '0';      
      m1_in <= '1';
      rd_in <= '0';
      fakeADDRESS <= PC_out;
      immed_in(15 downto 8) <= fakeDATA;

    elsif (mainfsm_out="0101") then 
      -- fetch imm8 load
      mainfsm_in <= "0001";
      refresh_in <= '0';      
      m1_in <= '1';
      rd_in <= '0';
      fakeADDRESS <= PC_out;
      immed_in(7 downto 0) <= fakeDATA;

    elsif (mainfsm_out="0110") then 
      -- fetch CB prefix
      mainfsm_in <= "0001";
      refresh_in <= '1';      
      m1_in <= '1';
      rd_in <= '0';
      fakeADDRESS <= PC_out;
      opcode_in <= fakeDATA;

    elsif (mainfsm_out="0111") then 
      -- read indirect
      mainfsm_in <= "0001";
      refresh_in <= '0';      
      m1_in <= '1';
      rd_in <= '0';
      fakeADDRESS <= H_out & L_out;
      indirect_in <= fakeDATA;

    end if;    
  end process;

  process (opcode_out,mainfsm_out,R_out,PC_out,immed_out,increment_PC,CB_out,indirect_out,
  	   A_out,B_out,C_out,D_out,E_out,H_out,L_out,SP_out,F_out)
  variable sign_extend:	       std_logic_vector (15 downto 0);
  variable rr_input,rr_output: std_logic_vector (15 downto 0);
  variable r_input,r_output:   std_logic_vector (07 downto 0);
  variable arith9:   	       std_logic_vector (08 downto 0);
  variable r_range:	       std_logic_vector (02 downto 0);	
  variable update_rr:	       std_logic;
  variable update_r:	       std_logic;
  variable parity:	       std_logic;	
  variable select_flag:	       std_logic; 	
  variable set_zero:	       std_logic;	
  variable set_parity:	       std_logic;	
  begin 
    R_in <= R_out;
    PC_in <= PC_out;
    A_in <= A_out;
    B_in <= B_out;
    C_in <= C_out;
    D_in <= D_out;
    E_in <= E_out;
    H_in <= H_out;
    L_in <= L_out;
    F_in <= F_out;
    SP_in <= SP_out;
    update_rr := '0';
    update_r := '0';
    rr_output := (others => '0');
    r_output := (others => '0');
    set_zero := '0';
    set_parity := '0';
    
    if (increment_PC = '1') then
      PC_in <= PC_out+1;        
    end if;

    if (mainfsm_out="0001") then 
      -- execute
      R_in(6 downto 0) <= R_out(6 downto 0)+1;
      case opcode_out(2 downto 0) is
        when "000"  => r_input := B_out;
        when "001"  => r_input := C_out;
        when "010"  => r_input := D_out;
        when "011"  => r_input := E_out;
        when "100"  => r_input := H_out;
        when "101"  => r_input := L_out;
        when "110"  => r_input := indirect_out;
        when "111"  => r_input := A_out;
        when others => null;
      end case;        
      case opcode_out(5 downto 4) is
        when "00"   => rr_input := B_out & C_out;
        when "01"   => rr_input := D_out & E_out;
        when "10"   => rr_input := H_out & L_out;
        when "11"   => rr_input := SP_out;
        when others => null;
      end case;  
      if (immed_out(7) = '1') then 
        sign_extend := "11111111" & immed_out(7 downto 0);
      else
        sign_extend := "00000000" & immed_out(7 downto 0);
      end if;  
      
      if (CB_out = '1') then
        if (opcode_out(7 downto 3) = "00100") then
          -- SLA r
	  -- doc flags complete
          r_output(7 downto 1) := r_input(6 downto 0);
          r_output(0) := '0';
          F_in(Cf) <= r_input(7);
          F_in(Sf) <= r_input(6); 
          F_in(Hf) <= '0';
          F_in(Nf) <= '0';
          set_zero := '1';
          set_parity := '1';
          update_r := '1';
        end if;
      else	      

        if (opcode_out="11000011") then 
  	  -- JP dddd
          PC_in <= immed_out;

	elsif (opcode_out="11010110" or (opcode_out(7 downto 3)="10010")) then 
	  -- SUB dd / SUB r
	  if (opcode_out="11010110") then
	    r_input := immed_out(7 downto 0); 
	  end if;  
	  arith9 := ("0" & A_out) - ("0" & r_input); 
	  r_output := arith9(7 downto 0);
	  A_in <= arith9(7 downto 0);
	  F_in(Nf) <= '1';
	  F_in(Cf) <= arith9(8);
	  set_zero := '1';
	  
	elsif (opcode_out(7 downto 3)="10011") then 
	  -- SBC A,r
	  arith9 := ("0" & A_out) - ("0" & r_input) - ("00000000" & F_out(Cf)); 
	  r_output := arith9(7 downto 0);
	  A_in <= arith9(7 downto 0);
	  F_in(Nf) <= '1';
	  F_in(Cf) <= arith9(8);
	  set_zero := '1';
	  
	elsif (opcode_out(7 downto 6) & opcode_out(2 downto 0) = "00100") then 
	  -- INC r	  
	  r_output := r_input + 1;
	  F_in(Nf) <= '0';
	  F_in(Sf) <= r_output(7);
	  set_zero := '1';
	  update_r := '1';
	  
	elsif (opcode_out(7 downto 3) = "10111") then 
	  -- CP r 
	  r_output := A_out - r_input; 
	  F_in(Nf) <= '1';
	  set_zero := '1';
	  
	elsif (opcode_out="00101111") then 
	  -- CPL
	  -- doc flags complete
	  r_output := not A_out;
	  A_in <= r_output;
	  F_in(Nf) <= '1';
	  F_in(Hf) <= '1';
	  
	elsif (opcode_out="11101011") then 
	  -- EX DE,HL
	  D_in <= H_out; E_in <= L_out;
	  H_in <= D_out; L_in <= E_out;	  
	  
	elsif (opcode_out(7 downto 5) & opcode_out(2 downto 0) = "001000") then
	  -- JR cc,dd
	  case opcode_out(4 downto 3) is 
	    when "00"   => select_flag := not F_out(Zf);
	    when "01"   => select_flag := F_out(Zf);
	    when "10"   => select_flag := not F_out(Cf);
	    when "11"   => select_flag := F_out(Zf);
	    when others => null;
	  end case;
	  if (select_flag = '1') then
	    PC_in <= PC_out + sign_extend + 1;
	  end if;  
	  
        elsif (opcode_out(7 downto 6) & opcode_out(3 downto 0) = "000001") then
          -- LD rr,dddd
          rr_output := immed_out;
          update_rr := '1';
      
        elsif (opcode_out(7 downto 3) = "10101") then
	  -- XOR r
	  -- doc flags complete
	  r_output := A_out xor r_input;
	  set_parity := '1';
	  set_zero := '1';
          A_in <= r_output;
          F_in(Cf) <= '0';
          F_in(Nf) <= '0';
          F_in(Hf) <= '0';
          F_in(Sf) <= r_output(7);
        
        elsif (opcode_out(7 downto 6) & opcode_out(2 downto 0) = "00110") then
	  -- LD r,dd
	  update_r := '1';
          r_output := immed_out(7 downto 0);
        
        elsif (opcode_out(7 downto 6)="01") then 
          -- LD r,r
          update_r := '1';
	  r_output := r_input;
        
        elsif (opcode_out(7 downto 6) & opcode_out(3 downto 0)="000111") then 
          -- INC rr
          update_rr := '1';
          rr_output := rr_input+1;
      
        elsif (opcode_out(7 downto 6) & opcode_out(3 downto 0)="001011") then 
          -- DEC rr
          update_rr := '1';
          rr_output := rr_input-1;
        
        end if;
      end if;  

      if (set_parity = '1') then
        parity := '1';
        for I in 0 to 7 loop
          parity := parity xor r_output(I);
        end loop;  
          F_in(Pf) <= parity;
      end if;
 
      if (set_zero = '1') then
        if (r_output = "00000000") then 
          F_in(Zf) <= '1';
        else  
          F_in(Zf) <= '0';
        end if;  
      end if;
      
      if (update_rr = '1') then
        case opcode_out(5 downto 4) is
          when "00"   => B_in <= rr_output(15 downto 8); C_in <= rr_output(7 downto 0); 
          when "01"   => D_in <= rr_output(15 downto 8); E_in <= rr_output(7 downto 0); 
          when "10"   => H_in <= rr_output(15 downto 8); L_in <= rr_output(7 downto 0); 
          when "11"   => SP_in <= rr_output;
          when others => null; 
        end case; 
      end if;
      
      if (update_r = '1') then
        if (CB_out = '0') then
          r_range := opcode_out(5 downto 3);
        else
          r_range := opcode_out(2 downto 0);
	end if;            
	
        case r_range is
          when "000"  => B_in <= r_output;
          when "001"  => C_in <= r_output;
          when "010"  => D_in <= r_output;
          when "011"  => E_in <= r_output;
          when "100"  => H_in <= r_output;
          when "101"  => L_in <= r_output;
          when "110"  => null; --indirect_in <= r_output;
          when "111"  => A_in <= r_output;
          when others => null;
        end case;        
      end if;  

    end if;
  end process;


end fudebium_arch;

