#!/usr/bin/env bash
# make_de10_lite_to_basys3_wrapper.sh — author the Arcade_Pooyan Basys3 top level
#
# Usage:  bash contrib/basys3/tools/make_de10_lite_to_basys3_wrapper.sh [REPODIR]
#   REPODIR defaults to two levels up from this script.
#
# Produces (directly, no intermediate copy):
#   basys3/arcade_pooyan_basys3.srcs/sources_1/new/arcade_pooyan_basys3.vhd
#
set -euo pipefail

REPODIR="${1:-$(cd "$(dirname "$0")/../../.." && pwd)}"
ORIG="${REPODIR}/rtl_dar/pooyan_de10_lite.vhd"
TARGET="${REPODIR}/basys3/arcade_pooyan_basys3.srcs/sources_1/new/arcade_pooyan_basys3.vhd"

if [ ! -f "${ORIG}" ]; then
  echo "ERROR: Original DE10-Lite wrapper not found: ${ORIG}" >&2
  exit 1
fi

mkdir -p "$(dirname "${TARGET}")"

# ---------- write the Basys3 wrapper ----------
cat > "${TARGET}" << 'VHDL_END'
---------------------------------------------------------------------------------
-- Basys3 Top level for Pooyan (Konami, 1982) by Dar (darfpga@aol.fr) (29/10/2017)
-- http://darfpga.blogspot.fr
--
-- Basys3 port by Red~Bote.
--
-- Ported from pooyan_de10_lite.vhd (DE10-Lite):
--  - 100 MHz board oscillator; clk_wiz_0 MMCM derives 12 MHz (core) + 14 MHz (sound)
--  - PS/2 keyboard on JB; Atari-style joystick on JA, OR-merged with keyboard
--    (Somhi kbd_joystick: arrows/space; F3 coin, F4 start1, F5 start2)
--  - PWM audio on JC via PmodAMP2 (AIN + GAIN/Shutdown on sw15/sw14); 31 kHz VGA on the Basys3 VGA connector via DECA vga_scandoubler
--  - btnC = reset
--  - sw(7:0) -> dip_switch_2 (Sound/Difficulty/Bonus/Cocktail/Lives)
--  - sw(12:8) -> dip_switch_1(4:0) (Coinage A); dip_switch_1(7:5) = "111" (Coinage B default)
---------------------------------------------------------------------------------
-- Educational use only
-- Do not redistribute synthetized file with roms
-- Do not redistribute roms whatever the form
-- Use at your own risk
---------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

library work;

entity arcade_pooyan_basys3 is
port(
 sys_clk      : in  std_logic;                     -- 100 MHz on Basys3
 sw           : in  std_logic_vector(15 downto 0);
 btnC         : in  std_logic;
 led          : out std_logic_vector(15 downto 0);
 seg          : out std_logic_vector(6 downto 0);
 an           : out std_logic_vector(3 downto 0);

 JA           : in  std_logic_vector(4 downto 0);  -- Joystick active-low (JA1=right,JA2=left,JA3=down,JA4=up,JA7=fire)
 ps2_dat      : in  std_logic;                      -- PS/2 data  (JB1)
 ps2_clk      : in  std_logic;                      -- PS/2 clock (JB3)
 O_PMODAMP2_AIN    : out std_logic;
 O_PMODAMP2_GAIN   : out std_logic;
 O_PMODAMP2_SHUTD  : out std_logic;

 vga_r        : out std_logic_vector(3 downto 0);
 vga_g        : out std_logic_vector(3 downto 0);
 vga_b        : out std_logic_vector(3 downto 0);
 vga_hs       : out std_logic;
 vga_vs       : out std_logic
);
end arcade_pooyan_basys3;

