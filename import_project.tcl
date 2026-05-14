# Set Current Directory to point to Github Repo directory (where project_run.tcl should be located)
##########################################################
## CHANGE THIS TO THE FILEPATH OF YOUR ACTUAL DIRECTORY ##
## REPLACE THE \ SLASH AS A /                           ##
##########################################################
set SRCDIR "C:/Users/marie/CoE_199_Digi_AI"
cd $SRCDIR

#Add Verilog Files to Project
add_files -scan_for_includes ./Design_Sources

#Add constraints
add_files -fileset constrs_1 ./constraints/arty7_a200t_nexys.xdc

# New core-only testbenches
create_fileset -simset sim_new
add_files -fileset sim_new ./sim/tb_core_extmem.sv
add_files -fileset sim_new ./sim/tb_core_extmem_single.sv

#Set top module of simulation sources
set_property top tb_core_extmem [get_filesets sim_new]
set_property top_lib xil_defaultlib [get_filesets sim_new]

#set top module of design sources
set_property top core_extmem [current_fileset]

# Set arty7_a200t.xdc as target constraints file
set_property target_constrs_file [format %s%s $SRCDIR "/constraints/arty7_a200t_nexys.xdc"] [current_fileset -constrset]

# Add A7-200T constraints file
create_fileset -constrset constr_a200t
set_property target_constrs_file [format %s%s $SRCDIR "/constraints/arty7_a200t_nexys.xdc"] [get_filesets constr_a200t]

#Synthesis and Implementation
#launch_runs synth_1
#wait_on_run synth_1
#launch_runs impl_1 -to_step write_bitstream
#wait_on_run impl_1
