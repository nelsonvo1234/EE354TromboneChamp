read_verilog actual_project/sprite_roms.v
read_verilog actual_project/hvsync_generator.v
read_verilog actual_project/player.v
read_verilog actual_project/world.v
read_verilog actual_project/vga_demo.v
synth_design -top vga_demo -part xc7a100tcsg324-1
