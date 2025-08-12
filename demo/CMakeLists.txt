cmake_minimum_required(VERSION 3.29)
cmake_policy(SET CMP0074 NEW)
project(tt_r0)

find_package(verilator HINTS $ENV{VERILATOR_ROOT} ${VERILATOR_ROOT})
if (NOT verilator_FOUND)
	message(
		FATAL_ERROR
		"Verilator was not found. Either install it, or set the VERILATOR_ROOT environment variable"
	)
endif ()

find_package(SDL3 REQUIRED)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

add_executable(tt_r0 main.cpp)
target_compile_features(tt_r0 PUBLIC cxx_std_23)
include_directories(${SDL3_INCLUDE_DIRS})
target_link_libraries(tt_r0 PUBLIC ${SDL3_LIBRARIES})

verilate(tt_r0 COVERAGE TRACE_FST
	INCLUDE_DIRS "../src"
	VERILATOR_ARGS -DDEMO
	SOURCES ../src/project.sv
)
