cmake_minimum_required(VERSION 3.3)
project(lec18 CXX)
include(.ipd/CMakeLists.txt)

add_test_program(deque_test
        test/deque_test.cpp
        src/Deque.h
        src/Sentinel.h)

