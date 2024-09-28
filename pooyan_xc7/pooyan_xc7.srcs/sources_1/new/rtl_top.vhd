----------------------------------------------------------------------------------
-- Company: Red~Bote
-- Engineer: Glenn Neidermeier
-- 
-- Create Date: 09/21/2024 08:33:29 AM
-- Design Name: 
-- Module Name: rtl_top
-- Project Name: Top level for Pooyan by Dar
-- Target Devices: Basys 3 (Xilinx Artix 7 FPGA xc7a35t)
-- Tool Versions: Vivado v2020.2
-- Description: 
--  VHDL top level for Pooyan FPGA by DAR, ported to Vivado project for XC7 (Basys 3 board)
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
--   Ported from Pooyan release rev 02 - (26/04/2020) by Dar (darfpga@aol.fr):
--     https://sourceforge.net/projects/darfpga/files/Software%20VHDL/pooyan/
--     vhdl_pooyan_rev_0_2_2020_04_26.zip
--
--   Adaptation to VGA based on
--     https://github.com/DECAfpga/Arcade_Pooyan/blob/main/deca/pooyan_deca.vhd
--
--   Vivado clocking wizard generator is used to get very close to rquired clocks
--     12.288MHz for pooyan core, 14.318MHz for sound 
--
--   Video output is 640x480 VGA. Audio output is on a PMOD Amp 2
--   Input uses a custom PMOD adapter for a classic Atari-style game controller.
--   Up+Button is Coin/Credit. Left+Button is game start.
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rtl_top is
    port (
        clk : in STD_LOGIC;
        sw : in STD_LOGIC_VECTOR (15 downto 0);
        JA : in STD_LOGIC_VECTOR(4 downto 0);

        O_PMODAMP2_AIN : out STD_LOGIC;
        O_PMODAMP2_GAIN : out STD_LOGIC;
        O_PMODAMP2_SHUTD : out STD_LOGIC;

        btnU : in STD_LOGIC;
        btnD : in STD_LOGIC;
        btnL : in STD_LOGIC;
        btnR : in STD_LOGIC;
        btnC : in STD_LOGIC;

        vgaRed : out STD_LOGIC_VECTOR (3 downto 0);
        vgaGreen : out STD_LOGIC_VECTOR (3 downto 0);
        vgaBlue : out STD_LOGIC_VECTOR (3 downto 0);

        Hsync : out STD_LOGIC;
        Vsync : out STD_LOGIC;
        led : out STD_LOGIC_VECTOR (15 downto 0));
end rtl_top;

architecture RTL of rtl_top is

    signal reset : STD_LOGIC := '0';
    signal clock_14m : STD_LOGIC;
    signal clock_12m : STD_LOGIC;
    signal clock_6m : STD_LOGIC;

    signal r : STD_LOGIC_VECTOR(2 downto 0);
    signal g : STD_LOGIC_VECTOR(2 downto 0);
    signal b : STD_LOGIC_VECTOR(1 downto 0);

    signal r_x2 : STD_LOGIC_VECTOR(2 downto 0);
    signal g_x2 : STD_LOGIC_VECTOR(2 downto 0);
    signal b_x2 : STD_LOGIC_VECTOR(1 downto 0);

    signal vga_g_i : STD_LOGIC_VECTOR(5 downto 0);
    signal vga_r_i : STD_LOGIC_VECTOR(5 downto 0);
    signal vga_b_i : STD_LOGIC_VECTOR(5 downto 0);
    signal vga_r_o : STD_LOGIC_VECTOR(5 downto 0);
    signal vga_g_o : STD_LOGIC_VECTOR(5 downto 0);
    signal vga_b_o : STD_LOGIC_VECTOR(5 downto 0);

    signal hsync_x1 : STD_LOGIC;
    signal vsync_x1 : STD_LOGIC;

    signal vga_hs_o : STD_LOGIC;
    signal vga_vs_o : STD_LOGIC;

    signal csync : STD_LOGIC;
    signal blankn : STD_LOGIC;

    signal audio : STD_LOGIC_VECTOR(10 downto 0);
    signal pwm_accumulator : STD_LOGIC_VECTOR(12 downto 0);

    signal joyPCFRLDU : STD_LOGIC_VECTOR(7 downto 0);

    signal dbg_cpu_addr : STD_LOGIC_VECTOR(15 downto 0);

    ----
    component vga_scandoubler is -- mod by somhic
        port (
            clkvideo : in STD_LOGIC;
            clkvga : in STD_LOGIC; -- has to be double of clkvideo
            enable_scandoubling : in STD_LOGIC;
            disable_scaneffect : in STD_LOGIC;
            ri : in STD_LOGIC_VECTOR(5 downto 0);
            gi : in STD_LOGIC_VECTOR(5 downto 0);
            bi : in STD_LOGIC_VECTOR(5 downto 0);
            hsync_ext_n : in STD_LOGIC;
            vsync_ext_n : in STD_LOGIC;
            csync_ext_n : in STD_LOGIC;
            ro : out STD_LOGIC_VECTOR(5 downto 0);
            go : out STD_LOGIC_VECTOR(5 downto 0);
            bo : out STD_LOGIC_VECTOR(5 downto 0);
            hsync : out STD_LOGIC;
            vsync : out STD_LOGIC
        );
    end component;
    ----

