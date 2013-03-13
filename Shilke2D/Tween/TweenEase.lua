-- TweenEase

--[[
A TweenEase animates numeric properties of objects. It uses different
transition functions to give the animations various styles.

The primary use of this class is to do standard animations like 
movement, fading, rotation, etc. But there are no limits on what to 
animate; as long as the property you want to animate is numeric, the tween can handle it. For a list of available Transition types, look 
at the "Transitions" class.

The property can be directly a numeric key of a table/class, or a 
couple of setter and getter function/method of a table/class
    
usage:

e = Tween.ease(obj,tweenTime,Transition.LINEAR)
e:seek("x",endValue)
e:seekEx(obj.setR,endValue)
--]]

local TweenEase = class(Tween)
Tween.ease = TweenEase

function TweenEase:init(target,time,transitionName)
    assert(transitionName,"a valid transition name must be provided")
    Tween.init(self)
    assert(time>0,"A tween must have a valid time")
    self.target = target
    self.totalTime = math.max(0.0001, time)
    self.transition = Transition.getTransition(transitionName)
    assert(self.transition,
        transitionName.." is not a registered transition")
             
    self.properties = {}
    self.setters = {}
    self.tweenInfo = {}
end


--[[
seek the property of an object to a target value. 
Is it possible to call this method multiple times on one tween, 
to animate different properties.

- endValue is the value to which property will tween with a curve and 
in a time configured when the tween was created.

- roundToInt is optional, and if true force updated propery values
to be rounded to int values
--]]
function TweenEase:seek(property, endValue, roundToInt)	
    table.insert(self.properties,property)
    self.tweenInfo[property] = {
            endValue = endValue,
            roundToInt = roundToInt or false
    }
    return self
end

--Work as seek but instead of a property it receives a pair of setter and getter methods. 
function TweenEase:seekEx(setter, getter, endValue, roundToInt)
    table.insert(self.setters,setter)
    self.tweenInfo[setter] = {
            getter = getter,
			endValue = endValue,
            roundToInt = roundToInt or false
    }
    return self
end

--similar to seek but it receives a delta value instead of a target value,
--and the 'delta' is estimated on tween start
function TweenEase:move(property, deltaValue, roundToInt)
    assert(self.target[property],property..
        " is not a property of the target of this tween")
    table.insert(self.properties,property)
    self.tweenInfo[property] = {
            deltaValue = deltaValue,
            roundToInt = roundToInt or false
    }
    return self
end

function TweenEase:moveEx(setter, getter, deltaValue, roundToInt)
    table.insert(self.setters,setter)
    self.tweenInfo[setter] = {
            getter = getter,
			deltaValue = deltaValue,
            roundToInt = roundToInt or false
    }
    return self
end


-- instead of receiving a target value it receive a target object with property, that is
-- a dynamic variable that could change during time
function TweenEase:follow(property, target, targetProp, roundToInt)
    table.insert(self.setters,setter)
    self.tweenInfo[setter] = {
            getter = getter,
			target = target,
			targetProp = targetProp,
            roundToInt = roundToInt or false
    }
    return self
end

function TweenEase:followEx(setter, getter, target, targetProp, roundToInt)
    table.insert(self.setters,setter)
    self.tweenInfo[setter] = {
            getter = getter,
			target = target,
			targetProp = targetProp,
            roundToInt = roundToInt or false
    }
    return self
end

--onStart initialize start values of each tweened property
function TweenEase:_start()
    for _,property in pairs(self.properties) do
        local info = self.tweenInfo[property]
		info.startValue = self.target[property]
		if info.deltaValue then
			info.endValue = info.startValue + info.deltaValue
		end
    end
    for _,setter in pairs(self.setters) do
        local info = self.tweenInfo[setter]
		info.startValue = info.getter(self.target)
		if info.deltaValue then
			info.endValue = info.startValue + info.deltaValue
		end
    end
end

function TweenEase:_getValue(hash,ratio)
        local info = self.tweenInfo[hash]
        local startValue = info.startValue
        local endValue
		if info.endValue then 
			endValue = info.endValue
		else
			if type(info.targetProp) == 'function' then
				endValue = info.targetProp(info.target)
			else
				endValue = info.target[info.targetProp]
			end
		end
        local delta = endValue - startValue
            
        local currentValue = startValue + self.transition(ratio) * delta
        if (info.roundToInt) then
            currentValue = math.round(currentValue)
        end
        return currentValue
    end
	
function TweenEase:_update(deltaTime)
    
    local ratio = math.min(self.totalTime, self.currentTime) / 
        self.totalTime

    for _,property in pairs(self.properties) do
        self.target[property] = self:_getValue(property,ratio)
    end
    
    for _,setter in pairs(self.setters) do
        setter(self.target, self:_getValue(setter,ratio))
    end
end

function TweenEase:_isCompleted()
    return (self.currentTime >= self.totalTime)
end
