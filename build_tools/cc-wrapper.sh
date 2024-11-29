#!/bin/bash

# Required variables
BUILD_STAGE=${BUILD_STAGE:-build/stage}  # Default if not defined
DEFAULT_ENTITLEMENTS="/Procursus-roothide/build_misc/entitlements/general.xml"  # Default entitlements file

# Parse options to identify an executable
IS_EXECUTABLE=true
OUTPUT_FILE="a.out"  # Default value if -o is not specified

for arg in "$@"; do
    case $arg in
        -c) IS_EXECUTABLE=false ;;    # -c flag means it is not an executable
        -o) OUTPUT_FILE_NEXT=true ;;  # Identify the output file
        *)
            if [ "$OUTPUT_FILE_NEXT" = true ]; then
                OUTPUT_FILE="$arg"
                OUTPUT_FILE_NEXT=false
            fi
            ;;
    esac
done

# Determine the real compiler (gcc or g++)
REAL_COMPILER=$(basename "$0")
if [ "$REAL_COMPILER" = "cc-wrapper.sh" ]; then
    REAL_COMPILER="clang"  # Default to g++ if used as CXX wrapper
fi

# Use the actual compiler to compile the code
if ! "$REAL_COMPILER" "$@"; then
    exit 1 # Exit with an error if compilation fails
fi

# Check if the output is an executable and sign it
if [ "$IS_EXECUTABLE" = true ] && [ -x "$OUTPUT_FILE" ] && [ "$OUTPUT_FILE" != "tic" ]; then
    # Determine entitlements file to use
    ENTITLEMENTS_FILE="${SIGN_ENTITLEMENTS:-$DEFAULT_ENTITLEMENTS}"

    # Use ldid and fastPathSign for signing
    ldid -S"${ENTITLEMENTS_FILE}" "$OUTPUT_FILE"
    
    # Fast path signing
    /basebin/fastPathSign "$(jbroot $OUTPUT_FILE)"
fi
