-- Transition

--[[
The Transitions class contains static methods that define easing 
functions. Those functions will be used by the Tween class to 
execute animations. 
    
You can define your own transitions through the "registerTransition" 
function. A transition function must have the following signature, 
where "ratio" is in the range [0..1]:

function myTransition(ratio)

For all easing functions:
t = time == current tweening time
b = begin == starting property value
c = change == ending - beginning
d = duration == total time duration of the tween

r = ratio = t/d

v = f(r)*c + b

----

easing functions thankfully taken from 

http://dojotoolkit.org,
http://www.robertpenner.com/easing,
https://github.com/EmmanuelOga/easing

--]]

--default transition supported by tween class
Transition = {

    LINEAR= "linear",
    
    IN_QUAD = "inQuad",
    OUT_QUAD = "outQuad",
    IN_OUT_QUAD = "inOutQuad",
    OUT_IN_QUAD = "outInQuad",
    
    IN_CUBIC = "inCubic",
    OUT_CUBIC = "outCubic",
    IN_OUT_CUBIC = "inOutCubic",
    OUT_IN_CUBIC = "outInCubic",
    
    IN_QUART = "inQuart",
    OUT_QUART = "outQuart",
    IN_OUT_QUART = "inOutQuart",
    OUT_IN_QUART = "outInQuart",
    
    IN_QUINT = "inQuint",
    OUT_QUINT = "outQuint",
    IN_OUT_QUINT = "inOutQuint",
    OUT_IN_QUINT = "outInQuint",
    
    IN_BACK = "inBack",
    OUT_BACK = "outBack",
    IN_OUT_BACK = "inOutBack",
    OUT_IN_BACK = "outInBack",
    
    IN_ELASTIC = "inElastic",
    OUT_ELASTIC = "outElastic",
    IN_OUT_ELASTIC = "inOutElastic",
    OUT_IN_ELASTIC = "outInElastic",
    
    IN_BOUNCE = "inBounce",
    OUT_BOUNCE = "outBounce",
    IN_OUT_BOUNCE = "inOutBounce",
    OUT_IN_BOUNCE = "outInBounce",
    
    IN_SINE = "inSine",
    OUT_SINE = "outSine",
    IN_OUT_SINE = "inOutSine",
    OUT_IN_SINE = "outInSine",
    
    IN_EXPO = "inExpo",
    OUT_EXPO = "outExpo",
    IN_OUT_EXPO = "inOutExpo",
    OUT_IN_EXPO = "outInExpo",
    
    IN_CIRC = "inCirc",
    OUT_CIRC = "outCirc",
    IN_OUT_CIRC = "inOutCirc",
    OUT_IN_CIRC = "outInCirc"
}

local pow, sin, cos, pi, sqrt, abs, asin = math.pow, math.sin, math.cos, math.pi, math.sqrt, math.abs, math.asin

-- used to combine in & out ease functions
local function easeCombined(startFunc, endFunc, ratio)
    if (ratio < 0.5) then
        return 0.5 * startFunc(ratio * 2)
    else             
        return 0.5 * endFunc((ratio - 0.5) * 2) + 0.5
    end
end

-- work as local namespace for defaul ease functions
local ease = {}

-- linear
function ease.linear(ratio)
    return ratio
end
        
-- quad
function ease.inQuad(ratio) 
    return pow(ratio, 2) 
end

function ease.outQuad(ratio)
    return -ratio * (ratio - 2)
end

function ease.inOutQuad(ratio)
    return easeCombined(ease.inQuad,ease.outQuad,ratio)
end

function ease.outInQuad(ratio)
    return easeCombined(ease.outQuad,ease.inQuad,ratio)
end

-- cubic
function ease.inCubic(ratio) 
    return pow(ratio, 3)
end

function ease.outCubic(ratio) 
    return pow(ratio - 1, 3) + 1 
end

function ease.inOutCubic(ratio)
    return easeCombined(ease.inCubic,ease.outCubic,ratio)
end

function ease.outInCubic(ratio)
    return easeCombined(ease.outCubic,ease.inCubic,ratio)
end

-- quart
function ease.inQuart(ratio) 
    return pow(ratio, 4) 
end

function ease.outQuart(ratio) 
    return -(pow(ratio - 1, 4) - 1) 
end

function ease.inOutQuart(ratio)
    return easeCombined(ease.inQuart,ease.outQuart,ratio)
end

function ease.outInQuart(ratio)
    return easeCombined(ease.outQuart,ease.inQuart,ratio)
end

-- quint
function ease.inQuint(ratio) 
    return pow(ratio, 5) 
end

function ease.outQuint(ratio) 
    return pow(ratio - 1, 5) + 1
end

