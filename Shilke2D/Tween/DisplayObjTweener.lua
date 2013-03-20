 --[[
DisplayObjTweener

helper to animate displayObjs. It's a set of wrapper function over Tween.ease() that allows to easily
animate displayObjs properties (position, scale, rotation, color, alpha).

Default transition for each transiformation is Transition.LINEAR
--]]

DisplayObjTweener = {}

function DisplayObjTweener.seekProp(obj,setter,getter,endValue,time,transition)
	local transition = transition or Transition.LINEAR
	local tween = Tween.ease(obj,time,transition)
	tween:seekEx(setter,getter,endValue)
	return tween
end

function DisplayObjTweener.moveProp(obj, setter,getter,deltaValue,time,transition)	
	local transition = transition or Transition.LINEAR
	local tween = Tween.ease(obj,time,transition)
	tween:moveEx(setter,getter,deltaValue)
	return tween
end

function DisplayObjTweener.seekAlpha(obj,a,time,transition)
	return DisplayObjTweener.seekProp(obj,obj.setAlpha,obj.getAlpha,a,time,transition)
end

function DisplayObjTweener.moveAlpha(obj,a,time,transition)
	return DisplayObjTweener.moveProp(obj,obj.setAlpha,obj.getAlpha,a,time,transition)
end

function DisplayObjTweener.seekColor(obj,c,time,transition)
	return DisplayObjTweener.seekProp(obj,obj.setColor,obj.getColor,c,time,transition)
end

function DisplayObjTweener.moveColor(obj,c,time,transition)
	return DisplayObjTweener.moveProp(obj,obj.setColor,obj.getColor,c,time,transition)
end

function DisplayObjTweener.seekPosition(obj,x,y,time,transition)
	return DisplayObjTweener.seekProp(obj,obj.setPosition_v2,obj.getPosition_v2,vec2(x,y),time,transition)
end

function DisplayObjTweener.movePosition(obj,x,y,time,transition)
	return DisplayObjTweener.moveProp(obj,obj.setPosition_v2,obj.getPosition_v2,vec2(x,y),time,transition)
end

-- used to follow another displayobj
function DisplayObjTweener.seekTarget(obj,target,time,transition)
	local transition = transition or Transition.LINEAR
	local juggler = juggler or Shilke2D.current.juggler
	local tween = Tween.ease(obj,time,transition)
	tween:followEx(obj.setPosition_v2,obj.getPosition_v2,target,target.getPosition_v2)
	return tween
end

function DisplayObjTweener.seekRotation(obj,r,time,transition)
	return DisplayObjTweener.seekProp(obj,obj.setRotation,obj.getRotation,r,time,transition)
end

function DisplayObjTweener.moveRotation(obj,r,time,transition)
	return DisplayObjTweener.moveProp(obj,obj.setRotation,obj.getRotation,r,time,transition)
end

function DisplayObjTweener.seekScale(obj,sx,sy,time,transition)
	return DisplayObjTweener.seekProp(obj,obj.setScale_v2,obj.getScale_v2,vec2(sx,sy),time,transition)
end

function DisplayObjTweener.moveScale(obj,sx,sy,time,transition)
	return DisplayObjTweener.moveProp(obj,obj.setScale_v2,obj.getScale_v2,vec2(sx,sy),time,transition)
end
