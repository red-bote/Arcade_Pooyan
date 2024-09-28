#!/bin/bash
# Convert Pooyan ROMs to VHDL
# For use with Arcade Pooyan port to Basys 3 Artix-7 FPGA  
# Red~Bote 9/21/2024

# 5401b8ef586127c8cf5a431e5c44e38be2254a98  1.4a
# b23cc7e61276c61a78e80fe08c7f0c8adadf2ffe  2.5a
# 5206893760f188ac71a5e6bd42561cf25fcc3d49  3.6a
# 4d9707423ad531ac535db432e329b3d52cbb4559  4.7a
# c815f0d27593efd23923511bdd13835456ef7f76  5.8a
# 189ad488869f34d7a38b82ef70eb805acfe04312  6.9a
# de5447d59a99c4c08c4f40c0b7dd3c3c609c11d4  7.9g
# 0325c1c1fdb44e0044b82b7c79b5eeabf5c11ce7  8.10g
# ae131320b66d76d4bc9108da6708f6f874b2e123  pooyan.pr1
# 9ce8eb92e482eba5a9077e9db99841d65b011346  pooyan.pr2
# e0188ecd5b53a8e6e28c1de80def676740772334  pooyan.pr3
# 5689a84ef110bdc0039ad1a6c5778e0b8eccfce0  xx.7a
# 9ab4e5362f9f7d9b46b750e14b1d9d71c57be40f  xx.8a


ROMS=roms
BUILD=./build
ROMGEN=../make_vhdl_prom

[ ! -d $BUILD ] && mkdir $BUILD

cat  $ROMS/1.4a $ROMS/2.5a $ROMS/3.6a $ROMS/4.7a  > $BUILD/pooyan_prog.bin
cat  $ROMS/xx.7a $ROMS/xx.8a  > $BUILD/pooyan_sound.bin

cd $BUILD

$ROMGEN  pooyan_prog.bin  pooyan_prog.vhd
rm pooyan_prog.bin

$ROMGEN  ../$ROMS/6.9a  pooyan_sprite_grphx1.vhd
$ROMGEN  ../$ROMS/5.8a  pooyan_sprite_grphx2.vhd

$ROMGEN  ../$ROMS/8.10g  pooyan_char_grphx1.vhd
$ROMGEN  ../$ROMS/7.9g   pooyan_char_grphx2.vhd

$ROMGEN  pooyan_sound.bin  pooyan_sound_prog.vhd
rm pooyan_sound.bin

$ROMGEN  ../$ROMS/pooyan.pr1  pooyan_palette.vhd
$ROMGEN  ../$ROMS/pooyan.pr3  pooyan_char_color_lut.vhd
$ROMGEN  ../$ROMS/pooyan.pr2  pooyan_sprite_color_lut.vhd

cd ..


