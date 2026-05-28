# ============================================================================
# ModelSim Compile Script
# File Name: compile.do
# Description: Creates work library and compiles all RTL and Testbench files.
# ============================================================================

# 1. Create and map the work library
if [file exists work] {
    vdel -all
}
vlib work
vmap work work

# 2. Compile RTL and Testbench files
vlog "../rtl/*.v"
vlog "../tb/*.v"

echo "=========================================================="
echo "    COMPILATION COMPLETED SUCCESSFULLY WITHOUT ERRORS    "
echo "=========================================================="