function ease.inOutQuint(ratio)
    return easeCombined(ease.inQuint,ease.outQuint,ratio)
end

function ease.outInQuint(ratio)
    return easeCombined(ease.outQuint,ease.inQuint,ratio)
end

-- back
function ease.inBack(ratio)
    local s = 1.70158
    return (ratio^2) * ((s + 1) * ratio - s)
end
        
function ease.outBack(ratio)
    local invRatio = ratio - 1
    local s = 1.70158
    return (invRatio^2) * ((s + 1) * invRatio + s) + 1
end
        
function ease.inOutBack(ratio)
    return easeCombined(ease.inBack, ease.outBack, ratio)
end
        
function ease.outInBack(ratio)
    return easeCombined(ease.outBack, ease.inBack, ratio)
end
        
-- elastic
function ease.inElastic(ratio)
    if (ratio == 0 or ratio == 1) then
        return ratio
    else
        local p = 0.3
        local s = p/4
        local invRatio = ratio - 1
        return -1 * 2^(10*invRatio) * math.sin((invRatio-s) *
            (2 * math.pi)/p)
    end
end
        
function ease.outElastic(ratio)
    if (ratio == 0 or ratio == 1) then
        return ratio
    else
        local p = 0.3
        local s = p/4
        return 2^ (-10 * ratio) * math.sin((ratio-s)*(2*math.pi)/p) + 1
    end
end
        
function ease.inOutElastic(ratio)
    return easeCombined(ease.inElastic, ease.outElastic, ratio)
end
        
function ease.outInElastic(ratio)
    return easeCombined(ease.outElastic, ease.inElastic, ratio)
end
        
-- bounce
function ease.outBounce(ratio)
    local s = 7.5625
    local p = 2.75
    local l = 0
    if (ratio < (1/p)) then
        l = s * ratio^2
    elseif (ratio < (2/p)) then
        ratio = ratio - 1.5/p
        l = s * ratio^2 + 0.75
    elseif (ratio < 2.5/p) then 
        ratio = ratio - 2.25/p
        l = s * ratio^2 + 0.9375
    else
        ratio = ratio - 2.625/p
        l =  s * ratio^2 + 0.984375
    end
    return l
end
        
function ease.inBounce(ratio)
    return 1.0 - easeOutBounce(1.0 - ratio)
end

function ease.inOutBounce(ratio)
    return easeCombined(ease.inBounce, ease.outBounce, ratio)
end
        
function ease.outInBounce(ratio)
    return easeCombined(ease.outBounce, ease.inBounce, ratio)
end

-- sine
function ease.inSine(ratio) 
    return -cos(ratio * (pi / 2)) + 1 
end

function ease.outSine(ratio) 
    return sin(ratio * (pi / 2))
end

function ease.inOutSine(ratio) 
    --return -(cos(pi * ratio) - 1)/2
    return easeCombined(ease.inSine,ease.outSine,ratio)
end

function ease.outInSine(ratio)
    return easeCombined(ease.outSine,ease.inSine,ratio)
end

-- expo
function ease.inExpo(ratio)
    if ratio == 0 then 
        return 0 
    end
    return pow(2, 10 * (ratio - 1)) - 0.001
end
function ease.outExpo(ratio)
    if ratio == 1 then 
        return 1 
    end
    return 1.001 * (-pow(2, -10 * ratio) + 1)
end

function ease.inOutExpo(ratio)
    return easeCombined(ease.inExpo,ease.outExpo,ratio)
end

function ease.outInExpo(ratio)
    return easeCombined(ease.outExpo,ease.inExpo,ratio)
end

-- circ
function ease.inCirc(ratio) 
    return -(sqrt(1 - pow(ratio, 2)) - 1) 
end

function ease.outCirc(ratio)  
    return sqrt(1 - pow(ratio - 1, 2))
end

function ease.inOutCirc(ratio)
    return easeCombined(ease.inCirc,ease.outCirc,ratio)
end

function ease.outInCirc(ratio)
    return easeCombined(ease.outCirc,ease.inCirc,ratio)
end

-- Transition registration
local _transitions = nil

local function registerDefaultTransitions()
    _transitions = {}
    
    for i,v in pairs(Transition) do
        if type(v) == "string" then
            _transitions[v] = ease[v]
            --print(v,ease[v])
        end
    end
end

--get the transition function registered under a certain name.
function Transition.getTransition(transitionName)
    if not _transitions then
        registerDefaultTransitions()
    end
    return _transitions[transitionName]
end

--Registers a new transition function under a certain name.
function Transition.registerTransition(transitionName,transitionFunc)
    if not _transitions then
        registerDefaultTransitions()
    end
    assert(not _transitions[transitionName], 
        transitionName.." already registered")
    _transitions[transitionName] = transitionFunc
end