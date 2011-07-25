----------------------------------------------------------------------------------
-- Cylon Visor for the S3EBOARD
-- by Ricardo Bittencourt 2009
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity visor is
    Port ( CLK : in   STD_LOGIC;
           SW0 : in   STD_LOGIC;
           LED0: out  STD_LOGIC;
           LED1: out  STD_LOGIC;
           LED2: out  STD_LOGIC;
           LED3: out  STD_LOGIC;
           LED4: out  STD_LOGIC;
           LED5: out  STD_LOGIC;
           LED6: out  STD_LOGIC;
           LED7: out  STD_LOGIC
         );
end visor;

architecture visor_impl of visor is
  signal clk_counter : std_logic_vector(22 downto 0);
  signal state : std_logic_vector(3 downto 0);
  signal led_output : std_logic_vector(7 downto 0);
begin

  process(CLK, clk_counter)
  begin
    if (CLK'event and CLK='1') then
      if (clk_counter=5000000) then
        clk_counter <= (others => '0');
       else
        clk_counter <= clk_counter + 1;
      end if;
    end if;
  end process;
  
  process(CLK, SW0, state, clk_counter)
  begin
    if (CLK'event and CLK='1') then
      if (clk_counter=0) then
        if (SW0='0' or state=13) then
          state <= (others => '0');
        else
          state <= state + 1;
        end if;
      end if;
    end if;
  end process;
  
  process(state)
  begin
    if (state=0) then
      led_output <= "00000001";
    elsif (state=1) then
      led_output <= "00000010";
    elsif (state=2) then
      led_output <= "00000100";
    elsif (state=3) then
      led_output <= "00001000";
    elsif (state=4) then
      led_output <= "00010000";
    elsif (state=5) then
      led_output <= "00100000";
    elsif (state=6) then
      led_output <= "01000000";
    elsif (state=7) then
      led_output <= "10000000";
    elsif (state=8) then
      led_output <= "01000000";
    elsif (state=9) then
      led_output <= "00100000";
    elsif (state=10) then
      led_output <= "00010000";
    elsif (state=11) then
      led_output <= "00001000";
    elsif (state=12) then
      led_output <= "00000100";
    elsif (state=13) then
      led_output <= "00000010";
   else
     led_output <= "00000000";
   end if;
  end process;

  LED0 <= led_output(0);
  LED1 <= led_output(1);
  LED2 <= led_output(2);
  LED3 <= led_output(3);
  LED4 <= led_output(4);
  LED5 <= led_output(5);
  LED6 <= led_output(6);
  LED7 <= led_output(7);
  
end visor_impl;

