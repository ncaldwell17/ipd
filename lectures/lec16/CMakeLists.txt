cmake_minimum_required(VERSION 3.3)
project(lec16 CXX)
include(.ipd/CMakeLists.txt)

add_test_program(hash_test
        test/hash_test.cpp
        src/Sbox_hash.h src/Sbox_hash.cpp)

add_test_program(bf_test
        test/bf_test.cpp
        src/Bloom_filter.h src/Bloom_filter.cpp
        src/Sbox_hash.h src/Sbox_hash.cpp)

add_test_program(list_test
        test/list_test.cpp
        src/Cons_list.h src/Cons_list.cpp)

add_test_program(vec_test
        test/vec_test.cpp
        src/My_vec.h)

add_test_program(queue_test
        test/queue_test.cpp
        src/SP_queue.h src/RP_queue.h src/UP_queue.h)