architecture struct of arcade_pooyan_basys3 is

 signal clock_12  : std_logic;
 signal clock_14  : std_logic;
 signal clock_6   : std_logic;
 signal reset     : std_logic;
 signal mmcm_reset : std_logic := '0';

 signal r         : std_logic_vector(2 downto 0);
 signal g         : std_logic_vector(2 downto 0);
 signal b         : std_logic_vector(1 downto 0);
 signal csync     : std_logic;
 signal blankn    : std_logic;
 signal hsync     : std_logic;
 signal vsync     : std_logic;

 signal audio           : std_logic_vector(10 downto 0);
 signal pwm_accumulator : std_logic_vector(12 downto 0);

 signal vga_r_i  : std_logic_vector(5 downto 0);
 signal vga_g_i  : std_logic_vector(5 downto 0);
 signal vga_b_i  : std_logic_vector(5 downto 0);
 signal vga_r_o  : std_logic_vector(5 downto 0);
 signal vga_g_o  : std_logic_vector(5 downto 0);
 signal vga_b_o  : std_logic_vector(5 downto 0);
 signal hsync_o  : std_logic;
 signal vsync_o  : std_logic;

 signal tv15Khz_mode  : std_logic;

 signal kbd_intr      : std_logic;
 signal kbd_scancode  : std_logic_vector(7 downto 0);
 signal kbd_joy       : std_logic_vector(8 downto 0);
 signal fn_pulse      : std_logic_vector(7 downto 0) := (others => '0');
 signal fn_toggle     : std_logic_vector(7 downto 0) := (others => '0');

 signal kb_left   : std_logic;
 signal kb_right  : std_logic;
 signal kb_fire   : std_logic;
 signal kb_start1 : std_logic;
 signal kb_start2 : std_logic;
 signal kb_coin   : std_logic;

 signal dip_sw1       : std_logic_vector(7 downto 0);
 signal dbg_cpu_addr : std_logic_vector(15 downto 0);
 signal seg8         : std_logic_vector(7 downto 0);

 component vga_scandoubler
     port (
         clkvideo           : in  std_logic;
         clkvga             : in  std_logic;
         enable_scandoubling : in  std_logic;
         disable_scaneffect : in  std_logic;
         ri                 : in  std_logic_vector (5 downto 0);
         gi                 : in  std_logic_vector (5 downto 0);
         bi                 : in  std_logic_vector (5 downto 0);
         hsync_ext_n        : in  std_logic;
         vsync_ext_n        : in  std_logic;
         csync_ext_n        : in  std_logic;
         ro                 : out std_logic_vector (5 downto 0);
         go                 : out std_logic_vector (5 downto 0);
         bo                 : out std_logic_vector (5 downto 0);
         hsync              : out std_logic;
         vsync              : out std_logic
     );
 end component;

begin

reset <= btnC;

-- 100 MHz -> 12 MHz (core) + 14 MHz (sound board)
clocks : entity work.clk_wiz_0
port map(
 clk_in1  => sys_clk,
 clk_out1 => clock_12,
 clk_out2 => clock_14,
 reset    => mmcm_reset,
 locked   => open
);

-- clock_6 = clock_12 / 2 (for scandoubler ce_x1 and PS/2 keyboard)
process (reset, clock_12)
begin
	if reset='1' then
		clock_6  <= '0';
	else
		if rising_edge(clock_12) then
				clock_6  <= not clock_6;
		end if;
	end if;
end process;

-- Pooyan core
dip_sw1 <= "111" & not sw(12 downto 8);

pooyan : entity work.pooyan
port map(
 clock_12   => clock_12,
 clock_14   => clock_14,
 reset      => reset,

 video_r      => r,
 video_g      => g,
 video_b      => b,
 video_csync  => csync,
 video_blankn => blankn,
 video_hs     => hsync,
 video_vs     => vsync,
 audio_out    => audio,

 dip_switch_1 => dip_sw1,
 dip_switch_2 => not sw(7) & not sw(6 downto 3) & sw(2) & not sw(1 downto 0),

 start1       => kb_start1 or (not JA(4) and not JA(1)),
 start2       => kb_start2 or (not JA(4) and not JA(0)),
 coin1        => kb_coin   or (not JA(4) and not JA(3)),

 fire1        => kb_fire   or  not JA(4),
 left1        => kb_left   or  not JA(1),
 right1       => kb_right  or  not JA(0),
 down1        => kbd_joy(1) or  not JA(2),
 up1          => kbd_joy(0) or  not JA(3),

 fire2        => kb_fire   or  not JA(4),
 left2        => kb_left   or  not JA(1),
 right2       => kb_right  or  not JA(0),
 down2        => kbd_joy(1) or  not JA(2),
 up2          => kbd_joy(0) or  not JA(3),

 dbg_cpu_addr => dbg_cpu_addr
);

