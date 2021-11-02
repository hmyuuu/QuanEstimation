function liouville_commu(H) 
    kron(one(H), H) - kron(H |> transpose, one(H))
end

function liouville_dissip(Γ)
    kron(Γ |> conj, Γ) - 0.5 * kron((Γ |> transpose) * (Γ |> conj), Γ |> one) - 0.5 * kron(Γ |> one, Γ' * Γ)
end

function liouville_commu_py(A::Array{T}) where {T <: Complex}
    dim = size(A)[1]
    result = zeros(T, dim^2, dim^2)
    @inbounds for i in 1:dim
        @inbounds for j in 1:dim
            @inbounds for k in 1:dim
                ni = dim * (i - 1) + j
                nj = dim * (k - 1) + j
                nk = dim * (i - 1) + k

                result[ni,nj] = A[i,k]
                result[ni,nk] = -A[k,j]
                result[ni,ni] = A[i,i] - A[j,j]
            end
        end
    end
    result
end

function liouville_dissip_py(A::Array{T}) where {T <: Complex}
    dim = size(A)[1]
    result =  zeros(T, dim^2, dim^2)
    @inbounds for i = 1:dim
        @inbounds for j in 1:dim
            ni = dim * (i - 1) + j
            @inbounds for k in 1:dim
                @inbounds for l in 1:dim 
                    nj = dim * (k - 1) + l
                    L_temp = A[i,k] * conj(A[j,l])
                    @inbounds for p in 1:dim
                        L_temp -= 0.5 * float(k == i) * A[p,j] * conj(A[p,l]) + 0.5 * float(l == j) * A[p,k] * conj(A[p,i])
                    end
                    result[ni,nj] = L_temp
                end
            end 
        end
    end
    result[findall(abs.(result) .< 1e-10)] .= 0.
    result
end

function dissipation(Γ::Vector{Matrix{T}}, γ::Vector{R}, t::Int=0) where {T <: Complex,R <: Real}
    [γ[i] * liouville_dissip(Γ[i]) for i in 1:length(Γ)] |> sum
end

function dissipation(Γ::Vector{Matrix{T}}, γ::Vector{Vector{R}}, t::Int=0) where {T <: Complex,R <: Real}
    [γ[i][t] * liouville_dissip(Γ[i]) for i in 1:length(Γ)] |> sum
end

function free_evolution(H0)
    -1.0im * liouville_commu(H0)
end

function liouvillian(H::Matrix{T}, Liouville_operator::Vector{Matrix{T}}, γ, t::Real) where {T <: Complex} 
    freepart = liouville_commu(H)
    dissp = norm(γ) +1 ≈ 1 ? freepart|>zero : dissipation(Liouville_operator, γ, t)
    -1.0im * freepart + dissp
end

function Htot(H0::Matrix{T}, control_Hamiltonian::Vector{Matrix{T}}, control_coefficients::Vector{Vector{R}}) where {T <: Complex, R}
    Htot = [H0] .+  ([control_coefficients[i] .* [control_Hamiltonian[i]] for i in 1:length(control_coefficients)] |> sum )
end

function Htot(H0::Matrix{T}, control_Hamiltonian::Vector{Matrix{T}}, control_coefficients::Vector{R}) where {T <: Complex, R<:Real}
    Htot = H0 + ([control_coefficients[i] * control_Hamiltonian[i] for i in 1:length(control_coefficients)] |> sum )
end

function evolute(H, Liouville_operator, γ, dt, tj)
    Ld = dt * liouvillian(H, Liouville_operator, γ, tj)
    exp(Ld)
end

function propagate(H0::Matrix{T}, ∂H_∂x::Vector{Matrix{T}},  ρ_initial::Matrix{T}, Liouville_operator::Vector{Matrix{T}},
                   γ, control_Hamiltonian::Vector{Matrix{T}}, control_coefficients::Vector{Vector{R}}, times) where {T <: Complex,R <: Real}
    dim = size(H0)[1]
    para_num = length(∂H_∂x)
    H = Htot(H0, control_Hamiltonian, control_coefficients)
    ρₜ = [Vector{ComplexF64}(undef, dim^2)  for i in 1:length(times)]
    ∂ₓρₜ = [[Vector{ComplexF64}(undef, dim^2) for i in 1:length(times)] for para in 1:para_num]
    Δt = times[2] - times[1]
    ρₜ[1] = ρ_initial |> vec
    for para in  1:para_num
        ∂ₓρₜ[para][1] = ρₜ[1] |> zero
    end
    for t in 2:length(times)
        expL = evolute(H[t-1], Liouville_operator, γ, Δt, t)
        ρₜ[t] =  expL * ρₜ[t-1]
        for para in para_num
            ∂ₓρₜ[para][t] = -im * Δt * liouville_commu(∂H_∂x[para]) * ρₜ[t] + expL * ∂ₓρₜ[para][t - 1]
        end
    end
    ρₜ .|> vec2mat, ∂ₓρₜ .|> vec2mat
end

function propagate(ρₜ::Matrix{T}, ∂ₓρₜ::Vector{Matrix{T}}, H0::Matrix{T}, ∂H_∂x::Vector{Matrix{T}},  Liouville_operator::Vector{Matrix{T}},
                   γ, control_Hamiltonian::Vector{Matrix{T}}, control_coefficients::Vector{R}, Δt::Real, t::Int=0, ctrl_interval::Int=1) where {T <: Complex,R <: Real}
    para_num = length(∂H_∂x)
    # ctrl_num = length(control_Hamiltonian)
    # control_coefficients = [transpose(repeat(control_coefficients[i], 1, ctrl_interval))[:] for i in 1:ctrl_num]
    H = Htot(H0, control_Hamiltonian, control_coefficients)
    # expL = (x->evolute(H, Liouville_operator, γ, Δt, x)).([t:t+ctrl_interval]...)
    expL = evolute(H, Liouville_operator, γ, Δt, t)
    ρₜ_next =expL * (ρₜ |> vec)
    ∂ₓρₜ_next = (∂ₓρₜ.|>vec) |> similar
    for para in para_num
        ∂ₓρₜ_next[para] = -im * Δt * liouville_commu(∂H_∂x[para]) * ρₜ_next + expL * (∂ₓρₜ[para]|>vec)
    end
    for i in 2:ctrl_interval
        ρₜ_next =expL * ρₜ_next 
        for para in para_num
            ∂ₓρₜ_next[para] = -im * Δt * liouville_commu(∂H_∂x[para])ρₜ_next + expL * ∂ₓρₜ_next[para]
        end
    end
    ρₜ_next|> vec2mat, ∂ₓρₜ_next|> vec2mat
end

function propagate(ρₜ, ∂ₓρₜ, system, ctrl, t=1)
    Δt = system.times[2] - system.times[1]
    propagate(ρₜ, ∂ₓρₜ, system.freeHamiltonian, system.Hamiltonian_derivative, system.Liouville_operator, system.γ, system.control_Hamiltonian, ctrl, Δt, t, system.ctrl_interval)
end

function propagate!(system)
    system.ρ, system.∂ρ_∂x = propagate(system.freeHamiltonian, system.Hamiltonian_derivative, system.ρ_initial,
                                       system.Liouville_operator, system.γ, system.control_Hamiltonian, 
                                       system.control_coefficients, system.times )
end

# function expm(H::Vector{Matrix{T}}, ∂H_∂x::Vector{Vector{T}},  ρ_in::Matrix{T}, Liouville_operator::Vector{Matrix{T}}, γ,  times) where {T <: Complex,R <: Real}
#     Δt = times[2] - times[1]
#     println(111)
#     para_num = length(∂H_∂x)
#     ρₜ = evolute(H[1], Liouville_operator, γ, Δt, 1) * (ρ_in |> vec)
#     ∂ₓρₜ = [-im * Δt * ∂H_∂x[i] * ρₜ for i in 1:para_num]
#     println(ρₜ)
#     println(∂ₓρₜ)
#     for t in 2:length(times)
#         expL = evolute(H[t], Liouville_operator, γ, Δt, t)
#         ρₜ = expL * ρₜ
#         ∂ₓρₜ = [-im * Δt * ∂H_∂x[i] * ρₜ for i in 1:para_num] + [expL] .* ∂ₓρₜ
#     end
#     ρₜ, ∂ₓρₜ
# end

# function evolute_ODE!(grape::Gradient)
#     H(p) = Htot(grape.freeHamiltonian, grape.control_Hamiltonian, p)
#     dt = grape.times[2] - grape.times[1]    
#     tspan = (grape.times[1], grape.times[end])
#     u0 = grape.ρ_initial
#     Γ = grape.Liouville_operator
#     f(u, p, t) = -im * (H(p)[t2Num(tspan[1], dt, t)] * u + u * H(p)[t2Num(tspan[1], dt, t)]) + 
#                  ([grape.γ[i] * (Γ[i] * u * Γ[i]' - (Γ[i]' * Γ[i] * u + u * Γ[i]' * Γ[i] )) for i in 1:length(Γ)] |> sum)
#     prob = ODEProblem(f, u0, tspan, grape.control_coefficients, saveat=dt)
#     sol = solve(prob)
#     sol.u
# end

# function propagate_ODEAD!(grape::Gradient)
#     H(p) = Htot(grape.freeHamiltonian, grape.control_Hamiltonian, p)
#     dt = grape.times[2] - grape.times[1]    
#     tspan = (grape.times[1], grape.times[end])
#     u0 = grape.ρ_initial
#     Γ = grape.Liouville_operator
#     f(u, p, t) = -im * (H(p)[t2Num(tspan[1], dt, t)] * u + u * H(p)[t2Num(tspan[1], dt, t)]) + 
#                  ([grape.γ[i] * (Γ[i] * u * Γ[i]' - (Γ[i]' * Γ[i] * u + u * Γ[i]' * Γ[i] )) for i in 1:length(Γ)] |> sum)
#     p = grape.control_coefficients
#     prob = ODEProblem(f, u0, tspan, p, saveat=dt)
#     u = solve(prob).u
#     du = Zygote.jacobian(solve(remake(prob, u0=u, p), sensealg=QuadratureAdjoint()))
#     u, du
# end

# function propagate_L_ODE!(grape::Gradient)
#     H = Htot(grape.freeHamiltonian, grape.control_Hamiltonian, grape.control_coefficients)
#     Δt = grape.times[2] - grape.times[1]    
#     tspan = (grape.times[1], grape.times[end])
#     u0 = grape.ρ_initial |> vec
#     evo(p, t) = evolute(p[t2Num(tspan[1], Δt,  t)], grape.Liouville_operator, grape.γ, grape.times, t2Num(tspan[1], Δt, t)) 
#     f(u, p, t) = evo(p, t) * u
#     prob = DiscreteProblem(f, u0, tspan, H,dt=Δt)
#     ρₜ = solve(prob).u 
#     ∂ₓρₜ = Vector{Vector{Vector{eltype(u0)}}}(undef, 1)
#     for para in 1:length(grape.Hamiltonian_derivative)
#         devo(p, t) = -1.0im * Δt * liouville_commu(grape.Hamiltonian_derivative[para]) * evo(p, t) 
#         du0 = devo(H, tspan[1]) * u0
#         g(du, p, t) = evo(p, t) * du + devo(p, t) * ρₜ[t2Num(tspan[1], Δt,  t)] 
#         dprob = DiscreteProblem(g, du0, tspan, H,dt=Δt) 
#         ∂ₓρₜ[para] = solve(dprob).u
#     end

#     grape.ρ, grape.∂ρ_∂x = ρₜ |> vec2mat, ∂ₓρₜ |> vec2mat
# end