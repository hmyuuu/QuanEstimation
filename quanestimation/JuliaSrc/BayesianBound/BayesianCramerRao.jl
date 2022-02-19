
########## Bayesian quantum Cramer-Rao bound ##########
function BQCRB(x, p, rho, drho; b=[], db=[], btype=1, eps=1e-8)
        
    para_num = length(x)

    if b==[]
        b =  [zero(x) for x in x]
        db =  [zero(x) for x in x]
    end
    if b!=[] && db==[] 
        db = [zero(x) for x in x]
    end

    
    if para_num == 1    
        p_num = length(p)
        #### singleparameter senario ####
        if typeof(drho[1]) == Vector{Matrix{ComplexF64}}
            drho = [drho[i][1] for i in 1:p_num]
        end
        if typeof(b) == Vector{Float64} || typeof(b) == Vector{Int64}
            b = b[1]
        end
        if typeof(db) == Vector{Float64} || typeof(db) == Vector{Int64}
            db = db[1]
        end
        F_tp = zeros(p_num)
        for i in 1:p_num
            f = QFIM(rho[i], drho[i]; dtype=dtype, eps=eps)
            F_tp[i] = f
        end
        F = 0.0
        if btype == 1
            arr = [p[i]*((1+db)^2/F_tp[i]+b^2) for i in 1:p_num]
            F = trapz(x[1], arr)
        elseif btype == 2
            arr = [p[i]*F_tp[i] for i in 1:p_num]
            F1 = trapz(x[1], arr)
            F = (1+db)^2*(1.0/F1)+b^2
        end
        return F
    else
        #### multiparameter senario ####
        xnum = length(x)
        bs  =  Iterators.product(b...)
        dbs =  Iterators.product(db...)

        trapzm(x, integrands, slice_dim) =  [trapz(tuple(x...), I) for I in [reshape(hcat(integrands...)[i,:], length.(x)...) for i in 1:slice_dim]] 

        if btype == 1 
            integrand(p,rho,drho,b,db)=p*diagm(1 .+db)*pinv(QFIM(rho,drho,eps))*diagm(1 .+db)+b*b'

            integrands = [integrand(p,rho,drho,[b...],[db...])|>vec for (p,rho,drho,b,db) in zip(p,rho,drho,bs,dbs)]

            I = trapzm(x, integrands, xnum^2) |> I->reshape(I,xnum,xnum)

        elseif btype == 2
            Bs = [p*(1 .+[db...]) for (p,db) in zip(p,dbs)]
            B = trapzm(x, Bs, xnum)|> diagm

            Fs = [p*QFIM(rho,drho,eps)|>vec for (p,rho,drho) in zip(p,rho,drho)]
            F = trapzm(x, Fs, xnum^2) |> I->reshape(I,xnum,xnum)

            bbts = [p*[b...]*[b...]'|>vec for (p,b) in zip(p,bs)]
            I = B*pinv(F)*B + (trapzm(x, bbts, xnum^2) |> I->reshape(I,xnum,xnum))
        end
        return I
    end

end

function BCRB(x, p, rho, drho; M=[], b=[], db=[], btype=1, eps=1e-8)
    para_num = length(x)

    
    if b==[]
        b =  [zero(x) for x in x]
        db =  [zero(x) for x in x]
    end
    if b!=[] && db==[] 
        db = [zero(x) for x in x]
    end

    
    if para_num == 1
        p_num = length(p)
        #### singleparameter senario ####
        if typeof(drho[1]) == Vector{Matrix{ComplexF64}}
            drho = [drho[i][1] for i in 1:p_num]
        end
        if typeof(b) == Vector{Float64} || typeof(b) == Vector{Int64}
            b = b[1]
        end
        if typeof(db) == Vector{Float64} || typeof(db) == Vector{Int64}
            db = db[1]
        end
        F_tp = zeros(p_num)
        for i in 1:p_num
            f = QFIM(rho[i], drho[i]; dtype=dtype, eps=eps)
            F_tp[i] = f
        end
        F = 0.0
        if btype == 1
            arr = [p[i]*((1+db)^2/F_tp[i]+b^2) for i in 1:p_num]
            F = trapz(x[1], arr)
        elseif btype == 2
            arr = [p[i]*F_tp[i] for i in 1:p_num]
            F1 = trapz(x[1], arr)
            F = (1+db)^2*(1.0/F1)+b^2
        end
        return F
    else
        #### multiparameter senario #### # TODO: load_M for multi-
        xnum = length(x)
        bs  =  Iterators.product(b...)
        dbs =  Iterators.product(db...)

        trapzm(x, integrands, slice_dim) =  [trapz(tuple(x...), I) for I in [reshape(hcat(integrands...)[i,:], length.(x)...) for i in 1:slice_dim]] 

        if btype == 1 
            integrand(p,rho,drho,b,db)=p*diagm(1 .+db)*pinv(CFIM(rho,drho,M,eps))*diagm(1 .+db)+b*b'

            integrands = [integrand(p,rho,drho,[b...],[db...])|>vec for (p,rho,drho,b,db) in zip(p,rho,drho,bs,dbs)]

            I = trapzm(x, integrands, xnum^2) |> I->reshape(I,xnum,xnum)

        elseif btype == 2
            Bs = [p*(1 .+[db...]) for (p,db) in zip(p,dbs)]
            B = trapzm(x, Bs, xnum)|> diagm

            Fs = [p*CFIM(rho,drho,M,eps)|>vec for (p,rho,drho) in zip(p,rho,drho)]
            F = trapzm(x, Fs, xnum^2) |> I->reshape(I,xnum,xnum)

            bbts = [p*[b...]*[b...]'|>vec for (p,b) in zip(p,bs)]
            I = B*pinv(F)*B + (trapzm(x, bbts, xnum^2) |> I->reshape(I,xnum,xnum))
        end    
        return I
    end

end

function QVTB(x, p, dp, rho, drho; dtype="SLD", btype=1, eps=1e-8)
    para_num = length(x)
    if para_num == 1
        #### singleparameter senario ####
        p_num = length(p)
        if typeof(drho[1]) == Vector{Matrix{ComplexF64}}
            drho = [drho[i][1] for i in 1:p_num]
        end
        if typeof(dp[1]) == Vector{Float64}
            dp = [dp[i][1] for i in 1:p_num]
        end
        F_tp = zeros(p_num)
        for m in 1:p_num
            F_tp[m] = QFIM(rho[m], drho[m]; dtype=dtype, eps=eps)
        end
        res = 0.0
        if btype==1
            I_tp = [real(dp[i]*dp[i]/p[i]^2) for i in 1:p_num]
            arr = [p[j]/(I_tp[j]+F_tp[j]) for j in 1:p_num]
            I = trapz(x[1], arr)
        elseif btype==2
            I, F = 0.0, 0.0
            arr1 = [real(dp[i]*dp[i]/p[i]) for i in 1:p_num]  
            I = trapz(x[1], arr1)
            arr2 = [real(F_tp[j]*p[j]) for j in 1:p_num]
            F = trapz(x[1], arr2)
            I = 1.0/(I+F)
        end
        return res
    else
        #### multiparameter senario ####
        xnum = length(x)

        trapzm(x, integrands, slice_dim) =  [trapz(tuple(x...), I) for I in [reshape(hcat(integrands...)[i,:], length.(x)...) for i in 1:slice_dim]] 

        Ip(p,dp) = dp*dp'/p^2

        if btype == 1 
            integrand(p,dp,rho,drho)=p*pinv(Ip(p,dp)+QFIM(rho,drho,eps))
            integrands = [integrand(p,dp,rho,drho)|>vec for (p,dp,rho,drho) in zip(p,dp,rho,drho)]

            I = trapzm(x, integrands, xnum^2) |> I->reshape(I,xnum,xnum)

        elseif btype == 2
            Iprs = [Ip(p,dp)|>vec for (p,dp) in zip(p,dp)]
            Ipr = trapzm(x, Iprs, xnum^2)|> I->reshape(I,xnum,xnum)

            Fs = [p*QFIM(rho,drho,eps)|>vec for (p,rho,drho) in zip(p,rho,drho)]
            F = trapzm(x, Fs, xnum^2) |> I->reshape(I,xnum,xnum)

            I = pinv(Ipr+F)
        end
        return I
    end
end

function VTB(x, p, dp, rho, drho; M=[], btype=1, eps=1e-8)
    para_num = length(x)
    if para_num == 1
        #### singleparameter senario ####
        p_num = length(p)
        if M==[]
            M = load_M(size(rho[1])[1])
        end
        if typeof(drho[1]) == Vector{Matrix{ComplexF64}}
            drho = [drho[i][1] for i in 1:p_num]
        end
        if typeof(dp[1]) == Vector{Float64}
            dp = [dp[i][1] for i in 1:p_num]
        end
        F_tp = zeros(p_num)
        for m in 1:p_num
            F_tp[m] = CFI(rho[m], drho[m], M; eps=eps)
        end
        res = 0.0
        if btype==1
            I_tp = [real(dp[i]*dp[i]/p[i]^2) for i in 1:p_num]
            arr = [p[j]/(I_tp[j]+F_tp[j]) for j in 1:p_num]
            res = trapz(x[1], arr)
        elseif btype==2
            arr1 = [real(dp[i]*dp[i]/p[i]) for i in 1:p_num]  
            I = trapz(x[1], arr1)
            arr2 = [real(F_tp[j]*p[j]) for j in 1:p_num]
            F = trapz(x[1], arr2)
            res = 1.0/(I+F)
        end
        return res
    else
        #### multiparameter senario #### # TODO: load_M for multi-
        xnum = length(x)

        trapzm(x, integrands, slice_dim) =  [trapz(tuple(x...), I) for I in [reshape(hcat(integrands...)[i,:], length.(x)...) for i in 1:slice_dim]] 

        Ip(p,dp) = dp*dp'/p^2

        if btype == 1 
            integrand(p,dp,rho,drho)=p*pinv(Ip(p,dp)+CFIM(rho,drho,M,eps))
            integrands = [integrand(p,dp,rho,drho)|>vec for (p,dp,rho,drho) in zip(p,dp,rho,drho)]

            I = trapzm(x, integrands, xnum^2) |> I->reshape(I,xnum,xnum)

        elseif btype == 2
            Iprs = [Ip(p,dp)|>vec for (p,dp) in zip(p,dp)]
            Ipr = trapzm(x, Iprs, xnum^2)|> I->reshape(I,xnum,xnum)

            Fs = [p*CFIM(rho,drho,M,eps)|>vec for (p,rho,drho) in zip(p,rho,drho)]
            F = trapzm(x, Fs, xnum^2) |> I->reshape(I,xnum,xnum)

            I = pinv(Ipr+F)
        end
        return I
    end
end

########## optimal biased bound ##########
function OBB_func(du, u, para, t)
    F, J, x = para
    J_tp = interp1(x, J, t)
    F_tp = interp1(x, F, t)
    bias = u[1]
    dbias = u[2]
    du[1] = dbias
    du[2] = -J_tp*dbias + F_tp*bias - J_tp
end

function boundary_condition(residual, u, p, t)
    residual[1] = u[1][2] + 1.0
    residual[2] = u[end][2] + 1.0
end

function interp1(xspan, yspan, x)
    idx = (x .>= xspan[1]) .& (x .<= xspan[end])
    intf = interpolate((xspan,), yspan, Gridded(Linear()))
    y = intf[x[idx]]
    return y
end

function OBB(x, p, dp, rho, drho, d2rho; dtype="SLD", eps=1e-8)
    p_num = length(p)
    
    if typeof(drho[1]) == Vector{Matrix{ComplexF64}}
        drho = [drho[i][1] for i in 1:p_num]
    end
    if typeof(d2rho[1]) == Vector{Matrix{ComplexF64}}
        d2rho = [d2rho[i][1] for i in 1:p_num]
    end
    if typeof(dp[1]) == Vector{Float64}
        dp = [dp[i][1] for i in 1:p_num]
    end
    if typeof(x[1]) != Float64 || typeof(x[1]) != Int64
        x = x[1]
    end

    delta = x[2] - x[1] 
    F, J = zeros(p_num), zeros(p_num)
    for m in 1:p_num
        f, LD = QFIM(rho[m], drho[m]; dtype=dtype, exportLD=true, eps=eps)
        dF = real(tr(2*d2rho[m]*d2rho[m]*LD - LD*LD*drho[m]))
        J[m] = dp[m]/p[m] - dF/f 
        F[m] = f
    end

    prob = BVProblem(OBB_func, boundary_condition, [0.0, 0.0], (x1, x2), (F, J, x))
    sol = solve(prob, GeneralMIRK4(), dt=delta)

    bias = [sol.u[i][1] for i in 1:p_num] 
    dbias = [sol.u[i][2] for i in 1:p_num]

    value = [p[i]*((1+dbias[i])^2/F[i] + bias[i]^2) for i in 1:p_num]
    return trapz(x, value)
end
