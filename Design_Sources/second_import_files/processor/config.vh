`ifndef CONFIG_VH		// Guard prevents header file from being included more than once
`define CONFIG_VH

`define FEATURE_MULT
`define FEATURE_DIV
// `define FEATURE_XILINX_DATAMEM_IP_GEN
// `define FEATURE_XILINX_BUFFER_IP

// `define FEATURE_INTERRUPT_ENABLE             // Exposes interrupt signal lines
`define FEATURE_INST_TRACE_ENABLE               // Exposes current IF and ID STAGE instructions
// `define FEATURE_BIT_ENABLE                      // Set this to have 32 bit write enables instead of 4 byte write enables 

`define REPO_LOCATION        "C:/Users/Aaron/CoE_199_Digi_AI/Design_Sources/second_import_files/"
`define TEST_LOCATION        "assembly-tests/riscv-compliance/"

`endif