begin

    -- active-low shutdown pin
    O_PMODAMP2_SHUTD <= sw(14);
    -- gain pin is driven high there is a 6 dB gain, low is a 12 dB gain 
    O_PMODAMP2_GAIN <= sw(15);

    joyPCFRLDU(7) <= '0'; -- start2
    joyPCFRLDU(6) <= not JA(4) and not JA(1); --start1 <= fire+left
    joyPCFRLDU(5) <= not JA(4) and not JA(3); -- coin1 <= fire+up

    joyPCFRLDU(4) <= not JA(4); -- fire1 
    joyPCFRLDU(3) <= '1'; -- right1 (not used)
    joyPCFRLDU(2) <= '1'; -- left1 (not used)
    joyPCFRLDU(1) <= not JA(2); -- down1
    joyPCFRLDU(0) <= not JA(3); -- up1 

    --reset <= not reset_n;

    -- Clock 12.288MHz for pooyan core, 14.318MHz for sound_board
    u_mmcm : entity work.mmcm_12m_14m
        port map(
            clk_in1 => clk,
            reset => reset,
            locked => open,
            clk_12m => clock_12m,
            clk_14m => clock_14m
        );

    -- make 6MHz clock from 12MHz (duplicated from pooyan.vhd)
    process (reset, clock_12m)
    begin
        if reset = '1' then
            clock_6m <= '0';
        else
            if rising_edge(clock_12m) then
                clock_6m <= not clock_6m;
            end if;
        end if;
    end process;

    -- Pooyan
    pooyan : entity work.pooyan
        port map(

            clock_12 => clock_12m,
            clock_14 => clock_14m,
            reset => reset,

            -- tv15Khz_mode => tv15Khz_mode,
            video_r => r,
            video_g => g,
            video_b => b,
            video_csync => csync,
            video_blankn => blankn,
            video_hs => hsync_x1,
            video_vs => vsync_x1,
            audio_out => audio,

            dip_switch_1 => X"FF", -- Coinage_B / Coinage_A
            dip_switch_2 => X"7F", -- Sound(8)/Difficulty(7-5)/Bonus(4)/Cocktail(3)/lives(2-1)
            -- dip_switch_2 => sw(7 downto 0), 

            start2 => joyPCFRLDU(7),
            start1 => joyPCFRLDU(6),
            coin1 => joyPCFRLDU(5),

            fire1 => joyPCFRLDU(4),
            right1 => joyPCFRLDU(3),
            left1 => joyPCFRLDU(2),
            down1 => joyPCFRLDU(1),
            up1 => joyPCFRLDU(0),

            fire2 => joyPCFRLDU(4),
            right2 => joyPCFRLDU(3),
            left2 => joyPCFRLDU(2),
            down2 => joyPCFRLDU(1),
            up2 => joyPCFRLDU(0),

            dbg_cpu_addr => dbg_cpu_addr
        );

    -- VGA 
    -- adapt video to 6bits/color only and blank
    vga_r_i <= r & r when blankn = '1' else "000000";
    vga_g_i <= g & g when blankn = '1' else "000000";
    vga_b_i <= b & b & b when blankn = '1' else "000000";

    -- vga scandoubler
    scandoubler : vga_scandoubler
    port map(
        --input
        clkvideo => clock_6m,
        clkvga => clock_12m, -- has to be double of clkvideo
        enable_scandoubling => '1',
        disable_scaneffect => '1', -- 1 to disable scanlines
        ri => vga_r_i,
        gi => vga_g_i,
        bi => vga_b_i,
        hsync_ext_n => hsync_x1,
        vsync_ext_n => vsync_x1,
        csync_ext_n => csync,
        --output
        ro => vga_r_o,
        go => vga_g_o,
        bo => vga_b_o,
        hsync => vga_hs_o,
        vsync => vga_vs_o
    );

    --VGA
    -- adapt video to 4 bits/color only
    vgaRed <= vga_r_o (5 downto 2);
    vgaGreen <= vga_g_o (5 downto 2);
    vgaBlue <= vga_b_o (5 downto 2);
    hsync <= vga_hs_o;
    vsync <= vga_vs_o;

    -- PWM sound output (One-bit DAC, delta-sigma dac, https://www.fpga4fun.com/PWM_DAC_3.html)
    process (clock_14m) -- use same clock as pooyan_sound_board
    begin
        if rising_edge(clock_14m) then
            pwm_accumulator <= std_logic_vector(unsigned('0' & pwm_accumulator(11 downto 0)) + unsigned(audio & "00"));
        end if;
    end process;

    --pwm_audio_out_l <= pwm_accumulator(12);
    --pwm_audio_out_r <= pwm_accumulator(12); 
    O_PMODAMP2_AIN <= pwm_accumulator(12);

end RTL;
