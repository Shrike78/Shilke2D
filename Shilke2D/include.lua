--[[---
Shilke2D/include is the entry point for each project based on Shilke2D.
There are some specific Shilke2D configuration options that can be set before including
this file. 

All the following options by default are set to false. Setting them to true allows to 
change default Shilke2D behaviour.
--]]

---
-- Select coordinate system.
-- 
-- Shilke2D default coordinate system has (0,0) as topleft point and y grows from top to bottom. 
-- It's possible to change coordinate system having (0,0) as bottomleft point and y growing from 
-- bottom to top (so called coordinate system) setting this option to true
-- By default is set to false
__USE_SIMULATION_COORDS__ = __USE_SIMULATION_COORDS__ == true

---
-- Select if rotation are expressed in degrees or radians.
-- 
-- By default Shilke2D uses radians for rotations. It's possible to switch to degrees 
-- (the default MOAI behaviour) setting this option to true. 
__USE_DEGREES_FOR_ROTATIONS__ = __USE_DEGREES_FOR_ROTATIONS__ == true


---
-- Choose between MOAIJsonParser and Shaun Brown lua Json parser module.
-- 
-- By default MOAI native parser is used.
-- It's possible to use Shaun Brown lua json parser setting this option to true
__USE_LUAJSONPARSER__ = __USE_LUAJSONPARSER__ == true


---
-- By deafult Quads support both vertex color and "prop" color, so final color result
-- is obtained as combination of the two color info. It's possible to override this
-- behaviour forcing to use only vertex color setting this option to true
__QUAD_VERTEX_COLOR_ONLY__ = __QUAD_VERTEX_COLOR_ONLY__ == true

-- debug features

---
-- Enable debug of callbacks.
-- 
-- This feature relies on ZeroBraneStudio mobdebug feature so it can be enabled only
-- when debugging from this IDE. By default is set to false
__DEBUG_CALLBACKS__ = __DEBUG_CALLBACKS__ == true


---
-- Enable assertion.
-- 
-- By default assertion are not evaluated to speed up the code.
-- If set to true, program execution is interrupted on positive assertion.
__DEBUG_ASSERT__ = __DEBUG_ASSERT__ == true


---	
-- Put juggler on a separate coroutine. 
-- 
-- By default the main juggler is updated in the mainLoop coroutine, before the update function call.
-- Setting this to true forces the main juggler to be updated on a separate coroutine executed 
-- before the mainLoop coroutine. Can be usefull for debug purposes, in order to avoid debug of juggler
-- update if __DEBUG_CALLBACKS__ is set to false.
__JUGGLER_ON_SEPARATE_COROUTINE__ = __JUGGLER_ON_SEPARATE_COROUTINE__ == true


require("Shilke2D/Utils/Assert")
require("Shilke2D/Utils/MOAIVersion")
require("Shilke2D/Utils/ClassEx")
require("Shilke2D/Utils/Shape")
require("Shilke2D/Utils/Callbacks")
require("Shilke2D/Utils/IO")
require("Shilke2D/Utils/Log")
require("Shilke2D/Utils/Color")
require("Shilke2D/Utils/Graphics")
require("Shilke2D/Utils/Table")
require("Shilke2D/Utils/Sound")
require("Shilke2D/Utils/PerformanceTimer")
require("Shilke2D/Utils/ObjectPool")

require("Shilke2D/Utils/Polygon")
require("Shilke2D/Utils/PathFinding")
require("Shilke2D/Utils/Coroutines")

require("Shilke2D/Utils/Bitmap/BitmapRegion")
require("Shilke2D/Utils/Bitmap/BitmapData")

require("Shilke2D/Utils/Config/IniParser")
require("Shilke2D/Utils/Config/Json")
require("Shilke2D/Utils/Config/XmlNode")

require("Shilke2D/Utils/Math/Math")
require("Shilke2D/Utils/Math/Bezier")
require("Shilke2D/Utils/Math/BitOp")
require("Shilke2D/Utils/Math/Vec2")

require("Shilke2D/Utils/String/String")
require("Shilke2D/Utils/String/StringBuilder")
require("Shilke2D/Utils/String/StringReader")

--Shilke2D/Core
require("Shilke2D/Core/Assets")
require("Shilke2D/Core/Event")
require("Shilke2D/Core/EventDispatcher")
require("Shilke2D/Core/IAnimatable")
require("Shilke2D/Core/Juggler")
require("Shilke2D/Core/TouchSensor")
require("Shilke2D/Core/Shilke2D")
require("Shilke2D/Core/Timer")
--should be included only on dektop devices, with modified sdk host 
--(basic glut host do not handle special keys)
require("Shilke2D/Core/Keymap")

--Shilke2D/Display
require("Shilke2D/Display/BlendMode")
require("Shilke2D/Display/DisplayObj")
require("Shilke2D/Display/DisplayObjContainer")
require("Shilke2D/Display/Stage")
require("Shilke2D/Display/BaseQuad")
require("Shilke2D/Display/Quad")
require("Shilke2D/Display/Image")
require("Shilke2D/Display/MovieClip")
require("Shilke2D/Display/TextField")
require("Shilke2D/Display/Button")
require("Shilke2D/Display/DrawableObj")
--included here because it requires DisplayObjContainer
require("Shilke2D/Core/Stats")

--Shilke2D/Texture
require("Shilke2D/Texture/Texture")
require("Shilke2D/Texture/SubTexture")
require("Shilke2D/Texture/RenderTexture")
require("Shilke2D/Texture/ITextureAtlas")
require("Shilke2D/Texture/TextureAtlas")
require("Shilke2D/Texture/TextureAtlasComposer")
require("Shilke2D/Texture/TexturePacker")
require("Shilke2D/Texture/TextureManager")

require("Shilke2D/Tween/Tween")
require("Shilke2D/Tween/TweenDelay")
require("Shilke2D/Tween/Transition")
require("Shilke2D/Tween/TweenEase")
require("Shilke2D/Tween/TweenBezier")
require("Shilke2D/Tween/TweenParallel")
require("Shilke2D/Tween/TweenLoop")
require("Shilke2D/Tween/TweenSequence")
require("Shilke2D/Tween/DisplayObjTweener")
