--------------------------------------------------
--  FPGA Pong
--  Authors
-- 		Ricardo Bittencourt
--	   	Maryana Alegro
--  Created: 2005.5.29
--  Last Modified: 2005.5.29
--------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.STD_LOGIC_ARITH.ALL; 
use IEEE.std_logic_unsigned.all;

entity VGA is
  port (
    CLOCK		: in std_logic;
    RESET		: in std_logic;
    H_SYNC	: out std_logic;
    V_SYNC	: out std_logic;
    R		: out std_logic;
    G		: out std_logic;
    B		: out std_logic
  );
end VGA;

architecture rtl of VGA is

constant H_pulse		: std_logic_vector(1 downto 0)	:= "00";
constant H_porch		: std_logic_vector(1 downto 0)	:= "01";
constant H_disp		: std_logic_vector(1 downto 0)	:= "11";
constant V_pulse		: std_logic_vector(1 downto 0)	:= "00";
constant V_porch		: std_logic_vector(1 downto 0)	:= "01";
constant V_disp		: std_logic_vector(1 downto 0)	:= "11";

signal H_count			: std_logic_vector(10 downto 0);
signal V_count			: std_logic_vector(9 downto 0);
signal H_state			: std_logic_vector(1 downto 0);
signal V_state			: std_logic_vector(1 downto 0);
signal R_out,G_out,B_out : std_logic;

signal color_bar		: std_logic_vector(2 downto 0);
signal color_bar_count	: std_logic_vector(7 downto 0);

signal init_state: std_logic_vector(2 downto 0);
constant init_start: std_logic_vector(2 downto 0) := "001";
constant init_running: std_logic_vector(2 downto 0) := "010";

signal paddle_up, paddle_down: std_logic;
signal paddle_up_start, paddle_down_start: std_logic;
signal paddle_up_x: std_logic_vector(10 downto 0);
signal paddle_down_x: std_logic_vector(10 downto 0);
signal paddle_up_x20: std_logic_vector(10 downto 0);
signal paddle_down_x20: std_logic_vector(10 downto 0);

signal init_finished: std_logic;

begin

