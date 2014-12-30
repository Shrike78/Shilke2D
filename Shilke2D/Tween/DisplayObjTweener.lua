 --[[---
DisplayObjTweener is a tween helper to animate displayObjs. 
It's a set of wrapper function over Tween.ease() that allows to easily
animate displayObjs properties (position, scale, rotation, color, alpha).

Default transition for each transiformation is Transition.LINEAR
--]]

DisplayObjTweener = {}

--[[---
used to seek a property to a specific value
@param obj the displayObj to animate
@param setter the setter method to handle
@param getter the getter method to handle
@param endValue endValue of the animation
@param time duration of the animation
@param transition type of transition to apply. Default is LINEAR
@treturn Tween
--]]
function DisplayObjTweener.seekProp(obj,setter,getter,endValue,time,transition)
	local transition = transition or Transition.LINEAR
	local tween = Tween.ease(obj,time,transition)
	tween:seekEx(setter,getter,endValue)
	return tween
end

--[[---
used to move a property of a specific delta value
@param obj the displayObj to animate
@param setter the setter method to handle
@param getter the getter method to handle
@param deltaValue offset of the animation
@param time duration of the animation
@param transition type of transition to apply. Default is LINEAR
@treturn Tween
--]]
function DisplayObjTweener.moveProp(obj,setter,getter,deltaValue,time,transition)	
	local transition = transition or Transition.LINEAR
	local tween = Tween.ease(obj,time,transition)
	tween:moveEx(setter,getter,deltaValue)
	return tween
end

--[[---
seek alpha to a given value
@tparam DisplayObj obj the displayObj to animate
@tparam int a [0,255] end value of the animation
@tparam number time duration of the animation
@tparam[opt=Transition.LINEAR] Transition transition the transform transition to apply
@treturn Tween
--]]
function DisplayObjTweener.seekAlpha(obj,a,time,transition)
	return DisplayObjTweener.seekProp(obj,obj.setAlpha,obj.getAlpha,a,time,transition)
end

--[[---
move alpha of a given delta value
@tparam DisplayObj obj the displayObj to animate
@tparam int a [0,255] offset value of the animation
@tparam number time duration of the animation
@tparam[opt=Transition.LINEAR] Transition transition the transform transition to apply
@treturn Tween
--]]
function DisplayObjTweener.moveAlpha(obj,a,time,transition)
	return DisplayObjTweener.moveProp(obj,obj.setAlpha,obj.getAlpha,a,time,transition)
end

--[[---
seek color to a given value. it accepts only Colors or int32 values, not rgb
@tparam DisplayObj obj the displayObj to animate
@tparam Color c end value of the animation
@tparam number time duration of the animation
@tparam[opt=Transition.LINEAR] Transition transition the transform transition to apply
@treturn Tween
--]]
function DisplayObjTweener.seekColor(obj,c,time,transition)
	return DisplayObjTweener.seekProp(obj,obj.setColor,obj.getColor,Color(c),time,transition)
end

--[[---
move color of a given delta value. it accepts only Color or int32 values, not rgb
@tparam DisplayObj obj the displayObj to animate
@tparam Color c offset value of the animation
@tparam number time duration of the animation
@tparam[opt=Transition.LINEAR] Transition transition the transform transition to apply
@treturn Tween
--]]
function DisplayObjTweener.moveColor(obj,c,time,transition)
	return DisplayObjTweener.moveProp(obj,obj.setColor,obj.getColor,Color(c),time,transition)
end


--[[---
seek position, rotation and scale to given values
@tparam DisplayObj obj the displayObj to animate
@tparam number x end x position value
@tparam number y end y position value
@tparam number r end rotation value
@tparam number sx end x scale value
@tparam number sy end y scale value
@tparam number time duration of the animation
@tparam[opt=Transition.LINEAR] Transition transition the transform transition to apply
@treturn Tween
--]]
function DisplayObjTweener.seek(obj,x,y,r,sx,sy,time,transition)
	local transition = transition or Transition.LINEAR
	local tween = Tween.ease(obj,time,transition)
	tween:seekEx(obj.setPositionX,	obj.getPositionX,	x)
	tween:seekEx(obj.setPositionY,	obj.getPositionY,	y)
	tween:seekEx(obj.setRotation,	obj.getRotation,	r)
	tween:seekEx(obj.setScaleX,	obj.getScaleX,		sx)
	tween:seekEx(obj.setScaleY,	obj.getScaleY,		sy)
	return tween
end

