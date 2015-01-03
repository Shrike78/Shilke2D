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
	self.tweenInfos = {}
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
	table.insert(self.tweenInfos, 
		{
			property = property,
			endValue = endValue,
			roundToInt = roundToInt or false
		}
	)
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
	table.insert(self.tweenInfos,
		{
			setter = setter,
			getter = getter,
			endValue = endValue,
			roundToInt = roundToInt or false
		}
	)
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
	table.insert(self.tweenInfos,
		{
			property = property,
			deltaValue = deltaValue,
			roundToInt = roundToInt or false
		}
	)
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
	table.insert(self.tweenInfos,
		{
			setter = setter,
			getter = getter,
			deltaValue = deltaValue,
			roundToInt = roundToInt or false
		}
	)
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
	local info = {
			property = property,
			target = target,
			roundToInt = roundToInt or false
		}
	--check type of provided targetProp (property or method)
	if type(targetProp) == 'function' then
		info.targetGetter = targetProp
	else
		info.targetProperty = targetProp
	end
	table.insert(self.tweenInfos,info)
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
	local info = {
			setter = setter,
			getter = getter,
			target = target,
			roundToInt = roundToInt or false
		}
	--check type of provided targetProp (property or method)
	if type(targetProp) == 'function' then
		info.targetGetter = targetProp
	else
		info.targetProperty = targetProp
	end
	table.insert(self.tweenInfos,info)
	return self
end

--onStart initialize start values of each tweened property
function TweenEase:_start()
	for _,info in ipairs(self.tweenInfos) do
		--initialize start value with current property/getter value
		if info.getter then
			info.startValue = info.getter(self.target)
		else
			info.startValue = self.target[info.property]
		end		
		--if possible initialize once per session the delta value (not possible if a 
		--follow ease is in action, because target changes each frame)
		if info.deltaValue then
			info._delta = info.deltaValue
		elseif info.endValue then
			info._delta = info.endValue - info.startValue
		end
		--reset the cached "lastValue" for each tweeninfo
		info.lastValue = nil
	end
end

function TweenEase:_getValue(info, mul)
	local startValue = info.startValue
	local deltaValue = info._delta
	--if a follow ease is in action check the target property/getter value and use
	--it to define current delta value
	if not deltaValue then
		if info.targetGetter then
			deltaValue = info.targetGetter(info.target) - startValue
		else
			deltaValue = info.target[info.targetProperty] - startValue
		end
	end
	if deltaValue == 0 then
		return startValue
	end
	local currentValue = startValue + mul * deltaValue
	if (info.roundToInt) then
		currentValue = round(currentValue)
	end
	return currentValue
end
	
	
function TweenEase:_update(deltaTime) 
	local ratio = min(self.totalTime, self.currentTime) / self.totalTime
	local mul = self.transition(ratio)
	local val
	for _,info in ipairs(self.tweenInfos) do
		val = self:_getValue(info, mul)
		--avoid continuous set of same value caching last value for each tween info
		if val ~= info.lastValue then
			if info.getter then
				info.setter(self.target, val)
			else
				self.target[info.property] = val
			end
			info.lastValue = val
		end
	end
end

function TweenEase:_isCompleted()
	return (self.currentTime >= self.totalTime)
end
