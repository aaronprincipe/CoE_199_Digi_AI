
################################################################
# This is a generated script based on design: person_detection
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}
}
variable script_folder
set script_folder [_tcl::get_script_folder]

################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2024.1
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   if { [string compare $scripts_vivado_version $current_vivado_version] > 0 } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2042 -severity "ERROR" " This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Sourcing the script failed since it was created with a future version of Vivado."}

   } else {
     catch {common::send_gid_msg -ssname BD::TCL -id 2041 -severity "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."}

   }

   return 1
}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source person_detection_script.tcl


# The design that will be created by this Tcl script contains the following 
# module references:
# core_extmem_cacheless, cores_to_AXI4, process_rdata, process_wdata, core_nreset_new, instmem_xpm, qspi_bootloader, qspi_inst_bootloader, qspi_data_nreset, systolic_csr, DMA_Controller, axi_spad_write_adapter, top_wrapper, axi_output_read_adapter

# Please add the sources of those modules before sourcing this Tcl script.

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xc7a200tsbg484-1
   set_property BOARD_PART digilentinc.com:nexys_video:part0:1.2 [current_project]
}


# CHANGE DESIGN NAME HERE
variable design_name
set design_name person_detection

# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $design_name

# Creating design if needed
set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "Please set the variable <design_name> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name exists in project.

   if { $cur_design ne $design_name } {
      common::send_gid_msg -ssname BD::TCL -id 2001 -severity "INFO" "Changing value of <design_name> from <$design_name> to <$cur_design> since current design is empty."
      set design_name [get_property NAME $cur_design]
   }
   common::send_gid_msg -ssname BD::TCL -id 2002 -severity "INFO" "Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name exists in project.
   #    7) No opened design, design_name exists in project.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name not in project.
   #    9) Current opened design, has components, but diff names, design_name not in project.

   common::send_gid_msg -ssname BD::TCL -id 2003 -severity "INFO" "Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

   common::send_gid_msg -ssname BD::TCL -id 2004 -severity "INFO" "Making design <$design_name> as current_bd_design."
   current_bd_design $design_name

}

common::send_gid_msg -ssname BD::TCL -id 2005 -severity "INFO" "Currently the variable <design_name> is equal to \"$design_name\"."

if { $nRet != 0 } {
   catch {common::send_gid_msg -ssname BD::TCL -id 2006 -severity "ERROR" $errMsg}
   return $nRet
}

set bCheckIPsPassed 1
##################################################################
# CHECK IPs
##################################################################
set bCheckIPs 1
if { $bCheckIPs == 1 } {
   set list_check_ips "\ 
xilinx.com:ip:clk_wiz:6.0\
xilinx.com:ip:proc_sys_reset:5.0\
xilinx.com:ip:xlconstant:1.1\
xilinx.com:ip:blk_mem_gen:8.4\
xilinx.com:ip:axi_bram_ctrl:4.1\
xilinx.com:ip:mig_7series:4.2\
xilinx.com:ip:axi_uartlite:2.0\
xilinx.com:ip:axi_quad_spi:3.2\
xilinx.com:ip:smartconnect:1.0\
xilinx.com:ip:ila:6.2\
"

   set list_ips_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2011 -severity "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

   foreach ip_vlnv $list_check_ips {
      set ip_obj [get_ipdefs -all $ip_vlnv]
      if { $ip_obj eq "" } {
         lappend list_ips_missing $ip_vlnv
      }
   }

   if { $list_ips_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2012 -severity "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
      set bCheckIPsPassed 0
   }

}

##################################################################
# CHECK Modules
##################################################################
set bCheckModules 1
if { $bCheckModules == 1 } {
   set list_check_mods "\ 
core_extmem_cacheless\
cores_to_AXI4\
process_rdata\
process_wdata\
core_nreset_new\
instmem_xpm\
qspi_bootloader\
qspi_inst_bootloader\
qspi_data_nreset\
systolic_csr\
DMA_Controller\
axi_spad_write_adapter\
top_wrapper\
axi_output_read_adapter\
"

   set list_mods_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2020 -severity "INFO" "Checking if the following modules exist in the project's sources: $list_check_mods ."

   foreach mod_vlnv $list_check_mods {
      if { [can_resolve_reference $mod_vlnv] == 0 } {
         lappend list_mods_missing $mod_vlnv
      }
   }

   if { $list_mods_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2021 -severity "ERROR" "The following module(s) are not found in the project: $list_mods_missing" }
      common::send_gid_msg -ssname BD::TCL -id 2022 -severity "INFO" "Please add source files for the missing module(s) above."
      set bCheckIPsPassed 0
   }
}

if { $bCheckIPsPassed != 1 } {
  common::send_gid_msg -ssname BD::TCL -id 2023 -severity "WARNING" "Will not continue with creation of design due to the error(s) above."
  return 3
}


##################################################################
# MIG PRJ FILE TCL PROCs
##################################################################

