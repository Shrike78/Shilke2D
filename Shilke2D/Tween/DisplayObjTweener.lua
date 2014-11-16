 --[[---
DisplayObjTweener is a tween helper to animate displayObjs. 
It's a set of wrapper function over Tween.ease() that allows to easily
animate displayObjs properties (position, scale, rotation, color, alpha).

Default transition for each transiformation is Transition.LINEAR
--]]

DisplayObjTweener = {}

--[[---
used to seek a properties to a specific value
@param obj the displayObj to animate
@param setter the setter method to handle
@param getter the getter method to handle
@param endValue endValue of the animation
@param time duration of the animation
@param transition type of transition to apply. Default is LINEAR
--]]
function DisplayObjTweener.seekProp(obj,setter,getter,endValue,time,transition)
	local transition = transition or Transition.LINEAR
	local tween = Tween.ease(obj,time,transition)
	tween:seekEx(setter,getter,endValue)
	return tween
end

--[[---
used to move a properties of specific value
@param obj the displayObj to animate
@param setter the setter method to handle
@param getter the getter method to handle
@param deltaValue offset of the animation
@param time duration of the animation
@param transition type of transition to apply. Default is LINEAR
--]]
function DisplayObjTweener.moveProp(obj, setter,getter,deltaValue,time,transition)	
	local transition = transition or Transition.LINEAR
	local tween = Tween.ease(obj,time,transition)
	tween:moveEx(setter,getter,deltaValue)
	return tween
end

---seek animation of alpha value
function DisplayObjTweener.seekAlpha(obj,a,time,transition)
	return DisplayObjTweener.seekProp(obj,obj.setAlpha,obj.getAlpha,a,time,transition)
end

---move animation of alpha value
function DisplayObjTweener.moveAlpha(obj,a,time,transition)
	return DisplayObjTweener.moveProp(obj,obj.setAlpha,obj.getAlpha,a,time,transition)
end

---seek animation of color value. it accepts only Color, not rgb
function DisplayObjTweener.seekColor(obj,c,time,transition)
	return DisplayObjTweener.seekProp(obj,obj.setColor,obj.getColor,Color(c),time,transition)
end

---move animation of color value. it accepts only Color, not rgb
--@param obj the displayObj to animate
--@param c can be composed also by negative values but the end animation color must be a valid Color
--@param time duration of the animation
--@param transition type of transition. default is LINEAR
function DisplayObjTweener.moveColor(obj,c,time,transition)
	return DisplayObjTweener.moveProp(obj,obj.setColor,obj.getColor,Color(c),time,transition)
end


---seek animation of position
function DisplayObjTweener.seekPosition(obj,x,y,time,transition)
	return DisplayObjTweener.seekProp(obj,obj.setPosition_v2,obj.getPosition_v2,vec2(x,y),time,transition)
end

---move animation of position
function DisplayObjTweener.movePosition(obj,x,y,time,transition)
	return DisplayObjTweener.moveProp(obj,obj.setPosition_v2,obj.getPosition_v2,vec2(x,y),time,transition)
end

---seek animation of rotation
function DisplayObjTweener.seekRotation(obj,r,time,transition)
	return DisplayObjTweener.seekProp(obj,obj.setRotation,obj.getRotation,r,time,transition)
end

---move animation of rotation
function DisplayObjTweener.moveRotation(obj,r,time,transition)
	return DisplayObjTweener.moveProp(obj,obj.setRotation,obj.getRotation,r,time,transition)
end

---seek animation of scale values
function DisplayObjTweener.seekScale(obj,sx,sy,time,transition)
	return DisplayObjTweener.seekProp(obj,obj.setScale_v2,obj.getScale_v2,vec2(sx,sy),time,transition)
end

---move animation of scale values
function DisplayObjTweener.moveScale(obj,sx,sy,time,transition)
	return DisplayObjTweener.moveProp(obj,obj.setScale_v2,obj.getScale_v2,vec2(sx,sy),time,transition)
end

---used to follow another displayobj position
--@param obj the displayObj to animate
--@param target the displayObj to follow
--@param time time into which reach the target
--@param transition type of transition. default is LINEAR
function DisplayObjTweener.seekTargetPosition(obj,target,time,transition)
	local transition = transition or Transition.LINEAR
	local juggler = juggler or Shilke2D.current.juggler
	local tween = Tween.ease(obj,time,transition)
	tween:followEx(obj.setPosition_v2,obj.getPosition_v2,target,target.getPosition_v2)
	return tween
end
