for TensorType in (SymmetricTensor, Tensor)
    @eval begin
        @generated function Base.diagm{order, dim}(Tt::Type{$(TensorType){order, dim}}, v::Union{AbstractVector, Tuple})
            if order == 2
                f = (i,j) -> i == j ? :(v[$i]) : :($(zero(eltype(v))))
            elseif order == 4
                f = (i,j,k,l) -> i == k && j == l ? :(v[$i]) : :($(zero(eltype(v))))
            else
                throw(ArgumentError("diagm only defined for tensors of order 2 and 4"))
            end
            exp = tensor_create(get_type(Tt),f)
            return quote
                $(Expr(:meta, :inline))
                @inbounds t = $exp
                $($TensorType){order, dim}(t)
            end
        end

        @generated function Base.diagm{order, dim, T}(Tt::Type{$(TensorType){order, dim}}, v::T)
            if order == 2
                f = (i,j) -> i == j ? :(v) : :($(zero(T)))
            elseif order == 4
                f = (i,j,k,l) -> i == k && j == l ? :(v) : :($(zero(T)))
            else
                throw(ArgumentError("diagm only defined for tensors of order 2 and 4"))
            end
            exp = tensor_create(get_type(Tt),f)
            return quote
                $(Expr(:meta, :inline))
                $($TensorType){order, dim}($exp)
            end
        end
    end
end