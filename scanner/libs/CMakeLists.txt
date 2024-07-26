# cmake_minimum_required(VERSION 3.0)


cmake_minimum_required(VERSION 3.4.1)

project(api LANGUAGES CXX C)
add_library(api
  SHARED
  ./api.cpp
)

project(api_gmp)

# Manually specify the paths to the GMP include directory and library
set(GMP_INCLUDE_DIR "/c/Users/kadon/Programming/libs/gmp/include")
set(GMP_LIBRARY "/c/Users/kadon/Programming/libs/gmp/lib/libgmp.a")

# Include directories
include_directories(${GMP_INCLUDE_DIR})

# Add library
add_library(api_gmp SHARED api_gmp.cpp)

# Link GMP library
target_link_libraries(api_gmp ${GMP_LIBRARY})


#add_subdirectory("./libs")