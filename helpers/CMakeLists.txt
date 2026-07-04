# cmake_minimum_required(VERSION 3.16)
# project(honest_helpers CXX)

# set(CMAKE_CXX_STANDARD 20)
# set(CMAKE_CXX_STANDARD_REQUIRED ON)

# # Отдаёт compile_commands.json — по нему clangd/IntelliSense в VSCode
# # понимает проект без ручной настройки.
# set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# if(NOT CMAKE_BUILD_TYPE)
#     set(CMAKE_BUILD_TYPE Release)   # = -O2, как в g++-команде
# endif()

# add_executable(honest-updates-sort honest-updates-sort.cpp)
add_executable(sort honest-updates-sort.cpp)
