#!/bin/bash

# === Show help if no args or help requested ===
if [ "$#" -eq 0 ] || [ "$1" == "help" ]; then
    usage() {
        echo "Usage:"
        echo "  ./run_script help                    - Show this message"
        echo "  ./run_script mkdirs                  - Create all required source directories"
        echo "  ./run_script commit                  - Copy files from new_* folders into RTL/TB/VSIM"
        echo "  ./run_script revert                  - Revert to files from confirmed_* folders"
        echo "  ./run_script confirm_merge           - Overwrite confirmed_* folders with new_* folders"
        echo "  ./run_script build <project> [-spi|-spi-ps]  - Configure and build the specified project"
       
        exit 1
    }
    usage
fi

# === Safe build directory creation ===
if [ -f "./build" ]; then
    echo "Error: A file named 'build' exists in sw/. Please remove or rename it."
    exit 1
fi
mkdir -p "./build"

# === Path setup ===
WORKBENCH="./workbench"
CONFIRMED="$WORKBENCH/confirmed"
VSIM_TARGET="../vsim"
VSIM_VCOMPILE_DEST="$VSIM_TARGET/vcompile/rtl"
DEST_DIR_RTL="../rtl"
DEST_DIR_TB="../tb"

REQUIRED_DIRS=(
    "$WORKBENCH/new_rtl"
    "$WORKBENCH/new_tb"
    "$WORKBENCH/new_vsim_compile"
    "$CONFIRMED/confirmed_rtl"
    "$CONFIRMED/confirmed_tb"
    "$CONFIRMED/confirmed_vsim_compile"
    "$CONFIRMED/original_vsim"
)

# === mkdirs ===
if [ "$1" == "mkdirs" ]; then
    CREATED=0
    for dir in "${REQUIRED_DIRS[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            echo "Created: $dir"
            CREATED=1
        fi
    done
    mkdir -p "$WORKBENCH/new_rtl/components"
    mkdir -p "$CONFIRMED/confirmed_rtl/components"

    if [ "$CREATED" -eq 0 ]; then
        echo "All source directories already exist."
    else
        echo "Source directory setup complete (including components/)."
    fi
    exit 0
fi

# === confirm_merge ===
if [ "$1" == "confirm_merge" ]; then
    echo "Merging new_* folders into confirmed_* folders..."

    mkdir -p "$CONFIRMED/confirmed_rtl/components"
    mkdir -p "$CONFIRMED/confirmed_tb"
    mkdir -p "$CONFIRMED/confirmed_vsim_compile"

    cp -rf "$WORKBENCH/new_rtl"/. "$CONFIRMED/confirmed_rtl"/
    cp -rf "$WORKBENCH/new_tb"/. "$CONFIRMED/confirmed_tb"/
    cp -rf "$WORKBENCH/new_vsim_compile"/. "$CONFIRMED/confirmed_vsim_compile"/

    echo "Merge completed."
    exit 0
fi

# === build <project> [-spi] ===
if [ "$1" == "build" ]; then
    if [ -z "$2" ]; then
        echo "Usage: ./run_script build <project_name> [-spi]"
        exit 1
    fi

    PROJECT_NAME="$2"
    VSIM_MODE="vsim"
    if [ "$3" == "-spi" ]; then
        VSIM_MODE="vsim.spi"
    fi
    
    if [ "$3" == "-spi-ps" ]; then
    VSIM_MODE="vsim.spi.ps"
	fi


    if [ ! -f setup2022.efd ]; then
        echo "Error: setup2022.efd not found in sw/"
        exit 1
    fi

    if [ ! -f cmake_configure.riscv.gcc.sh ]; then
        echo "Error: cmake_configure.riscv.gcc.sh not found in sw/"
        exit 1
    fi

    cp setup2022.efd ./build/ || { echo "Failed to copy setup2022.efd"; exit 1; }
    cp cmake_configure.riscv.gcc.sh ./build/ || { echo "Failed to copy cmake_configure script"; exit 1; }

    cd ./build || exit 1
    make clean

    source setup2022.efd || { echo "Failed to source setup2022.efd"; exit 1; }
    source cmake_configure.riscv.gcc.sh || { echo "Failed to source cmake_configure.riscv.gcc.sh"; exit 1; }

    make "${PROJECT_NAME}.read" && echo "${PROJECT_NAME}.read completed." || echo "make ${PROJECT_NAME}.read failed."
    make vcompile && echo "vcompile completed." || echo "make vcompile failed."
    make "${PROJECT_NAME}.${VSIM_MODE}" && echo "${PROJECT_NAME}.${VSIM_MODE} completed." || echo "make ${PROJECT_NAME}.${VSIM_MODE} failed."

    exit 0
fi

# === commit or revert ===
case "$1" in
    commit)
        SOURCE_RTL="$WORKBENCH/new_rtl"
        SOURCE_TB="$WORKBENCH/new_tb"
        SOURCE_VCOMPILE_DIR="$WORKBENCH/new_vsim_compile"
        VSIM_BASE_SOURCE="$CONFIRMED/original_vsim"
        ;;
    revert)
        SOURCE_RTL="$CONFIRMED/confirmed_rtl"
        SOURCE_TB="$CONFIRMED/confirmed_tb"
        SOURCE_VCOMPILE_DIR="$CONFIRMED/confirmed_vsim_compile"
        VSIM_BASE_SOURCE="$CONFIRMED/original_vsim"
        ;;
    *)
        echo "Unknown argument: $1"
        echo "Use './run_script help' for a list of valid commands."
        exit 1
        ;;
esac

# === check for missing source dirs ===
SKIP_OPERATIONS=0
for dir in "$SOURCE_RTL" "$SOURCE_TB" "$SOURCE_VCOMPILE_DIR" "$VSIM_BASE_SOURCE"; do
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        echo "Created: $dir"
        SKIP_OPERATIONS=1
    fi
done

if [ "$SKIP_OPERATIONS" -eq 1 ]; then
    echo "One or more source directories were missing and have been created."
    echo "No operations will be performed in this run."
    exit 0
fi

# === VSIM cleanup and base copy ===
rm -rf "$VSIM_TARGET"/*
mkdir -p "$VSIM_TARGET"
cp -r "$VSIM_BASE_SOURCE"/* "$VSIM_TARGET"/ && echo "VSIM setup updated." || echo "Failed to update VSIM."

# === Copy vcompile folder contents ===
mkdir -p "$VSIM_VCOMPILE_DEST"
cp -rf "$SOURCE_VCOMPILE_DIR"/. "$VSIM_VCOMPILE_DEST"/ 2>/dev/null
echo "vcompile folder contents copied."

# === Copy RTL folder and all contents (including subfolders like components) ===
if [ -d "$SOURCE_RTL" ]; then
    cp -rf "$SOURCE_RTL"/. "$DEST_DIR_RTL"/ && echo "RTL folder copied." || echo "Failed to copy RTL folder."
else
    echo "No RTL folder found. Skipped."
fi

# === Copy TB files ===
if [ "$(ls -A "$SOURCE_TB" 2>/dev/null)" ]; then
    for file in "$SOURCE_TB"/*; do
        filename=$(basename "$file")
        cp -f "$file" "$DEST_DIR_TB"/ && echo "$filename copied" || echo "failed to copy $filename"
    done
else
    echo "No testbench files found. Skipped."
fi

echo "Script finished."