-- 31 kHz VGA via DECA vga_scandoubler.
-- Pad the core's 3/3/2-bit RGB to 6 bits by MSB replication; force black during blank.
vga_r_i <= r & r     when blankn = '1' else "000000";
vga_g_i <= g & g     when blankn = '1' else "000000";
vga_b_i <= b & b & b when blankn = '1' else "000000";

scandoubler_inst : vga_scandoubler
port map(
 clkvideo            => clock_6,
 clkvga              => clock_12,
 enable_scandoubling => '1',
 disable_scaneffect  => '1',
 ri                  => vga_r_i,
 gi                  => vga_g_i,
 bi                  => vga_b_i,
 hsync_ext_n         => hsync,
 vsync_ext_n         => vsync,
 csync_ext_n         => csync,
 ro                  => vga_r_o,
 go                  => vga_g_o,
 bo                  => vga_b_o,
 hsync               => hsync_o,
 vsync               => vsync_o
);

-- Display mode toggle via F8 key (fn_toggle(7)):
--   0 = 31 kHz VGA (scan-doubled 6-bit RGB adapted to 4 bits/color)
--   1 = 15 kHz TV  (native core RGB padded to 4 bits, composite sync on HS,
--       VS held high -- requires a 15 kHz RGB monitor or RGB->composite converter)
tv15Khz_mode <= fn_toggle(7);          -- F8 key

process (clock_12)
begin
    if rising_edge(clock_12) then
        if tv15Khz_mode = '1' then
            -- RGB (15 kHz TV)
            if blankn = '1' then
                vga_r  <= r & '0';
                vga_g  <= g & '0';
                vga_b  <= b & "00";
            else
                vga_r  <= "0000";
                vga_g  <= "0000";
                vga_b  <= "0000";
            end if;
            vga_hs <= csync;
            vga_vs <= '1';
        else
            -- VGA (31 kHz, scan-doubled)
            vga_r  <= vga_r_o(5 downto 2);
            vga_g  <= vga_g_o(5 downto 2);
            vga_b  <= vga_b_o(5 downto 2);
            vga_hs <= hsync_o;
            vga_vs <= vsync_o;
        end if;
    end if;
end process;

-- PS/2 keyboard
keyboard : entity work.io_ps2_keyboard
port map (
  clk       => clock_6,
  kbd_clk   => ps2_clk,
  kbd_dat   => ps2_dat,
  interrupt => kbd_intr,
  scancode  => kbd_scancode
);

-- Translate scancode to joystick (Somhi interface: arrows/space +
-- F-key pulse/toggle banks)
joystick : entity work.kbd_joystick
port map (
  Clk           => clock_6,
  KbdInt        => kbd_intr,
  KbdScanCode   => std_logic_vector(kbd_scancode),
  joy_BBBBFRLDU => kbd_joy,
  fn_pulse      => fn_pulse,
  fn_toggle     => fn_toggle
);

-- Keyboard mapping: directional from joy bits, coin/start from F-key pulses
kb_left   <= kbd_joy(2);  -- left arrow
kb_right  <= kbd_joy(3);  -- right arrow
kb_fire   <= kbd_joy(4);  -- space
kb_start1 <= fn_pulse(3); -- F4
kb_start2 <= fn_pulse(4); -- F5
kb_coin   <= fn_pulse(2); -- F3

-- PWM audio output (11-bit audio -> PWM on JA pins)
process(clock_14)
begin
  if rising_edge(clock_14) then
    pwm_accumulator <= std_logic_vector(unsigned('0' & pwm_accumulator(11 downto 0)) + unsigned(audio & "00"));
  end if;
end process;

O_PMODAMP2_AIN   <= pwm_accumulator(12);
O_PMODAMP2_SHUTD <= sw(14);
O_PMODAMP2_GAIN  <= sw(15);

-- Debug: show dip_switch_2 and dip_switch_1 on LEDs
led(7 downto 0)  <= sw(7 downto 0);
led(12 downto 8) <= sw(12 downto 8);
led(15 downto 13) <= (others => '0');

-- Debug: CPU address on 7-segment (active-low anodes, active-low segments)
an <= "1110";  -- enable digit 0 only
h0 : entity work.decodeur_7_seg port map(dbg_cpu_addr(3 downto 0), seg8);
seg <= seg8(6 downto 0);

end struct;
VHDL_END

echo "Wrote: ${TARGET}"
