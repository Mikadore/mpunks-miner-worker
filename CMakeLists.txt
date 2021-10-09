cmake_minimum_required(VERSION 3.8)
project(mpunks_miner_worker)

enable_language(CUDA)

add_executable(mpunks-miner-worker mpunks-miner-worker-vs/kernel.cu mpunks-miner-worker-vs/getopt.c)

target_include_directories(mpunks-miner-worker PRIVATE mpunks-miner-worker-vs)

set_target_properties(mpunks-miner-worker PROPERTIES LINK_SEARCH_START_STATIC 1)
set_target_properties(mpunks-miner-worker PROPERTIES LINK_SEARCH_END_STATIC 1)

find_library(GMP_LIBRARY NAMES gmp libgmp PATHS "${GMP_DIR}")

target_link_libraries(mpunks-miner-worker PRIVATE gmp)