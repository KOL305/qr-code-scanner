cmake_minimum_required(VERSION 3.0)
project(api LANGUAGES CXX C)
add_library(api
  SHARED
  ./api.cpp
)

add_subdirectory("./libs")