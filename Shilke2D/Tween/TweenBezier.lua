--[[---
A TweenBezier animates numeric properties of objects based on a bezier
curve defined by a set of control points

The primary use of this class is to do standard animations like 
movement, fading, rotation, etc. But there are no limits on what to 
animate; as long as the property you want to animate is numeric, the tween can handle it. 

The property can be directly a numeric key of a table/class, or a 
couple of setter and getter function/method of a table/class
    
@usage

b = tween.bezier(obj,tweenTime)

b:animate("x",x1,x2,x3)

b:animateEx(obj.setR,r1,r2,r3)

--]]

local TweenBezier = class(Tween)
Tween.bezier = TweenBezier

function TweenBezier:init(target,time)
    Tween.init(self)
    assert(time>0,"A tween must have a valid time")
    self.target = target
    self.totalTime = math.max(0.0001, time)
    self.properties = {}
    self.setters = {}
    self.tweenInfo = {}
end

function TweenBezier:_createTweenInfo(...)
    local controlPoints = {...}
    local bezierFunc = bezier
    if #controlPoints == 3 then 
        bezierFunc =  bezier3
    elseif #controlPoints == 4 then
        bezierFunc = bezier4
    end
    local tweenInfo = { 
        controlPoints = controlPoints,
        bezierFunc = bezierFunc
    }
    return tweenInfo
end

--[[---
Animates the property of an object following a bezier curve
defined by a list of control points

Is it possible to call this method multiple times on one tween, 
to animate different properties.

- each control point must be of the same type of property (scalar or
vector or any type that defines algebraic operations)
--]]
function TweenBezier:animate(property, ...)
    assert(self.target[property],property..
        " is not a property of the target of this tween")
    table.insert(self.properties,property)
    self.tweenInfo[property] = self:_createTweenInfo(...)
    return self
end

---Work as animate but instead of a property it uses a setter method
--@see TweenBezier:animate
function TweenBezier:animateEx(setter, ...)
    table.insert(self.setters,setter)
    self.tweenInfo[setter] = self:_createTweenInfo(...)
    return self
end

---Update method
function TweenBezier:_update()
    
    local ratio = math.min(self.totalTime, self.currentTime) / 
        self.totalTime
    
    function _getValue(hash,ratio)
        local info = self.tweenInfo[hash]
        local controlPoints = info.controlPoints
        local bezierFunc = info.bezierFunc
        local currentValue = bezierFunc(ratio,controlPoints)
        return currentValue
    end

    for _,property in pairs(self.properties) do
        self.target[property] = _getValue(property,ratio)
    end
    
    for _,setter in pairs(self.setters) do
        setter(self.target, _getValue(setter,ratio))
    end
end

function TweenBezier:_isCompleted()
    return (self.currentTime >= self.totalTime)
end
