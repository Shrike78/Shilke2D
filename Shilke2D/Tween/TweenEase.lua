--[[---
A TweenEase animates numeric properties of objects. It uses different
transition functions to give the animations various styles.

The primary use of this class is to do standard animations like 
movement, fading, rotation, etc. But there are no limits on what to 
animate. As long as the property you want to animate is numeric, the 
tween can handle it. For a list of available Transition types, look 
at the "Transitions" class.

The property can be directly a numeric key of a table/class, or a 
couple of setter and getter function/method of a table/class
    
@usage

e = Tween.ease(obj,tweenTime,Transition.LINEAR)
e:seek("x",endValue)
e:seekEx(obj.setter,obj.getter,endValue)
--]]

local TweenEase = class(Tween)
Tween.ease = TweenEase

local min, max, round = math.min, math.max, math.round

--[[---
Constructor.
@param target the object that will be animated
@param time duration of the animation
@param transitionName type of transition that will be applied
--]]
function TweenEase:init(target,time,transitionName)
	Tween.init(self)
	assert(time>0,"A tween must have a valid time")
	self.target = target
	self.totalTime = max(0.0001, time)
	local transitionName = transitionName or Transition.LINEAR
	self.transition = Transition.getTransition(transitionName)
	assert(self.transition, transitionName.." is not a registered transition")
			 
	self.properties = {}
	self.setters = {}
	self.tweenInfo = {}
end


--[[---
seeks the property of an object to a target value. 
Is it possible to call this method multiple times on one tween, 
to animate different properties.

@param property the property that will be animated
@param endValue the value to which the property will tweened with 
a curve and in a time configured when the tween was created.
@param roundToInt if true force updated propery values
to be rounded to int values. default is false
@return self
--]]
function TweenEase:seek(property, endValue, roundToInt)	
	table.insert(self.properties,property)
	self.tweenInfo[property] = {
			endValue = endValue,
			roundToInt = roundToInt or false
	}
	return self
end

--[[---
Similar to seek but instead of a property it receives a pair of setter and getter methods.

@param setter the setter of the property that will be animated
@param getter the getter of the the property that will be animated
@param endValue the value to which the property will tweened with 
a curve and in a time configured when the tween was created.
@param roundToInt if true force updated propery values
to be rounded to int values. default is false
@return self
--]]
function TweenEase:seekEx(setter, getter, endValue, roundToInt)
	table.insert(self.setters,setter)
	self.tweenInfo[setter] = {
			getter = getter,
			endValue = endValue,
			roundToInt = roundToInt or false
	}
	return self
end

--[[---
move the property of an object of a delta value. 
Is it possible to call this method multiple times on one tween, 
to animate different properties.

@param property the property that will be animated
@param deltaValue the value of which the property will tweened with 
a curve and in a time configured when the tween was created.
@param roundToInt if true force updated propery values
to be rounded to int values. default is false
@return self
--]]
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

--[[---
Similar to move but instead of a property it receives a pair of setter and getter methods.

@param setter the setter of the property that will be animated
@param getter the getter of the the property that will be animated
@param deltaValue the value of which the property will tweened with 
a curve and in a time configured when the tween was created.
@param roundToInt if true force updated propery values
to be rounded to int values. default is false
@return self
--]]
function TweenEase:moveEx(setter, getter, deltaValue, roundToInt)
	table.insert(self.setters,setter)
	self.tweenInfo[setter] = {
			getter = getter,
			deltaValue = deltaValue,
			roundToInt = roundToInt or false
	}
	return self
end


--[[---
Instead of receiving a target value it receive a target object with property, 
that is a dynamic variable that could change during time.

Is it possible to call this method multiple times on one tween, 
to animate different properties.

@param property the property that will be animated
@param target the object that has to be followed
@param targetProp the property of the target object that we want to reach. 
Can be also a getter method
@param roundToInt if true force updated propery values
to be rounded to int values. default is false
@return self
--]]
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

--[[---
Similar to follow but instead of a property it receives a pair of setter and getter methods.

@param setter the setter of the property that will be animated
@param getter the getter of the the property that will be animated
@param target the object that has to be followed
@param targetProp the property of the target object that we want to reach. 
Can be also a getter method
@param roundToInt if true force updated propery values
to be rounded to int values. default is false
@return self
--]]
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
	if delta == 0 then
		return startValue, false
	end
	local currentValue = startValue + self.transition(ratio) * delta
	if (info.roundToInt) then
		currentValue = round(currentValue)
	end
	local bNeedUpdate = info.lastValue ~= currentValue
	info.lastValue = currentValue
	return currentValue, bNeedUpdate
end
	
function TweenEase:_update(deltaTime) 
	local ratio = min(self.totalTime, self.currentTime) / self.totalTime
	local val, bNeedUpdate
	for _,property in pairs(self.properties) do
		val, bNeedUpdate = self:_getValue(property,ratio) 
		if bNeedUpdate then
			self.target[property] = val
		end
	end

	for _,setter in pairs(self.setters) do
		val, bNeedUpdate = self:_getValue(setter,ratio)
		if bNeedUpdate then
			setter(self.target, val)
		end
	end
end

function TweenEase:_isCompleted()
	return (self.currentTime >= self.totalTime)
end