proc write_mig_file_person_detection_mig_7series_0_0 { str_mig_prj_filepath } {

   file mkdir [ file dirname "$str_mig_prj_filepath" ]
   set mig_prj_file [open $str_mig_prj_filepath  w+]

   puts $mig_prj_file {﻿<?xml version="1.0" encoding="UTF-8" standalone="no" ?>}
   puts $mig_prj_file {<Project NoOfControllers="1">}
   puts $mig_prj_file {  }
   puts $mig_prj_file {<!-- IMPORTANT: This is an internal file that has been generated by the MIG software. Any direct editing or changes made to this file may result in unpredictable behavior or data corruption. It is strongly advised that users do not edit the contents of this file. Re-run the MIG GUI with the required settings if any of the options provided below need to be altered. -->}
   puts $mig_prj_file {  <ModuleName>bd_gpio_mig_7series_0_3</ModuleName>}
   puts $mig_prj_file {  <dci_inouts_inputs>1</dci_inouts_inputs>}
   puts $mig_prj_file {  <dci_inputs>1</dci_inputs>}
   puts $mig_prj_file {  <Debug_En>OFF</Debug_En>}
   puts $mig_prj_file {  <DataDepth_En>1024</DataDepth_En>}
   puts $mig_prj_file {  <LowPower_En>ON</LowPower_En>}
   puts $mig_prj_file {  <XADC_En>Enabled</XADC_En>}
   puts $mig_prj_file {  <TargetFPGA>xc7a200t-sbg484/-1</TargetFPGA>}
   puts $mig_prj_file {  <Version>4.2</Version>}
   puts $mig_prj_file {  <SystemClock>No Buffer</SystemClock>}
   puts $mig_prj_file {  <ReferenceClock>Use System Clock</ReferenceClock>}
   puts $mig_prj_file {  <SysResetPolarity>ACTIVE LOW</SysResetPolarity>}
   puts $mig_prj_file {  <BankSelectionFlag>FALSE</BankSelectionFlag>}
   puts $mig_prj_file {  <InternalVref>1</InternalVref>}
   puts $mig_prj_file {  <dci_hr_inouts_inputs>50 Ohms</dci_hr_inouts_inputs>}
   puts $mig_prj_file {  <dci_cascade>0</dci_cascade>}
   puts $mig_prj_file {  <FPGADevice>}
   puts $mig_prj_file {    <selected>7a/xc7a200ti-sbg484</selected>}
   puts $mig_prj_file {  </FPGADevice>}
   puts $mig_prj_file {  <Controller number="0">}
   puts $mig_prj_file {    <MemoryDevice>DDR3_SDRAM/Components/MT41K256M16XX-125</MemoryDevice>}
   puts $mig_prj_file {    <TimePeriod>2500</TimePeriod>}
   puts $mig_prj_file {    <VccAuxIO>1.8V</VccAuxIO>}
   puts $mig_prj_file {    <PHYRatio>4:1</PHYRatio>}
   puts $mig_prj_file {    <InputClkFreq>200</InputClkFreq>}
   puts $mig_prj_file {    <UIExtraClocks>0</UIExtraClocks>}
   puts $mig_prj_file {    <MMCM_VCO>800</MMCM_VCO>}
   puts $mig_prj_file {    <MMCMClkOut0> 1.000</MMCMClkOut0>}
   puts $mig_prj_file {    <MMCMClkOut1>1</MMCMClkOut1>}
   puts $mig_prj_file {    <MMCMClkOut2>1</MMCMClkOut2>}
   puts $mig_prj_file {    <MMCMClkOut3>1</MMCMClkOut3>}
   puts $mig_prj_file {    <MMCMClkOut4>1</MMCMClkOut4>}
   puts $mig_prj_file {    <DataWidth>16</DataWidth>}
   puts $mig_prj_file {    <DeepMemory>1</DeepMemory>}
   puts $mig_prj_file {    <DataMask>1</DataMask>}
   puts $mig_prj_file {    <ECC>Disabled</ECC>}
   puts $mig_prj_file {    <Ordering>Normal</Ordering>}
   puts $mig_prj_file {    <BankMachineCnt>4</BankMachineCnt>}
   puts $mig_prj_file {    <CustomPart>FALSE</CustomPart>}
   puts $mig_prj_file {    <NewPartName/>}
   puts $mig_prj_file {    <RowAddress>15</RowAddress>}
   puts $mig_prj_file {    <ColAddress>10</ColAddress>}
   puts $mig_prj_file {    <BankAddress>3</BankAddress>}
   puts $mig_prj_file {    <MemoryVoltage>1.5V</MemoryVoltage>}
   puts $mig_prj_file {    <C0_MEM_SIZE>536870912</C0_MEM_SIZE>}
   puts $mig_prj_file {    <UserMemoryAddressMap>BANK_ROW_COLUMN</UserMemoryAddressMap>}
   puts $mig_prj_file {    <PinSelection>}
   puts $mig_prj_file {      <Pin IN_TERM="" IOSTANDARD="" PADName="M2" SLEW="" VCCAUX_IO="" name="ddr3_addr[0]"/>}
   puts $mig_prj_file {      <Pin IN_TERM="" IOSTANDARD="" PADName="L5" SLEW="" VCCAUX_IO="" name="ddr3_addr[10]"/>}
   puts $mig_prj_file {      <Pin IN_TERM="" IOSTANDARD="" PADName="N5" SLEW="" VCCAUX_IO="" name="ddr3_addr[11]"/>}
   puts $mig_prj_file {      <Pin IN_TERM="" IOSTANDARD="" PADName="N4" SLEW="" VCCAUX_IO="" name="ddr3_addr[12]"/>}
   puts $mig_prj_file {      <Pin IN_TERM="" IOSTANDARD="" PADName="P2" SLEW="" VCCAUX_IO="" name="ddr3_addr[13]"/>}
   puts $mig_prj_file {      <Pin IN_TERM="" IOSTANDARD="" PADName="P6" SLEW="" VCCAUX_IO="" name="ddr3_addr[14]"/>}
   puts $mig_prj_file {      <Pin IN_TERM="" IOSTANDARD="" PADName="M5" SLEW="" VCCAUX_IO="" name="ddr3_addr[1]"/>}
   puts $mig_prj_file {      <Pin IN_TERM="" IOSTANDARD="" PADName="M3" SLEW="" VCCAUX_IO="" name="ddr3_addr[2]"/>}
   puts $mig_prj_file {      <Pin IN_TERM="" IOSTANDARD="" PADName="M1" SLEW="" VCCAUX_IO="" name="ddr3_addr[3]"/>}
   puts $mig_prj_file {      <Pin IN_TERM="" IOSTANDARD="" PADName="L6" SLEW="" VCCAUX_IO="" name="ddr3_addr[4]"/>}
   puts $mig_prj_file {      <Pin IN_TERM="" IOSTANDARD="" PADName="P1" SLEW="" VCCAUX_IO="" name="ddr3_addr[5]"/>}
   puts $mig_prj_file {      <Pin IN_TERM="" IOSTANDARD="" PADName="N3" SLEW="" VCCAUX_IO="" name="ddr3_addr[6]"/>}
   puts $mig_prj_file {      <Pin IN_TERM="" IOSTANDARD="" PADName="N2" SLEW="" VCCAUX_IO="" name="ddr3_addr[7]"/>}
   puts $mig_prj_file {      <Pin IN_TERM="" IOSTANDARD="" PADName="M6" SLEW="" VCCAUX_IO="" name="ddr3_addr[8]"/>}
   puts $mig_prj_file {      <Pin IN_TERM="" IOSTANDARD="" PADName="R1" SLEW="" VCCAUX_IO="" name="ddr3_addr[9]"/>}
   puts $mig_prj_file {      <Pin IN_TERM="" IOSTANDARD="" PADName="L3" SLEW="" VCCAUX_IO="" name="ddr3_ba[0]"/>}
   puts $mig_prj_file {      <Pin IN_TERM="" IOSTANDARD="" PADName="K6" SLEW="" VCCAUX_IO="" name="ddr3_ba[1]"/>}
   puts $mig_prj_file {      <Pin IN_TERM="" IOSTANDARD="" PADName="L4" SLEW="" VCCAUX_IO="" name="ddr3_ba[2]"/>}
   puts $mig_prj_file {      <Pin IN_TERM="" IOSTANDARD="" PADName="K3" SLEW="" VCCAUX_IO="" name="ddr3_cas_n"/>}
   puts $mig_prj_file {      <Pin IN_TERM="" IOSTANDARD="" PADName="P4" SLEW="" VCCAUX_IO="" name="ddr3_ck_n[0]"/>}
   puts $mig_prj_file {      <Pin IN_TERM="" IOSTANDARD="" PADName="P5" SLEW="" VCCAUX_IO="" name="ddr3_ck_p[0]"/>}
   puts $mig_prj_file {      <Pin IN_TERM="" IOSTANDARD="" PADName="J6" SLEW="" VCCAUX_IO="" name="ddr3_cke[0]"/>}
   puts $mig_prj_file {      <Pin IN_TERM="" IOSTANDARD="" PADName="G3" SLEW="" VCCAUX_IO="" name="ddr3_dm[0]"/>}
   puts $mig_prj_file {      <Pin IN_TERM="" IOSTANDARD="" PADName="F1" SLEW="" VCCAUX_IO="" name="ddr3_dm[1]"/>}
   puts $mig_prj_file {      <Pin IN_TERM="" IOSTANDARD="" PADName="G2" SLEW="" VCCAUX_IO="" name="ddr3_dq[0]"/>}
   puts $mig_prj_file {      <Pin IN_TERM="" IOSTANDARD="" PADName="F3" SLEW="" VCCAUX_IO="" name="ddr3_dq[10]"/>}
   puts $mig_prj_file {      <Pin IN_TERM="" IOSTANDARD="" PADName="D2" SLEW="" VCCAUX_IO="" name="ddr3_dq[11]"/>}
   puts $mig_prj_file {      <Pin IN_TERM="" IOSTANDARD="" PADName="C2" SLEW="" VCCAUX_IO="" name="ddr3_dq[12]"/>}
   puts $mig_prj_file {      <Pin IN_TERM="" IOSTANDARD="" PADName="A1" SLEW="" VCCAUX_IO="" name="ddr3_dq[13]"/>}
   puts $mig_prj_file {      <Pin IN_TERM="" IOSTANDARD="" PADName="E2" SLEW="" VCCAUX_IO="" name="ddr3_dq[14]"/>}
   puts $mig_prj_file {      <Pin IN_TERM="" IOSTANDARD="" PADName="B1" SLEW="" VCCAUX_IO="" name="ddr3_dq[15]"/>}
   puts $mig_prj_file {      <Pin IN_TERM="" IOSTANDARD="" PADName="H4" SLEW="" VCCAUX_IO="" name="ddr3_dq[1]"/>}
   puts $mig_prj_file {      <Pin IN_TERM="" IOSTANDARD="" PADName="H5" SLEW="" VCCAUX_IO="" name="ddr3_dq[2]"/>}
   puts $mig_prj_file {      <Pin IN_TERM="" IOSTANDARD="" PADName="J1" SLEW="" VCCAUX_IO="" name="ddr3_dq[3]"/>}
   puts $mig_prj_file {      <Pin IN_TERM="" IOSTANDARD="" PADName="K1" SLEW="" VCCAUX_IO="" name="ddr3_dq[4]"/>}
   puts $mig_prj_file {      <Pin IN_TERM="" IOSTANDARD="" PADName="H3" SLEW="" VCCAUX_IO="" name="ddr3_dq[5]"/>}
   puts $mig_prj_file {      <Pin IN_TERM="" IOSTANDARD="" PADName="H2" SLEW="" VCCAUX_IO="" name="ddr3_dq[6]"/>}
   puts $mig_prj_file {      <Pin IN_TERM="" IOSTANDARD="" PADName="J5" SLEW="" VCCAUX_IO="" name="ddr3_dq[7]"/>}
   puts $mig_prj_file {      <Pin IN_TERM="" IOSTANDARD="" PADName="E3" SLEW="" VCCAUX_IO="" name="ddr3_dq[8]"/>}
   puts $mig_prj_file {      <Pin IN_TERM="" IOSTANDARD="" PADName="B2" SLEW="" VCCAUX_IO="" name="ddr3_dq[9]"/>}
   puts $mig_prj_file {      <Pin IN_TERM="" IOSTANDARD="" PADName="J2" SLEW="" VCCAUX_IO="" name="ddr3_dqs_n[0]"/>}
   puts $mig_prj_file {      <Pin IN_TERM="" IOSTANDARD="" PADName="D1" SLEW="" VCCAUX_IO="" name="ddr3_dqs_n[1]"/>}
   puts $mig_prj_file {      <Pin IN_TERM="" IOSTANDARD="" PADName="K2" SLEW="" VCCAUX_IO="" name="ddr3_dqs_p[0]"/>}
   puts $mig_prj_file {      <Pin IN_TERM="" IOSTANDARD="" PADName="E1" SLEW="" VCCAUX_IO="" name="ddr3_dqs_p[1]"/>}
   puts $mig_prj_file {      <Pin IN_TERM="" IOSTANDARD="" PADName="K4" SLEW="" VCCAUX_IO="" name="ddr3_odt[0]"/>}
   puts $mig_prj_file {      <Pin IN_TERM="" IOSTANDARD="" PADName="J4" SLEW="" VCCAUX_IO="" name="ddr3_ras_n"/>}
   puts $mig_prj_file {      <Pin IN_TERM="" IOSTANDARD="" PADName="G1" SLEW="" VCCAUX_IO="" name="ddr3_reset_n"/>}
   puts $mig_prj_file {      <Pin IN_TERM="" IOSTANDARD="" PADName="L1" SLEW="" VCCAUX_IO="" name="ddr3_we_n"/>}
   puts $mig_prj_file {    </PinSelection>}
   puts $mig_prj_file {    <System_Control>}
   puts $mig_prj_file {      <Pin Bank="Select Bank" PADName="No connect" name="sys_rst"/>}
   puts $mig_prj_file {      <Pin Bank="Select Bank" PADName="No connect" name="init_calib_complete"/>}
   puts $mig_prj_file {      <Pin Bank="Select Bank" PADName="No connect" name="tg_compare_error"/>}
   puts $mig_prj_file {    </System_Control>}
   puts $mig_prj_file {    <TimingParameters>}
   puts $mig_prj_file {      <Parameters tcke="5" tfaw="40" tras="35" trcd="13.75" trefi="7.8" trfc="260" trp="13.75" trrd="7.5" trtp="7.5" twtr="7.5"/>}
   puts $mig_prj_file {    </TimingParameters>}
   puts $mig_prj_file {    <mrBurstLength name="Burst Length">8 - Fixed</mrBurstLength>}
   puts $mig_prj_file {    <mrBurstType name="Read Burst Type and Length">Sequential</mrBurstType>}
   puts $mig_prj_file {    <mrCasLatency name="CAS Latency">6</mrCasLatency>}
   puts $mig_prj_file {    <mrMode name="Mode">Normal</mrMode>}
   puts $mig_prj_file {    <mrDllReset name="DLL Reset">No</mrDllReset>}
   puts $mig_prj_file {    <mrPdMode name="DLL control for precharge PD">Slow Exit</mrPdMode>}
   puts $mig_prj_file {    <emrDllEnable name="DLL Enable">Enable</emrDllEnable>}
   puts $mig_prj_file {    <emrOutputDriveStrength name="Output Driver Impedance Control">RZQ/6</emrOutputDriveStrength>}
   puts $mig_prj_file {    <emrMirrorSelection name="Address Mirroring">Disable</emrMirrorSelection>}
   puts $mig_prj_file {    <emrCSSelection name="Controller Chip Select Pin">Disable</emrCSSelection>}
   puts $mig_prj_file {    <emrRTT name="RTT (nominal) - On Die Termination (ODT)">RZQ/6</emrRTT>}
   puts $mig_prj_file {    <emrPosted name="Additive Latency (AL)">0</emrPosted>}
   puts $mig_prj_file {    <emrOCD name="Write Leveling Enable">Disabled</emrOCD>}
   puts $mig_prj_file {    <emrDQS name="TDQS enable">Enabled</emrDQS>}
   puts $mig_prj_file {    <emrRDQS name="Qoff">Output Buffer Enabled</emrRDQS>}
   puts $mig_prj_file {    <mr2PartialArraySelfRefresh name="Partial-Array Self Refresh">Full Array</mr2PartialArraySelfRefresh>}
   puts $mig_prj_file {    <mr2CasWriteLatency name="CAS write latency">5</mr2CasWriteLatency>}
   puts $mig_prj_file {    <mr2AutoSelfRefresh name="Auto Self Refresh">Enabled</mr2AutoSelfRefresh>}
   puts $mig_prj_file {    <mr2SelfRefreshTempRange name="High Temparature Self Refresh Rate">Normal</mr2SelfRefreshTempRange>}
   puts $mig_prj_file {    <mr2RTTWR name="RTT_WR - Dynamic On Die Termination (ODT)">Dynamic ODT off</mr2RTTWR>}
   puts $mig_prj_file {    <PortInterface>AXI</PortInterface>}
   puts $mig_prj_file {    <AXIParameters>}
   puts $mig_prj_file {      <C0_C_RD_WR_ARB_ALGORITHM>RD_PRI_REG</C0_C_RD_WR_ARB_ALGORITHM>}
   puts $mig_prj_file {      <C0_S_AXI_ADDR_WIDTH>29</C0_S_AXI_ADDR_WIDTH>}
   puts $mig_prj_file {      <C0_S_AXI_DATA_WIDTH>32</C0_S_AXI_DATA_WIDTH>}
   puts $mig_prj_file {      <C0_S_AXI_ID_WIDTH>2</C0_S_AXI_ID_WIDTH>}
   puts $mig_prj_file {      <C0_S_AXI_SUPPORTS_NARROW_BURST>0</C0_S_AXI_SUPPORTS_NARROW_BURST>}
   puts $mig_prj_file {    </AXIParameters>}
   puts $mig_prj_file {  </Controller>}
   puts $mig_prj_file {</Project>}

   close $mig_prj_file
}
# End of write_mig_file_person_detection_mig_7series_0_0()



