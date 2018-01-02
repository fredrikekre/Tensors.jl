#!/bin/bash

git checkout master
julia-master -e 'dir = pwd()
                 include(joinpath(dir, "src/Tensors.jl")); using Tensors
                 include(joinpath(dir, "benchmark/runbenchmarks.jl"))
                 run_benchmarks("master")'

git checkout fe/simd-promotions
julia-master -e 'dir = pwd()
                 include(joinpath(dir, "src/Tensors.jl")); using Tensors
                 include(joinpath(dir, "benchmark/runbenchmarks.jl"))
                 run_benchmarks("PR")
                 generate_report("PR", "master")'
