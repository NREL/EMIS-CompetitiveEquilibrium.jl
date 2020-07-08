struct TransmissionOperations{R,T,P}

    labels::Vector{Pair{Int,Int}}

    # Parameters

    limits::Vector{Float64}

    # Variables

    flows::Array{VariableRef,3} # (i x t x p)

    # Expressions

    exports::Array{ExpressionRef,3} # (r x t x p)

    # Constraints

    maxflow_forward::Array{<:ConstraintRef,3} # (i x t x p)
    maxflow_back::Array{<:ConstraintRef,3}

end

function setup!(
    tx::TransmissionOperations{R,T,P}
    m::Model, periodweights::Vector{Float64})

    interfaces = 1:length(tx.labels)
    regions = 1:R
    timesteps = 1:T
    periods = 1:P

    # Variables

    tx.flows .=
        @variable(m, [i in interfaces, t in timesteps, p in periods])

    # Expressions

    tx.exports .=
        @expression(m, [r in regions, t in timesteps, p in periods],
                    sum(flowout(r, l, tx.flows[i,t,p])
                        for (i, l) in enumerate(tx.labels)))

    # Constraints

    tx.maxflow_forward .=
        @constraint(m, [i in interfaces, t in timesteps, p in periods],
                    tx.flows[i] <= tx.limits[i,t,p])

    tx.maxflow_back .=
        @constraint(m, [i in interfaces, t in timesteps, p in periods],
                    -tx.limits[i] <= tx.flows[i,t,p])

end

flowout(r::Int, label::Pair{Int,Int}, x) =
    if r == first(label)
        x
    elseif r == second(label)
        -x
    else
        zero(x)
    end
