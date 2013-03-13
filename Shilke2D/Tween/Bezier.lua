-- Bezier

--[[
source ported from http://paulbourke.net/geometry/bezier/index2.html  
--]]

--Three control point Bezier interpolation
--mu ranges from 0 to 1, start to end of the curve
function bezier3(mu,p)
    
    local mu2 = mu * mu
    local mum1 = 1 - mu
    local mum12 = mum1 * mum1
    
    local p = p[1] * mum12 + 2 * p[2] * mum1 * mu + p[3] * mu2
    return p
end

--Four control point Bezier interpolation
--mu ranges from 0 to 1, start to end of curve
function bezier4(mu,p)

    local mu3 = mu * mu * mu
    local mum1 = 1 - mu
    local mum13 = mum1 * mum1 * mum1
   
    local p = mum13 * p[1] + 3 * mu * mum1 * mum1 * p[2] + 
        3 * mu * mu * mum1 * p[3] + mu3 * p[4]
    return p    
end

function bezier(mu,p)
    local n = #p

    local k,kn,nn,nkn
    local blend,muk,munk
    --this set b to 0, where 0 can be scalar or vec2 ecc.
    local b = p[1] - p[1]

    local muk = 1
    local munk = math.pow(1-mu,n)

    for k=0,n-1,1 do
        nn = n
        kn = k
        nkn = n - k
        blend = muk * munk
        muk = muk * mu
        munk = munk / (1-mu)
        while nn >= 1 do
            blend = blend * nn
            nn = nn - 1
            if kn > 1 then
                blend = blend / kn
                kn = kn -1
             end
             if nkn > 1 then
                 blend = blend / nkn
                nkn = nkn - 1
             end
        end
        b = b + p[k+1] * blend
    end

    return b    
end