##################################################################
# DESIGN PROCs
##################################################################



# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder
  variable design_name

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set DDR3 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:ddrx_rtl:1.0 DDR3 ]

  set UART_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:uart_rtl:1.0 UART_0 ]

  set qspi_flash [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:spi_rtl:1.0 qspi_flash ]


  # Create ports
  set clk [ create_bd_port -dir I -type clk -freq_hz 100000000 clk ]
  set nrst [ create_bd_port -dir I nrst ]
  set init_calib_complete [ create_bd_port -dir O init_calib_complete ]

  # Create instance: clk_wiz_0, and set properties
  set clk_wiz_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 clk_wiz_0 ]
  set_property -dict [list \
    CONFIG.CLKOUT1_JITTER {175.402} \
    CONFIG.CLKOUT1_PHASE_ERROR {98.575} \
    CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {25} \
    CONFIG.CLKOUT2_JITTER {114.829} \
    CONFIG.CLKOUT2_PHASE_ERROR {98.575} \
    CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {200.000} \
    CONFIG.CLKOUT2_USED {true} \
    CONFIG.CLK_IN1_BOARD_INTERFACE {sys_clock} \
    CONFIG.MMCM_CLKFBOUT_MULT_F {10.000} \
    CONFIG.MMCM_CLKOUT0_DIVIDE_F {40.000} \
    CONFIG.MMCM_CLKOUT1_DIVIDE {5} \
    CONFIG.NUM_OUT_CLKS {2} \
    CONFIG.RESET_PORT {resetn} \
    CONFIG.RESET_TYPE {ACTIVE_LOW} \
  ] $clk_wiz_0


  # Create instance: proc_sys_reset_0, and set properties
  set proc_sys_reset_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0 ]

  # Create instance: xlconstant_0, and set properties
  set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_0 ]
  set_property CONFIG.CONST_VAL {0} $xlconstant_0


  # Create instance: core_extmem_cacheless_0, and set properties
  set block_name core_extmem_cacheless
  set block_cell_name core_extmem_cacheless_0
  if { [catch {set core_extmem_cacheless_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $core_extmem_cacheless_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: cores_to_AXI4_0, and set properties
  set block_name cores_to_AXI4
  set block_cell_name cores_to_AXI4_0
  if { [catch {set cores_to_AXI4_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $cores_to_AXI4_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: BRAM, and set properties
  set BRAM [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 BRAM ]
  set_property CONFIG.Memory_Type {True_Dual_Port_RAM} $BRAM


  # Create instance: axi_bram_ctrl_0, and set properties
  set axi_bram_ctrl_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_0 ]

  # Create instance: process_rdata_0, and set properties
  set block_name process_rdata
  set block_cell_name process_rdata_0
  if { [catch {set process_rdata_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $process_rdata_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: process_wdata_0, and set properties
  set block_name process_wdata
  set block_cell_name process_wdata_0
  if { [catch {set process_wdata_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $process_wdata_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: mig_7series_0, and set properties
  set mig_7series_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:mig_7series:4.2 mig_7series_0 ]

  # Generate the PRJ File for MIG
  set str_mig_folder [get_property IP_DIR [ get_ips [ get_property CONFIG.Component_Name $mig_7series_0 ] ] ]
  set str_mig_file_name mig_a.prj
  set str_mig_file_path ${str_mig_folder}/${str_mig_file_name}
  write_mig_file_person_detection_mig_7series_0_0 $str_mig_file_path

  set_property -dict [list \
    CONFIG.BOARD_MIG_PARAM {ddr3_sdram} \
    CONFIG.MIG_DONT_TOUCH_PARAM {Custom} \
    CONFIG.RESET_BOARD_INTERFACE {Custom} \
    CONFIG.XML_INPUT_FILE {mig_a.prj} \
  ] $mig_7series_0


  # Create instance: proc_sys_reset_1, and set properties
  set proc_sys_reset_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_1 ]

  # Create instance: axi_uartlite_0, and set properties
  set axi_uartlite_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_uartlite:2.0 axi_uartlite_0 ]
  set_property -dict [list \
    CONFIG.UARTLITE_BOARD_INTERFACE {usb_uart} \
    CONFIG.USE_BOARD_FLOW {true} \
  ] $axi_uartlite_0


  # Create instance: core_nreset_new_0, and set properties
  set block_name core_nreset_new
  set block_cell_name core_nreset_new_0
  if { [catch {set core_nreset_new_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $core_nreset_new_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: xlconstant_2, and set properties
  set xlconstant_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_2 ]
  set_property CONFIG.CONST_VAL {0} $xlconstant_2


  # Create instance: instmem_xpm_0, and set properties
  set block_name instmem_xpm
  set block_cell_name instmem_xpm_0
  if { [catch {set instmem_xpm_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $instmem_xpm_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: axi_quad_spi_0, and set properties
  set axi_quad_spi_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_quad_spi:3.2 axi_quad_spi_0 ]
  set_property -dict [list \
    CONFIG.C_SPI_MEMORY {3} \
    CONFIG.C_SPI_MODE {0} \
    CONFIG.QSPI_BOARD_INTERFACE {qspi_flash} \
    CONFIG.USE_BOARD_FLOW {true} \
  ] $axi_quad_spi_0


  # Create instance: qspi_bootloader_0, and set properties
  set block_name qspi_bootloader
  set block_cell_name qspi_bootloader_0
  if { [catch {set qspi_bootloader_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $qspi_bootloader_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property CONFIG.WORDS_TO_COPY {100000} $qspi_bootloader_0


  # Create instance: xlconstant_3, and set properties
  set xlconstant_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_3 ]
  set_property -dict [list \
    CONFIG.CONST_VAL {0} \
    CONFIG.CONST_WIDTH {32} \
  ] $xlconstant_3


  # Create instance: smartconnect_1, and set properties
  set smartconnect_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_1 ]
  set_property -dict [list \
    CONFIG.NUM_CLKS {2} \
    CONFIG.NUM_MI {8} \
    CONFIG.NUM_SI {4} \
  ] $smartconnect_1


  # Create instance: qspi_inst_bootloader_0, and set properties
  set block_name qspi_inst_bootloader
  set block_cell_name qspi_inst_bootloader_0
  if { [catch {set qspi_inst_bootloader_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $qspi_inst_bootloader_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: qspi_data_nreset_0, and set properties
  set block_name qspi_data_nreset
  set block_cell_name qspi_data_nreset_0
  if { [catch {set qspi_data_nreset_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $qspi_data_nreset_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: systolic_csr_0, and set properties
  set block_name systolic_csr
  set block_cell_name systolic_csr_0
  if { [catch {set systolic_csr_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $systolic_csr_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: ila_0, and set properties
  set ila_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:ila:6.2 ila_0 ]
  set_property -dict [list \
    CONFIG.C_MONITOR_TYPE {Native} \
    CONFIG.C_NUM_OF_PROBES {3} \
  ] $ila_0


  # Create instance: DMA_Controller_0, and set properties
  set block_name DMA_Controller
  set block_cell_name DMA_Controller_0
  if { [catch {set DMA_Controller_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $DMA_Controller_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: axi_spad_write_adapt_0, and set properties
  set block_name axi_spad_write_adapter
  set block_cell_name axi_spad_write_adapt_0
  if { [catch {set axi_spad_write_adapt_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $axi_spad_write_adapt_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: top_wrapper_0, and set properties
  set block_name top_wrapper
  set block_cell_name top_wrapper_0
  if { [catch {set top_wrapper_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $top_wrapper_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: ila_2, and set properties
  set ila_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:ila:6.2 ila_2 ]
  set_property -dict [list \
    CONFIG.C_MONITOR_TYPE {Native} \
    CONFIG.C_NUM_OF_PROBES {20} \
  ] $ila_2


  # Create instance: axi_output_read_adap_0, and set properties
  set block_name axi_output_read_adapter
  set block_cell_name axi_output_read_adap_0
  if { [catch {set axi_output_read_adap_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $axi_output_read_adap_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create interface connections
  connect_bd_intf_net -intf_net DMA_Controller_0_M_AXI [get_bd_intf_pins DMA_Controller_0/M_AXI] [get_bd_intf_pins smartconnect_1/S03_AXI]
  connect_bd_intf_net -intf_net axi_bram_ctrl_0_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA] [get_bd_intf_pins BRAM/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_bram_ctrl_0_BRAM_PORTB [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTB] [get_bd_intf_pins BRAM/BRAM_PORTB]
  connect_bd_intf_net -intf_net axi_quad_spi_0_SPI_0 [get_bd_intf_ports qspi_flash] [get_bd_intf_pins axi_quad_spi_0/SPI_0]
  connect_bd_intf_net -intf_net axi_uartlite_0_UART [get_bd_intf_ports UART_0] [get_bd_intf_pins axi_uartlite_0/UART]
  connect_bd_intf_net -intf_net cores_to_AXI4_0_M_AXI [get_bd_intf_pins smartconnect_1/S00_AXI] [get_bd_intf_pins cores_to_AXI4_0/M_AXI]
  connect_bd_intf_net -intf_net mig_7series_0_DDR3 [get_bd_intf_ports DDR3] [get_bd_intf_pins mig_7series_0/DDR3]
  connect_bd_intf_net -intf_net qspi_bootloader_0_m [get_bd_intf_pins smartconnect_1/S01_AXI] [get_bd_intf_pins qspi_bootloader_0/m]
  connect_bd_intf_net -intf_net qspi_inst_bootloader_0_m [get_bd_intf_pins qspi_inst_bootloader_0/m] [get_bd_intf_pins smartconnect_1/S02_AXI]
  connect_bd_intf_net -intf_net smartconnect_1_M00_AXI [get_bd_intf_pins smartconnect_1/M00_AXI] [get_bd_intf_pins axi_uartlite_0/S_AXI]
  connect_bd_intf_net -intf_net smartconnect_1_M01_AXI [get_bd_intf_pins smartconnect_1/M01_AXI] [get_bd_intf_pins axi_bram_ctrl_0/S_AXI]
  connect_bd_intf_net -intf_net smartconnect_1_M02_AXI [get_bd_intf_pins smartconnect_1/M02_AXI] [get_bd_intf_pins mig_7series_0/S_AXI]
  connect_bd_intf_net -intf_net smartconnect_1_M03_AXI [get_bd_intf_pins smartconnect_1/M03_AXI] [get_bd_intf_pins axi_quad_spi_0/AXI_LITE]
  connect_bd_intf_net -intf_net smartconnect_1_M04_AXI [get_bd_intf_pins DMA_Controller_0/s_axil] [get_bd_intf_pins smartconnect_1/M04_AXI]
  connect_bd_intf_net -intf_net smartconnect_1_M05_AXI [get_bd_intf_pins smartconnect_1/M05_AXI] [get_bd_intf_pins systolic_csr_0/s_axil]
  connect_bd_intf_net -intf_net smartconnect_1_M06_AXI [get_bd_intf_pins smartconnect_1/M06_AXI] [get_bd_intf_pins axi_spad_write_adapt_0/s_axi]
  connect_bd_intf_net -intf_net smartconnect_1_M07_AXI [get_bd_intf_pins smartconnect_1/M07_AXI] [get_bd_intf_pins axi_output_read_adap_0/s_axi]

  # Create port connections
  connect_bd_net -net CEC_ext_noncache_data_addr [get_bd_pins core_extmem_cacheless_0/ext_noncache_data_addr] [get_bd_pins cores_to_AXI4_0/i_addr_1] [get_bd_pins ila_0/probe2]
  connect_bd_net -net CEC_ext_noncache_done [get_bd_pins core_extmem_cacheless_0/ext_noncache_done] [get_bd_pins cores_to_AXI4_0/i_done_core_1]
  connect_bd_net -net CEC_ext_noncache_wr [get_bd_pins core_extmem_cacheless_0/ext_noncache_wr] [get_bd_pins cores_to_AXI4_0/i_wr_1]
  connect_bd_net -net DMA_Controller_0_M_SPAD_SEL [get_bd_pins DMA_Controller_0/M_SPAD_SEL] [get_bd_pins axi_spad_write_adapt_0/i_spad_sel]
  connect_bd_net -net Instmem_ROM_douta [get_bd_pins qspi_inst_bootloader_0/inst_refill] [get_bd_pins instmem_xpm_0/inst_refill]
  connect_bd_net -net Net [get_bd_pins mig_7series_0/ui_clk] [get_bd_pins proc_sys_reset_1/slowest_sync_clk] [get_bd_pins smartconnect_1/aclk1]
  connect_bd_net -net axi_output_read_adap_0_o_or_rd_addr [get_bd_pins axi_output_read_adap_0/o_or_rd_addr] [get_bd_pins top_wrapper_0/i_or_addr]
  connect_bd_net -net axi_output_read_adap_0_o_or_rd_en [get_bd_pins axi_output_read_adap_0/o_or_rd_en] [get_bd_pins top_wrapper_0/i_or_read_en]
  connect_bd_net -net axi_spad_write_adapt_0_o_data_in [get_bd_pins axi_spad_write_adapt_0/o_data_in] [get_bd_pins top_wrapper_0/i_data_in]
  connect_bd_net -net axi_spad_write_adapt_0_o_spad_select [get_bd_pins axi_spad_write_adapt_0/o_spad_select] [get_bd_pins top_wrapper_0/i_spad_select]
  connect_bd_net -net axi_spad_write_adapt_0_o_write_addr [get_bd_pins axi_spad_write_adapt_0/o_write_addr] [get_bd_pins top_wrapper_0/i_write_addr]
  connect_bd_net -net axi_spad_write_adapt_0_o_write_en [get_bd_pins axi_spad_write_adapt_0/o_write_en] [get_bd_pins top_wrapper_0/i_write_en]
  connect_bd_net -net axi_spad_write_adapt_0_o_write_mask [get_bd_pins axi_spad_write_adapt_0/o_write_mask] [get_bd_pins top_wrapper_0/i_write_mask]
  connect_bd_net -net axi_uartlite_0_s_axi_rdata [get_bd_pins axi_uartlite_0/s_axi_rdata] [get_bd_pins process_rdata_0/data_i]
  connect_bd_net -net bootloader_for_data_0_done [get_bd_pins qspi_bootloader_0/done] [get_bd_pins core_nreset_new_0/bootload_data_done]
  connect_bd_net -net clk_1 [get_bd_ports clk] [get_bd_pins clk_wiz_0/clk_in1]
  connect_bd_net -net clk_wiz_0_clk_out1 [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins proc_sys_reset_0/slowest_sync_clk] [get_bd_pins axi_bram_ctrl_0/s_axi_aclk] [get_bd_pins axi_uartlite_0/s_axi_aclk] [get_bd_pins instmem_xpm_0/clk] [get_bd_pins cores_to_AXI4_0/clk] [get_bd_pins axi_quad_spi_0/s_axi_aclk] [get_bd_pins axi_quad_spi_0/ext_spi_clk] [get_bd_pins core_extmem_cacheless_0/clk] [get_bd_pins smartconnect_1/aclk] [get_bd_pins qspi_inst_bootloader_0/clk] [get_bd_pins ila_0/clk] [get_bd_pins ila_2/clk] [get_bd_pins axi_spad_write_adapt_0/aclk] [get_bd_pins qspi_bootloader_0/clk] [get_bd_pins axi_output_read_adap_0/clk] [get_bd_pins DMA_Controller_0/clk] [get_bd_pins top_wrapper_0/i_clk] [get_bd_pins systolic_csr_0/clk]
  connect_bd_net -net clk_wiz_0_clk_out2 [get_bd_pins clk_wiz_0/clk_out2] [get_bd_pins mig_7series_0/sys_clk_i]
  connect_bd_net -net clk_wiz_0_locked [get_bd_pins clk_wiz_0/locked] [get_bd_pins proc_sys_reset_0/dcm_locked]
  connect_bd_net -net core_extmem_cacheless_0_ext_inst_addr [get_bd_pins core_extmem_cacheless_0/ext_inst_addr] [get_bd_pins instmem_xpm_0/addr]
  connect_bd_net -net core_extmem_cacheless_0_ext_noncache_data_req [get_bd_pins core_extmem_cacheless_0/ext_noncache_data_req] [get_bd_pins cores_to_AXI4_0/i_req_core_1]
  connect_bd_net -net core_extmem_cacheless_0_ext_noncache_data_store [get_bd_pins core_extmem_cacheless_0/ext_noncache_data_store] [get_bd_pins cores_to_AXI4_0/i_data_core_1]
  connect_bd_net -net core_extmem_cacheless_0_ext_noncache_data_write [get_bd_pins core_extmem_cacheless_0/ext_noncache_data_write] [get_bd_pins cores_to_AXI4_0/i_dm_write_core_1]
  connect_bd_net -net core_extmem_cacheless_0_ext_noncache_rd [get_bd_pins core_extmem_cacheless_0/ext_noncache_rd] [get_bd_pins cores_to_AXI4_0/i_rd_1]
  connect_bd_net -net core_extmem_cacheless_0_ext_probe_atomic_data_from_ocm [get_bd_pins core_extmem_cacheless_0/ext_probe_atomic_data_from_ocm] [get_bd_pins ila_0/probe1]
  connect_bd_net -net core_extmem_cacheless_0_ext_probe_ext_noncache_data_valid [get_bd_pins core_extmem_cacheless_0/ext_probe_ext_noncache_data_valid] [get_bd_pins ila_0/probe0]
  connect_bd_net -net core_nreset_new_0_core_nreset [get_bd_pins core_nreset_new_0/core_nreset] [get_bd_pins core_extmem_cacheless_0/nrst]
  connect_bd_net -net cores_to_AXI4_0_o_data [get_bd_pins cores_to_AXI4_0/o_data] [get_bd_pins core_extmem_cacheless_0/ext_noncache_data_load]
  connect_bd_net -net cores_to_AXI4_0_o_grant_core_1 [get_bd_pins cores_to_AXI4_0/o_grant_core_1] [get_bd_pins core_extmem_cacheless_0/ext_noncache_data_gnt]
  connect_bd_net -net cores_to_AXI4_0_valid_data [get_bd_pins cores_to_AXI4_0/valid_data] [get_bd_pins core_extmem_cacheless_0/ext_noncache_data_valid]
  connect_bd_net -net cores_to_AXI4_0_valid_write_data [get_bd_pins cores_to_AXI4_0/valid_write_data] [get_bd_pins core_extmem_cacheless_0/ext_noncache_data_write_valid]
  connect_bd_net -net mig_7series_0_init_calib_complete [get_bd_pins mig_7series_0/init_calib_complete] [get_bd_ports init_calib_complete] [get_bd_pins core_nreset_new_0/init_calib_complete] [get_bd_pins qspi_data_nreset_0/init_calib_complete] [get_bd_pins systolic_csr_0/i_ddr_calib_done]
  connect_bd_net -net mig_7series_0_mmcm_locked [get_bd_pins mig_7series_0/mmcm_locked] [get_bd_pins proc_sys_reset_1/dcm_locked]
  connect_bd_net -net new_instmem_0_instruction [get_bd_pins instmem_xpm_0/instruction] [get_bd_pins core_extmem_cacheless_0/ext_inst_data]
  connect_bd_net -net nrst_1 [get_bd_ports nrst] [get_bd_pins clk_wiz_0/resetn] [get_bd_pins proc_sys_reset_0/ext_reset_in] [get_bd_pins mig_7series_0/sys_rst] [get_bd_pins proc_sys_reset_1/ext_reset_in]
  connect_bd_net -net proc_sys_reset_0_peripheral_aresetn [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins axi_bram_ctrl_0/s_axi_aresetn] [get_bd_pins axi_uartlite_0/s_axi_aresetn] [get_bd_pins instmem_xpm_0/nrst] [get_bd_pins cores_to_AXI4_0/nrst] [get_bd_pins axi_quad_spi_0/s_axi_aresetn] [get_bd_pins smartconnect_1/aresetn] [get_bd_pins qspi_data_nreset_0/nrst] [get_bd_pins qspi_inst_bootloader_0/nrst] [get_bd_pins axi_spad_write_adapt_0/aresetn] [get_bd_pins axi_output_read_adap_0/nrst] [get_bd_pins DMA_Controller_0/nrst] [get_bd_pins top_wrapper_0/i_nrst] [get_bd_pins systolic_csr_0/nrst]
  connect_bd_net -net proc_sys_reset_1_peripheral_aresetn [get_bd_pins proc_sys_reset_1/peripheral_aresetn] [get_bd_pins mig_7series_0/aresetn]
  connect_bd_net -net process_rdata_0_data_o [get_bd_pins process_rdata_0/data_o] [get_bd_pins smartconnect_1/M00_AXI_rdata]
  connect_bd_net -net process_wdata_0_data_o [get_bd_pins process_wdata_0/data_o] [get_bd_pins axi_uartlite_0/s_axi_wdata]
  connect_bd_net -net qspi_data_nreset_0_qspi_data_nrst [get_bd_pins qspi_data_nreset_0/qspi_data_nrst] [get_bd_pins qspi_bootloader_0/nrst]
  connect_bd_net -net qspi_inst_bootloader_0_bootload_done [get_bd_pins qspi_inst_bootloader_0/bootload_done] [get_bd_pins core_nreset_new_0/bootload_inst_done] [get_bd_pins qspi_data_nreset_0/qspi_inst_done]
  connect_bd_net -net qspi_inst_bootloader_0_valid [get_bd_pins qspi_inst_bootloader_0/valid] [get_bd_pins instmem_xpm_0/refill_valid]
  connect_bd_net -net smartconnect_1_M00_AXI_wdata [get_bd_pins smartconnect_1/M00_AXI_wdata] [get_bd_pins process_wdata_0/data_i]
  connect_bd_net -net systolic_csr_0_o_conv_mode [get_bd_pins systolic_csr_0/o_conv_mode] [get_bd_pins top_wrapper_0/i_conv_mode]
  connect_bd_net -net systolic_csr_0_o_depth_mult [get_bd_pins systolic_csr_0/o_depth_mult] [get_bd_pins top_wrapper_0/i_depth_mult]
  connect_bd_net -net systolic_csr_0_o_i_addr_end [get_bd_pins systolic_csr_0/o_i_addr_end] [get_bd_pins top_wrapper_0/i_i_addr_end]
  connect_bd_net -net systolic_csr_0_o_i_c_size [get_bd_pins systolic_csr_0/o_i_c_size] [get_bd_pins top_wrapper_0/i_i_c_size]
  connect_bd_net -net systolic_csr_0_o_i_size [get_bd_pins systolic_csr_0/o_i_size] [get_bd_pins top_wrapper_0/i_i_size]
  connect_bd_net -net systolic_csr_0_o_i_start_addr [get_bd_pins systolic_csr_0/o_i_start_addr] [get_bd_pins top_wrapper_0/i_i_start_addr]
  connect_bd_net -net systolic_csr_0_o_input_offset [get_bd_pins systolic_csr_0/o_input_offset] [get_bd_pins top_wrapper_0/i_input_offset]
  connect_bd_net -net systolic_csr_0_o_o_c_size [get_bd_pins systolic_csr_0/o_o_c_size] [get_bd_pins top_wrapper_0/i_o_c_size]
  connect_bd_net -net systolic_csr_0_o_o_size [get_bd_pins systolic_csr_0/o_o_size] [get_bd_pins top_wrapper_0/i_o_size]
  connect_bd_net -net systolic_csr_0_o_p_mode [get_bd_pins systolic_csr_0/o_p_mode] [get_bd_pins top_wrapper_0/i_p_mode]
  connect_bd_net -net systolic_csr_0_o_pad_h [get_bd_pins systolic_csr_0/o_pad_h] [get_bd_pins top_wrapper_0/i_pad_h]
  connect_bd_net -net systolic_csr_0_o_pad_w [get_bd_pins systolic_csr_0/o_pad_w] [get_bd_pins top_wrapper_0/i_pad_w]
  connect_bd_net -net systolic_csr_0_o_reg_clear [get_bd_pins systolic_csr_0/o_reg_clear] [get_bd_pins top_wrapper_0/i_reg_clear]
  connect_bd_net -net systolic_csr_0_o_route_en [get_bd_pins systolic_csr_0/o_route_en] [get_bd_pins top_wrapper_0/i_route_en]
  connect_bd_net -net systolic_csr_0_o_stride [get_bd_pins systolic_csr_0/o_stride] [get_bd_pins top_wrapper_0/i_stride]
  connect_bd_net -net systolic_csr_0_o_w_addr_end [get_bd_pins systolic_csr_0/o_w_addr_end] [get_bd_pins top_wrapper_0/i_w_addr_end]
  connect_bd_net -net systolic_csr_0_o_w_start_addr [get_bd_pins systolic_csr_0/o_w_start_addr] [get_bd_pins top_wrapper_0/i_w_start_addr]
  connect_bd_net -net systolic_csr_0_o_zero_point [get_bd_pins systolic_csr_0/o_zero_point] [get_bd_pins top_wrapper_0/i_zero_point]
  connect_bd_net -net top_wrapper_0_dbg_first_or_read_addr [get_bd_pins top_wrapper_0/dbg_first_or_read_addr] [get_bd_pins ila_2/probe12]
  connect_bd_net -net top_wrapper_0_dbg_first_or_read_data [get_bd_pins top_wrapper_0/dbg_first_or_read_data] [get_bd_pins ila_2/probe14]
  connect_bd_net -net top_wrapper_0_dbg_first_word [get_bd_pins top_wrapper_0/dbg_first_word] [get_bd_pins ila_2/probe8]
  connect_bd_net -net top_wrapper_0_dbg_first_word_addr [get_bd_pins top_wrapper_0/dbg_first_word_addr] [get_bd_pins ila_2/probe7]
  connect_bd_net -net top_wrapper_0_dbg_last_or_read_addr [get_bd_pins top_wrapper_0/dbg_last_or_read_addr] [get_bd_pins ila_2/probe13]
  connect_bd_net -net top_wrapper_0_dbg_last_or_read_data [get_bd_pins top_wrapper_0/dbg_last_or_read_data] [get_bd_pins ila_2/probe15]
  connect_bd_net -net top_wrapper_0_dbg_last_word [get_bd_pins top_wrapper_0/dbg_last_word] [get_bd_pins ila_2/probe10]
  connect_bd_net -net top_wrapper_0_dbg_last_word_addr [get_bd_pins top_wrapper_0/dbg_last_word_addr] [get_bd_pins ila_2/probe9]
  connect_bd_net -net top_wrapper_0_dbg_or_en [get_bd_pins top_wrapper_0/dbg_or_en] [get_bd_pins ila_2/probe17]
  connect_bd_net -net top_wrapper_0_dbg_or_read_count [get_bd_pins top_wrapper_0/dbg_or_read_count] [get_bd_pins ila_2/probe11]
  connect_bd_net -net top_wrapper_0_dbg_pe_en [get_bd_pins top_wrapper_0/dbg_pe_en] [get_bd_pins ila_2/probe18]
  connect_bd_net -net top_wrapper_0_dbg_route_en_from_ir [get_bd_pins top_wrapper_0/dbg_route_en_from_ir] [get_bd_pins ila_2/probe19]
  connect_bd_net -net top_wrapper_0_dbg_seen_done [get_bd_pins top_wrapper_0/dbg_seen_done] [get_bd_pins ila_2/probe5]
  connect_bd_net -net top_wrapper_0_dbg_seen_route_en [get_bd_pins top_wrapper_0/dbg_seen_route_en] [get_bd_pins ila_2/probe3]
  connect_bd_net -net top_wrapper_0_dbg_seen_word_valid [get_bd_pins top_wrapper_0/dbg_seen_word_valid] [get_bd_pins ila_2/probe4]
  connect_bd_net -net top_wrapper_0_dbg_top_state [get_bd_pins top_wrapper_0/dbg_top_state] [get_bd_pins ila_2/probe16]
  connect_bd_net -net top_wrapper_0_dbg_word_valid_count [get_bd_pins top_wrapper_0/dbg_word_valid_count] [get_bd_pins ila_2/probe6]
  connect_bd_net -net top_wrapper_0_o_done [get_bd_pins top_wrapper_0/o_done] [get_bd_pins ila_2/probe0] [get_bd_pins systolic_csr_0/i_done]
  connect_bd_net -net top_wrapper_0_o_or_data_out [get_bd_pins top_wrapper_0/o_or_data_out] [get_bd_pins axi_output_read_adap_0/i_or_rd_data]
  connect_bd_net -net top_wrapper_0_o_or_data_out_valid [get_bd_pins top_wrapper_0/o_or_data_out_valid] [get_bd_pins axi_output_read_adap_0/i_or_rd_valid]
  connect_bd_net -net top_wrapper_0_o_word [get_bd_pins top_wrapper_0/o_word] [get_bd_pins ila_2/probe2]
  connect_bd_net -net top_wrapper_0_o_word_valid [get_bd_pins top_wrapper_0/o_word_valid] [get_bd_pins ila_2/probe1]
  connect_bd_net -net xlconstant_0_dout [get_bd_pins xlconstant_0/dout] [get_bd_pins cores_to_AXI4_0/i_wr_2] [get_bd_pins cores_to_AXI4_0/i_rd_2] [get_bd_pins cores_to_AXI4_0/i_req_core_2] [get_bd_pins cores_to_AXI4_0/i_done_core_2]
  connect_bd_net -net xlconstant_2_dout [get_bd_pins xlconstant_2/dout] [get_bd_pins instmem_xpm_0/sel_ISR]
  connect_bd_net -net xlconstant_3_dout [get_bd_pins xlconstant_3/dout] [get_bd_pins qspi_bootloader_0/bram_data]

  # Create address segments
  assign_bd_address -offset 0x00010000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cores_to_AXI4_0/M_AXI] [get_bd_addr_segs DMA_Controller_0/s_axil/reg0] -force
  assign_bd_address -offset 0x00000000 -range 0x00001000 -target_address_space [get_bd_addr_spaces cores_to_AXI4_0/M_AXI] [get_bd_addr_segs axi_bram_ctrl_0/S_AXI/Mem0] -force
  assign_bd_address -offset 0x20000000 -range 0x00020000 -target_address_space [get_bd_addr_spaces cores_to_AXI4_0/M_AXI] [get_bd_addr_segs axi_output_read_adap_0/s_axi/reg0] -force
  assign_bd_address -offset 0x44A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cores_to_AXI4_0/M_AXI] [get_bd_addr_segs axi_quad_spi_0/AXI_LITE/Reg] -force
  assign_bd_address -offset 0xC0000000 -range 0x00020000 -target_address_space [get_bd_addr_spaces cores_to_AXI4_0/M_AXI] [get_bd_addr_segs axi_spad_write_adapt_0/s_axi/reg0] -force
  assign_bd_address -offset 0x40600000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cores_to_AXI4_0/M_AXI] [get_bd_addr_segs axi_uartlite_0/S_AXI/Reg] -force
  assign_bd_address -offset 0x80000000 -range 0x20000000 -target_address_space [get_bd_addr_spaces cores_to_AXI4_0/M_AXI] [get_bd_addr_segs mig_7series_0/memmap/memaddr] -force
  assign_bd_address -offset 0x00001000 -range 0x00001000 -target_address_space [get_bd_addr_spaces cores_to_AXI4_0/M_AXI] [get_bd_addr_segs systolic_csr_0/s_axil/reg0] -force
  assign_bd_address -offset 0x00010000 -range 0x00010000 -target_address_space [get_bd_addr_spaces qspi_bootloader_0/m] [get_bd_addr_segs DMA_Controller_0/s_axil/reg0] -force
  assign_bd_address -offset 0x00000000 -range 0x00001000 -target_address_space [get_bd_addr_spaces qspi_bootloader_0/m] [get_bd_addr_segs axi_bram_ctrl_0/S_AXI/Mem0] -force
  assign_bd_address -offset 0x20000000 -range 0x00020000 -target_address_space [get_bd_addr_spaces qspi_bootloader_0/m] [get_bd_addr_segs axi_output_read_adap_0/s_axi/reg0] -force
  assign_bd_address -offset 0x44A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces qspi_bootloader_0/m] [get_bd_addr_segs axi_quad_spi_0/AXI_LITE/Reg] -force
  assign_bd_address -offset 0xC0000000 -range 0x40000000 -target_address_space [get_bd_addr_spaces qspi_bootloader_0/m] [get_bd_addr_segs axi_spad_write_adapt_0/s_axi/reg0] -force
  assign_bd_address -offset 0x40600000 -range 0x00010000 -target_address_space [get_bd_addr_spaces qspi_bootloader_0/m] [get_bd_addr_segs axi_uartlite_0/S_AXI/Reg] -force
  assign_bd_address -offset 0x80000000 -range 0x20000000 -target_address_space [get_bd_addr_spaces qspi_bootloader_0/m] [get_bd_addr_segs mig_7series_0/memmap/memaddr] -force
  assign_bd_address -offset 0x00001000 -range 0x00001000 -target_address_space [get_bd_addr_spaces qspi_bootloader_0/m] [get_bd_addr_segs systolic_csr_0/s_axil/reg0] -force
  assign_bd_address -offset 0x00010000 -range 0x00010000 -target_address_space [get_bd_addr_spaces qspi_inst_bootloader_0/m] [get_bd_addr_segs DMA_Controller_0/s_axil/reg0] -force
  assign_bd_address -offset 0x00000000 -range 0x00001000 -target_address_space [get_bd_addr_spaces qspi_inst_bootloader_0/m] [get_bd_addr_segs axi_bram_ctrl_0/S_AXI/Mem0] -force
  assign_bd_address -offset 0x20000000 -range 0x00020000 -target_address_space [get_bd_addr_spaces qspi_inst_bootloader_0/m] [get_bd_addr_segs axi_output_read_adap_0/s_axi/reg0] -force
  assign_bd_address -offset 0x44A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces qspi_inst_bootloader_0/m] [get_bd_addr_segs axi_quad_spi_0/AXI_LITE/Reg] -force
  assign_bd_address -offset 0xC0000000 -range 0x40000000 -target_address_space [get_bd_addr_spaces qspi_inst_bootloader_0/m] [get_bd_addr_segs axi_spad_write_adapt_0/s_axi/reg0] -force
  assign_bd_address -offset 0x40600000 -range 0x00010000 -target_address_space [get_bd_addr_spaces qspi_inst_bootloader_0/m] [get_bd_addr_segs axi_uartlite_0/S_AXI/Reg] -force
  assign_bd_address -offset 0x80000000 -range 0x20000000 -target_address_space [get_bd_addr_spaces qspi_inst_bootloader_0/m] [get_bd_addr_segs mig_7series_0/memmap/memaddr] -force
  assign_bd_address -offset 0x00001000 -range 0x00001000 -target_address_space [get_bd_addr_spaces qspi_inst_bootloader_0/m] [get_bd_addr_segs systolic_csr_0/s_axil/reg0] -force
  assign_bd_address -offset 0x00010000 -range 0x00010000 -target_address_space [get_bd_addr_spaces DMA_Controller_0/M_AXI] [get_bd_addr_segs DMA_Controller_0/s_axil/reg0] -force
  assign_bd_address -offset 0x00000000 -range 0x00001000 -target_address_space [get_bd_addr_spaces DMA_Controller_0/M_AXI] [get_bd_addr_segs axi_bram_ctrl_0/S_AXI/Mem0] -force
  assign_bd_address -offset 0x20000000 -range 0x00020000 -target_address_space [get_bd_addr_spaces DMA_Controller_0/M_AXI] [get_bd_addr_segs axi_output_read_adap_0/s_axi/reg0] -force
  assign_bd_address -offset 0x44A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces DMA_Controller_0/M_AXI] [get_bd_addr_segs axi_quad_spi_0/AXI_LITE/Reg] -force
  assign_bd_address -offset 0xC0000000 -range 0x40000000 -target_address_space [get_bd_addr_spaces DMA_Controller_0/M_AXI] [get_bd_addr_segs axi_spad_write_adapt_0/s_axi/reg0] -force
  assign_bd_address -offset 0x40600000 -range 0x00010000 -target_address_space [get_bd_addr_spaces DMA_Controller_0/M_AXI] [get_bd_addr_segs axi_uartlite_0/S_AXI/Reg] -force
  assign_bd_address -offset 0x80000000 -range 0x20000000 -target_address_space [get_bd_addr_spaces DMA_Controller_0/M_AXI] [get_bd_addr_segs mig_7series_0/memmap/memaddr] -force
  assign_bd_address -offset 0x00001000 -range 0x00001000 -target_address_space [get_bd_addr_spaces DMA_Controller_0/M_AXI] [get_bd_addr_segs systolic_csr_0/s_axil/reg0] -force


  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""