H_SYNC		<= H_state(0);
V_SYNC		<= V_state(0);
R			<= R_out when ((H_state(1) and V_state(1))='1') else '0';
G			<= G_out when ((H_state(1) and V_state(1))='1') else '0';
B			<= B_out when ((H_state(1) and V_state(1))='1') else '0';

  -- init variables
  process(RESET,CLOCK,init_state)
  begin
    if(RESET='1') then
      init_state <= (others => '0');
    elsif(CLOCK'event and CLOCK='1') then
	   if (init_finished = '0') then
	     init_state <= init_start;
		else
	     init_state <= init_running;
		end if;
    end if;
  end process;

  -- H signals control
  process(RESET,CLOCK,H_count)
  begin
    if(RESET='1') then
      H_count <= (others => '0');
    elsif(CLOCK'event and CLOCK='1') then

      if(H_count=1599) then
        H_count <= (others => '0');
      else
        H_count <= H_count + 1;
      end if;
    end if;
  end process;
  
  process(RESET,CLOCK,H_state,H_count)
  begin
    if(RESET='1') then
      H_state <= H_pulse;
    elsif(CLOCK'event and CLOCK='1') then
      case H_state is
      when H_pulse =>
        if(H_count=1567) then	 
          H_state <= H_porch;
        end if;
      when H_porch =>
        if(H_count=1599) then 
          H_state <= H_disp;
        elsif(H_count=1375) then 
          H_state <= H_pulse;
        end if;
      when H_disp =>
        if(H_count=1279) then 
          H_state <= H_porch;
        end if;
      when others => H_state <= H_pulse;
      end case;
    end if;
  end process;
  
  -- V signals control
  process(RESET,CLOCK,H_count,V_count)
  begin
    if(RESET='1') then
      V_count <= (others => '0');
    elsif(CLOCK'event and CLOCK='1') then
      if(H_count=1375) then 
        if(V_count=520) then
          V_count <= (others => '0');
        else
          V_count <= V_count + 1;
        end if;
      end if;
    end if;
  end process;
  
  process(RESET,CLOCK,H_count,V_state,V_count)
  begin
    if(RESET='1') then
      V_state <= V_pulse;
    elsif(CLOCK'event and CLOCK='1') then
      if(H_count=1375) then 
        case V_state is
        when V_pulse =>
          if(V_count=509) then
            V_state <= V_porch;
          end if;
        when V_porch =>
          if(V_count=520) then
            V_state <= V_disp;
          elsif(V_count=508) then 
            V_state <= V_pulse;
          end if;
        when V_disp =>
          if(V_count=479) then 
            V_state <= V_porch;
          end if;
        when others => V_state <= V_pulse;
        end case;
      end if;
    end if;
  end process;

  -- Paddle control
  process (RESET)
  begin
    if (RESET='1') then
	   paddle_up_x <= "00110010000";
		paddle_down_x <= "00110010000";
	 end if;
  end process;

  process (RESET,CLOCK,V_state,V_count)
  begin
	 paddle_up_x20 <= paddle_up_x + 150;
	 paddle_down_x20 <= paddle_down_x + 150;
  end process;

  -- Paddle raster generation
  process (RESET,CLOCK,V_state,V_count)
  begin
    if (RESET='1') then
      paddle_up_start <= '0';
	   paddle_down_start <= '0';
	 elsif (CLOCK='1' and CLOCK'event) then
	   if ((H_state=H_disp) and (H_count=paddle_up_x)) then		   
		   paddle_up_start <= '1';
		elsif ((H_state=H_disp) and (H_count=paddle_up_x20)) then
		   paddle_up_start <= '0';
		end if;
	   if ((H_state=H_disp) and (H_count=paddle_down_x)) then		   
		   paddle_down_start <= '1';
		elsif ((H_state=H_disp) and (H_count=paddle_down_x20)) then
		   paddle_down_start <= '0';
		end if;
	 end if;
  end process;
  
  process (RESET,CLOCK,V_state,V_count)
  begin
    if (RESET='1') then
	   paddle_up <= '0';
		paddle_down <= '0';
	 elsif (CLOCK='1' and CLOCK'event) then
	   if ((V_state=V_disp) and (V_count=40)) then		   
		   paddle_up <= '1';
		elsif ((V_state=V_disp) and (V_count=59)) then
		   paddle_up <= '0';
		elsif ((V_state=V_disp) and (V_count=420)) then
		   paddle_down <= '1';
		elsif ((V_state=V_disp) and (V_count=439))then
		   paddle_down <= '0';
		end if;
	 end if;
  end process;
  
  -- Colors bar generation
  process(RESET,CLOCK,color_bar,color_bar_count,H_count,V_count,
  		H_state,V_state,paddle_up,paddle_down,paddle_up_start,
		paddle_down_start)
  begin
    if(RESET='1') then
      R_out <= '0';
      G_out <= '0';
      B_out <= '0';
	   color_bar <= (others => '0');
	   color_bar_count <= (others => '0');
    elsif(CLOCK'event and CLOCK='1') then

      if ((V_state=V_disp) and (H_state=H_disp)) then
	     if (color_bar_count=159) then
	       color_bar_count <= (others => '0');
		    if (color_bar=7) then
		      color_bar <= (others => '0');
		    else
		      color_bar <= color_bar + 1;
		    end if;
	     else
  	       color_bar_count <= color_bar_count + 1;
	     end if;	   
	   end if;

	 if ((paddle_up='1') and (paddle_up_start='1')) then
	   R_out <= '1';
		G_out <= '0';
	   B_out <= '0';
	 elsif ((paddle_down='1') and (paddle_down_start='1')) then
	   R_out <= '0';
		G_out <= '0';
	   B_out <= '1';
	 else 
	   R_out <= color_bar(2);
		G_out <= color_bar(1);
	   B_out <= color_bar(0);
  	 end if;

	 end if;
  end process;
end rtl;