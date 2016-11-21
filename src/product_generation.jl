export @pg

macro pg(ex)
    freeidx, sumidx, tensororders = tensor_parser(ex)
end

immutable DecomposedTensor
    name::Symbol
    indices::Vector{Symbol}
end

function tensor_parser(ex)
    tensororders = Int[]
    freeidx = Symbol[] # free indices
    sumidx = Symbol[] # summation index

    ex.head == :call || throw(ArgumentError("head not a call"))
    ex.args[1] == :* || throw(ArgumentError("head not a *"))
    for t in ex.args[2:end]
        t.head == :ref || throw(ArgumentError("head not a ref"))
        push!(tensororders, length(t.args)-1)
        for idx in t.args[2:end]
            isfree = findfirst(freeidx, idx)
            if idx in sumidx
                throw(ArgumentError("too many sum idx"))
            elseif isfree == 0
                push!(freeidx, idx)
            else
                push!(sumidx, idx)
                deleteat!(freeidx, isfree)
            end
        end
    end
    return freeidx, sumidx, tensororders
end

function lul(name)
    a = quote
        @generated function $(name){dim}(S1::SymmetricTensor{4, dim}, S2::Tensor{2, dim})
            idx1(i) = i
            idx2(i,j) = compute_index(Tensor{2, dim}, i, j)
            idx4(i,j,k,l) = compute_index(Tensor{4, dim}, i, j, k, l)

            exps = Expr(:tuple)

            freeloop = Expr(:for)
            for j in 1:dim, i in j:dim # free loop
                exps_ele = Expr[]
                for l in 1:dim, k in 1:dim # summation index loop
                    push!(exps_ele, :(data4[$(idx4(i, j, k, l))] * data2[$(idx2(k, l))]))
                end
                push!(exps.args, reduce((ex1,ex2) -> :(+($ex1, $ex2)), exps_ele))
            end
            quote
                $(Expr(:meta, :inline))
                data2 = get_data(S2)
                data4 = get_data(S1)
                @inbounds r = $exps
                SymmetricTensor{2, dim}(r)
            end
        end
    end
    return eval(a)
end