--[[---
move position, rotation and scale of given delta values
@tparam DisplayObj obj the displayObj to animate
@tparam number x delta x position value
@tparam number y delta y position value
@tparam number r delta rotation value
@tparam number sx delta x scale value
@tparam number sy delta y scale value
@tparam number time duration of the animation
@tparam[opt=Transition.LINEAR] Transition transition the transform transition to apply
@treturn Tween
--]]
function DisplayObjTweener.move(obj,x,y,r,sx,sy,time,transition)
	local transition = transition or Transition.LINEAR
	local tween = Tween.ease(obj,time,transition)
	tween:moveEx(obj.setPositionX,	obj.getPositionX,	x)
	tween:moveEx(obj.setPositionY,	obj.getPositionY,	y)
	tween:moveEx(obj.setRotation,	obj.getRotation,	r)
	tween:moveEx(obj.setScaleX,	obj.getScaleX,		sx)
	tween:moveEx(obj.setScaleY,	obj.getScaleY,		sy)
	return tween
end


--[[---
seek position to given value
@tparam DisplayObj obj the displayObj to animate
@tparam number x end x position value
@tparam number y end y position value
@tparam number time duration of the animation
@tparam[opt=Transition.LINEAR] Transition transition the transform transition to apply
@treturn Tween
--]]
function DisplayObjTweener.seekPosition(obj,x,y,time,transition)
	local transition = transition or Transition.LINEAR
	local tween = Tween.ease(obj,time,transition)
	tween:seekEx(obj.setPositionX,obj.getPositionX,x)
	tween:seekEx(obj.setPositionY,obj.getPositionY,y)
	return tween
end


--[[---
move position of given delta value
@tparam DisplayObj obj the displayObj to animate
@tparam number x delta x position value
@tparam number y delta y position value
@tparam number time duration of the animation
@tparam[opt=Transition.LINEAR] Transition transition the transform transition to apply
@treturn Tween
--]]
function DisplayObjTweener.movePosition(obj,x,y,time,transition)
	local transition = transition or Transition.LINEAR
	local tween = Tween.ease(obj,time,transition)
	tween:moveEx(obj.setPositionX,obj.getPositionX,x)
	tween:moveEx(obj.setPositionY,obj.getPositionY,y)
	return tween
end


--[[---
seek rotation to given value
@tparam DisplayObj obj the displayObj to animate
@tparam number r end rotation value
@tparam number time duration of the animation
@tparam[opt=Transition.LINEAR] Transition transition the transform transition to apply
@treturn Tween
--]]
function DisplayObjTweener.seekRotation(obj,r,time,transition)
	return DisplayObjTweener.seekProp(obj,obj.setRotation,obj.getRotation,r,time,transition)
end


--[[---
move rotation of given delta values
@tparam DisplayObj obj the displayObj to animate
@tparam number r delta rotation value
@tparam number time duration of the animation
@tparam[opt=Transition.LINEAR] Transition transition the transform transition to apply
@treturn Tween
--]]
function DisplayObjTweener.moveRotation(obj,r,time,transition)
	return DisplayObjTweener.moveProp(obj,obj.setRotation,obj.getRotation,r,time,transition)
end


--[[---
seek scale to given value
@tparam DisplayObj obj the displayObj to animate
@tparam number sx end x scale value
@tparam number sy end y scale value
@tparam number time duration of the animation
@tparam[opt=Transition.LINEAR] Transition transition the transform transition to apply
@treturn Tween
--]]
function DisplayObjTweener.seekScale(obj,sx,sy,time,transition)
	local transition = transition or Transition.LINEAR
	local tween = Tween.ease(obj,time,transition)
	tween:seekEx(obj.setScaleX,obj.getScaleX,sx)
	tween:seekEx(obj.setScaleY,obj.getScaleY,sy)
	return tween
end


--[[---
move scale of given delta value
@tparam DisplayObj obj the displayObj to animate
@tparam number sx delta x scale value
@tparam number sy delta y scale value
@tparam number time duration of the animation
@tparam[opt=Transition.LINEAR] Transition transition the transform transition to apply
@treturn Tween
--]]
function DisplayObjTweener.moveScale(obj,sx,sy,time,transition)
	local transition = transition or Transition.LINEAR
	local tween = Tween.ease(obj,time,transition)
	tween:moveEx(obj.setScaleX,obj.getScaleX,sx)
	tween:moveEx(obj.setScaleY,obj.getScaleY,sy)
	return tween
end

--[[---
used to follow another displayobj position
@tparam DisplayObj obj the displayObj to animate
@tparam DisplayObj target the displayObj to follow
@tparam number time time into which reach the target
@tparam[opt=Transition.LINEAR] Transition transition the transform transition to apply
@treturn Tween
--]]
function DisplayObjTweener.seekTargetPosition(obj,target,time,transition)
	local transition = transition or Transition.LINEAR
	local tween = Tween.ease(obj,time,transition)
	tween:followEx(obj.setPositionX,obj.getPositionX,target,target.getPositionX)
	tween:followEx(obj.setPositionY,obj.getPositionY,target,target.getPositionY)
	return tween
end
