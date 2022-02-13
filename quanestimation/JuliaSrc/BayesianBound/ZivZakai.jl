trace_norm(X::AbstractMatrix{<:Number}) = norm(X|>svdvals, 1)

trace_norm(ρ::AbstractMatrix{<:Number}, σ::AbstractMatrix{<:Number}) = trace_norm(ρ-σ)

function fidelity(ρ::AbstractMatrix{<:Number}, σ::AbstractMatrix{<:Number})
    return (ρ|>sqrt)*σ*(ρ|>sqrt)|>sqrt|>tr|>real|>x->x^2
end # fidelity for density matrixes

function fidelity(ψ::AbstractVector{<:Number}, ϕ::AbstractVector{<:Number})
    overlap = ψ'ϕ
    return overlap'overlap
end  # fidelity for pure states

# Helstorm bound of error probability for the hypothesis testing problem 
function helstrom_bound(ρ::AbstractMatrix{<:Number},σ::AbstractMatrix{<:Number},ν=1,P0=0.5)
    return (1-trace_norm(P0*ρ-(1-P0)*σ))/2 |> real 
end

function helstrom_bound(ψ::AbstractVector{<:Number},ϕ::AbstractVector{<:Number},ν=1)
    return (1-sqrt(1-fidelity(ψ, ϕ))^ν)/2 |> real 
end

prior_uniform(W=1., μ=0.) = x -> abs(x-μ)>abs(W/2) ? 0 : 1/W

function QZZB(
    x::AbstractVector,
    p::AbstractVector,
    rho::AbstractVecOrMat,
    accuracy=1e-8;
    ν::Number=1)

    τ = x .- x[1]
    N = length(x)
    I = trapz(τ, [τ[i]*trapz(x[1:N-i],
        [2*min(p[j],p[j+i])*helstrom_bound(rho[j],rho[j+i],ν) for j in 1:N-i])
        for i in 1:N])

    return 0.5*I|>real
end  # Quantum Ziv-Zakai bound for equally likely hypotheses without valley-filling

function QZZB(
    x::AbstractVector,
    p::AbstractVector,
    rho::AbstractVecOrMat,
    ::Type{Val{:opt}},
    accuracy=1e-8;
    ν::Number=1)

    τ = x .- x[1]
    N = length(x)
    I = trapz(τ, [τ[i]*trapz(x[1:N-i],
        [max([2*min(p[j],p[j+k])*helstrom_bound(rho[j],rho[j+k],ν) for k in 1:N-j]...)
        for j in 1:N-i]) for i in 1:N])
        
    return I
end  # Quantum Ziv-Zakai bound for equally likely hypotheses with valley-filling
