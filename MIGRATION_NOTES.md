# Migration Notes

## Source and Destination

- Original archive: `C:\Users\kccistc\Desktop\Project`
- Curated copy: `C:\Users\kccistc\Desktop\Project-Portfolio`
- The original archive was read only and remains unchanged.
- Git metadata was not copied. The curated folder can be initialized or copied into a repository separately.

## What Was Kept

- Verilog/SystemVerilog RTL
- Testbench and UVM source
- XDC constraints
- Processor memory initialization files
- Vitis application, Driver, and HAL source
- Vivado block design and XCI metadata needed to understand the AXI system
- Original Vivado XPR files and their matching `.srcs` directories
- Makefiles, file lists, and editable Draw.io diagrams
- Original project presentation files in PPTX format
- Python application source

## What Was Excluded

- Vivado `.cache`, `.gen`, `.runs`, `.sim`, `.Xil`, hardware export, and logs
- VCS/Verdi `csrc`, `simv.daidir`, coverage databases, wave databases, and logs
- Vitis BSP, workspace metadata, object files, libraries, ELF/BIN outputs, and debug builds
- ONNX and TensorRT engine binaries
- The original `.git` directory

The excluded files remain available in the original archive. PPTX reports are included as requested,
but selected slides should ideally also be exported to PNG/PDF for quick GitHub review. Model binaries
should be published as release assets or documented with a download/build procedure.

## Normalization Decisions

- Project directories were renamed to two-digit, lowercase, hyphenated names.
- RTL, testbench, constraints, firmware, scripts, and documentation were separated by role.
- Original XPR bundles retain their original `.srcs` directory names so relative XPR references have the best chance of resolving.
- `tmp_edit_project.xpr` is retained for completeness but is a temporary Vivado editing project, not the primary AXI project.
- `01-stopwatch-clock/rtl/stopwatch_top.v` was copied from the original `Top_counter.v`; the module name was not changed.
- The original UART project referenced files outside its project directory. Matching dependencies available in projects 1 and 3 were copied into `02-uart-clock/rtl` to make the curated source set easier to inspect.
- RV32I files referenced by the active XPR were preferred. Older imported variants were retained under `04-rv32i-processor/*/legacy` for comparison.
- No HDL build, FPGA synthesis, UVM simulation, or Python inference was rerun during this file-only migration.

## Before Publishing

1. Add your real name and contact link to the GitHub profile.
2. Export representative PPTX slides and add architecture, waveform, coverage, and FPGA result images under each `docs/` directory.
3. Confirm the exact individual contribution for every team project.
4. Record tool and board versions used for each project.
5. Re-run representative simulations and replace README result placeholders with measured evidence.
6. Decide licensing per project after checking teammate and vendor code ownership.
