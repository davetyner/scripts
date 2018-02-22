/*
--***********************************************************************************************
--
--  Created:  September 4th 2012
--  Author:   Dave Tyner
--  Polyform Animator Tool
--
--***********************************************************************************************

This script will batch animate objects based on selection order or based on proximity to another object

--***********************************************************************************************
-- 
-- MODIFY THIS AT YOUR OWN RISK
-- Additional Modifications:
-- Added Spring animation --WARNING - scene playback could struggle
-- Added animate by layer
-- Fixed stuff
--***********************************************************************************************
*/

macroScript PolyFormAnimatorinator category:"PolyFormTools"
(
	global objectsToAnimate = #()
	global obj_state_arr = #()
	global startFrameOffset = 0
	fn getLayers = (
	local lay = #()
		for l = 1 to layermanager.count-1 do
		(
			append lay (layermanager.getLayer l).name
		)
		return lay
	)
	
	fn getObjectsInLayers = (
		local layers, tarr,arr
		local layers = getLayers()
		for l in layers do(
			for o in objects where o.layer.name == l.name do append arr o
		)
	)
	
	fn compareFN v1 v2 =
	(
	local myD = $starting_point_dummy
	local d = (distance v1 myD)-(distance v2 myD)
	case of
	(
	(d < 0.): -1
	(d > 0.): 1
	default: 0
	)
	)	
				
	--for o in objects do (layermanager.getlayerfromname "3D_FACE").addnode o
	try(destroyDialog ThePolyAnimator)catch()
    Rollout ThePolyAnimator "Polyform Fast Animator-inator"
    (
		group "Select Objects"(
		button btn_collectObjects "Create From Selection" width:150 height:30
		)
		group "Animate Objects"(
		checkbox chk_anim "By distance from object"
		pickbutton pick_obj "Select" enabled:false width:150 height:30
		checkbox chk_layer "By Layer"

		dropdownlist ddl_layers "Animate by Layer" items:(getlayers()) enabled:false
			on chk_layer changed theState do (if ddl_layers.enabled==false then ddl_layers.enabled=true else ddl_layers.enabled=false)
		checkbox chk_alllayers "All Layers" enabled:false
		)

		group "Animation Options"(
        --spinner SPN_AnimationSegment "Animation Segment" range:[0,100,80] type:#integer

        spinner SPN_XROT "X Rotation" range:[-3600,3600,0] type:#integer
        spinner SPN_YROT "Y Rotation" range:[-3600,3600,0] type:#integer
        spinner SPN_ZROT "Z Rotation" range:[-3600,3600,0] type:#integer
        spinner SPN_XPOS "X Position" range:[-10000,10000,0] type:#integer
        spinner SPN_YPOS "Y Position" range:[-10000,10000,0] type:#integer
        spinner SPN_ZPOS "Z Position" range:[-10000,10000,0] type:#integer
		button btn_resetAnimationOptions "Reset All Animation Options"
		)
		group "Animation Extras" (
        checkbox chk_scale "Scale"
		checkbox chk_scaleToZero "Scale To Zero" enabled:false offset:[10,0]
		checkbox chk_reversescale "Reverse" enabled:false offset:[10,0]
        checkbox CHK_Spring "Spring"
		checkbox CHK_visibility "Visibility"
			checkbox CHK_debug "Debug"
		spinner SPN_opacityDuration "Opacity Duration" type:#integer
		)
		
		group "Animation Timing" (

			spinner SPN_TheStartFrame "Start Frame" range:[0,10000,1] type:#integer
			/*
			spinner SPN_TheEndFrame "End Frame Adjustment" range:[1,20000,100] type:#integer
			checkbox chk_theEndFrame "Lock To End Frame" checked:false offset:[160,0]
			*/
			spinner SPN_Duration "Duration" range:[1,128,10] type:#integer
			spinner SPN_Overlap "Overlap" range:[0,128,.0001] type:#float
			spinner SPN_TheFinalEndFrame "" range:[1,20000,(animationrange.end)] type:#float enabled:false
		)
		
		on btn_resetAnimationOptions pressed do (
				SPN_Duration.value = 1
				SPN_XROT.value = 0
				SPN_YROT.value = 0
				SPN_ZROT.value = 0
				SPN_XPOS.value = 0
				SPN_YPOS.value = 0
				SPN_ZPOS.value = 0
			)
		
		fn updateTheRightSpinner spn v = (
			local eFrame
			case spn of (
				"overlap":(
				--format "%\t%\n" spn v
					if v >= SPN_Duration.value then SPN_Overlap.value = SPN_Duration.value-.01
					--SPN_TheFinalEndFrame.value = ((SPN_Duration.value-SPN_Overlap.value)*objectstoanimate.count)
					local tObjs = objectstoanimate.count-1
					local eTotal = SPN_Duration.value
					local eOffset = SPN_Overlap.value
					local sFrame = SPN_TheStartFrame.value
					local eFrame = tObjs*(eTotal-eOffset)+(eTotal+sFrame)

				)
				"duration":(
				--format "%\t%\n" spn v
					if SPN_Overlap.value >= v then SPN_Overlap.value = SPN_Duration.value-.01
					--SPN_TheFinalEndFrame.value = (SPN_Duration.value-SPN_Overlap.value)*objectstoanimate.count
					local tObjs = objectstoanimate.count-1
					local eTotal = SPN_Duration.value
					local eOffset = SPN_Overlap.value
					local sFrame = SPN_TheStartFrame.value
					local eFrame = tObjs*(eTotal-eOffset)+(eTotal+sFrame)
				)
			)
			return eFrame
		)
		
		fn get_object_state objectstoanimate = obj_state_arr = (for o in objectstoanimate collect #(o,o.pos,o.rotation,o.scale,o.visibility.controller.value))
		
		fn set_object_state obj_state_arr = (
			local obj,pos,rot,scl,vis
			for o in obj_state_arr do (
				obj = o[1]
				pos = o[2]
				rot = o[3]
				scl = o[4]
				vis = o[5]
				obj.pos = pos
				obj.rotation = rot
				obj.scale = scl
				obj.visibility.controller.value = vis
			)
		)
		
		on chk_theEndFrame changed v do (
			case v of
			(
				true:(
					SPN_Overlap.enabled=false
					SPN_Duration.enabled=false
				)
				default:(
					SPN_Overlap.enabled=true
					SPN_Duration.enabled=true
				)
			)
		)
		on SPN_Overlap changed v1 do (
			val = updateTheRightSpinner "overlap" v1
			format "overlap val:%\n" val
			animationRange = interval 0 val
			SPN_TheFinalEndFrame.value = animationrange.end
		)
		on SPN_Duration changed v2 do (
			val = updateTheRightSpinner "duration" v2
			format "duration val:%\n" val
			animationRange = interval 0 val
			SPN_TheFinalEndFrame.value = animationrange.end
		)
		on SPN_TheStartFrame changed v do (
			local diff
			if startFrameOffset < 1.0 then startFrameOffset = 1.0
			val = updateTheRightSpinner "duration" SPN_Duration.value
			SPN_TheFinalEndFrame.value = animationrange.end
			if v>startFrameOffset then diff = (v - startFrameOffset)
			else diff = (startFrameOffset-v)*-1
			format "V val:%\n" v
			format "SFOS val:%\n" startFrameOffset
			format "diff val:%\n" diff
			animationRange = interval 0 (SPN_TheFinalEndFrame.value+diff)
			SPN_TheFinalEndFrame.value = animationrange.end
			startFrameOffset = v
		)
        button BTN_CreateAnimation "Create Animation" width:250 height:75 size:36
		group "Reset Stuff"(
			button BTN_ResetKeys "Reset Keys"
			button BTN_ResetAll "Reset All"
		)
		on ddl_layers selected val do (
			objectsToAnimate = for o in objects where o.layer.name == ddl_layers.items[val] collect o
			btn_collectObjects.text = (objectsToAnimate.count as string + " objects selected!")
		)
		

			
		on chk_scale changed thestate do
		(
			case thestate of
					(
						true: (
							chk_reversescale.enabled = true
							chk_scaleToZero.enabled=true 
						)
						default:(
							chk_reversescale.enabled = false
							chk_scaleToZero.enabled=false 
						)
					)
		)
		
		on chk_anim changed thestate do
		(
			case thestate of
					(
						true: pick_obj.enabled = true
						default:(
							pick_obj.enabled = false
							if objectsToAnimate != undefined then objectsToAnimate = for o in objectstoanimate collect o
						)
					)
		)
		
		on pick_obj picked obj do
		(
			pick_obj.text = obj.name
		)	

		on CHK_Spring changed theState do
		(
			if theState then
				(
					for a in objectsToAnimate do
					(
					a.pos.controller = SpringPositionController ()
					)
				)
			else
				(
					for a in objectsToAnimate do
					(
					a.pos.controller = Position_XYZ ()
					)
				)
		)
		
        on btn_collectObjects pressed do
        (
			local val
			objectsToAnimate = for o in selection collect o
			for o in objectsToAnimate do o.visibility = bezier_float()
			obj_state_arr = get_object_state objectsToAnimate
			format "%\t" obj_state_arr
			if objectsToAnimate.count>0 then btn_collectObjects.text = (objectsToAnimate.count as string + " objects selected!")
			max select none
			val = updateTheRightSpinner "duration" SPN_Duration.value
			animationRange = interval 0 (val+SPN_TheStartFrame.value)
			SPN_TheFinalEndFrame.value = animationrange.end
		)     
		
		on BTN_ResetKeys pressed do
        (
			
			deletekeys objectsToAnimate
			set_object_state obj_state_arr
			slidertime = 0f
        )
		
		on BTN_ResetAll pressed do
        (
			slidertime = 0f
			if objectsToAnimate.count>0 then (
				deletekeys objectsToAnimate
				for a in objectsToAnimate where a.pos.controller != Position_XYZ do a.pos.controller = Position_XYZ ()
				objectsToAnimate = #()
			)
			btn_collectObjects.text = "Create From Selection"
        )
		
        on BTN_CreateAnimation pressed do
        (
			clearlistener()
			local theCount,theStartFrame,theEndFrame,theRange,animLayer
			if objectstoanimate.count == 0 then (
				messagebox "Nothing to Animate!\nPlease Select Objects to Animate"
			)
			local debugmode=false
			if CHK_debug.checked==true then debugmode = true
			/*
			if chk_layer.checked then (
				if chk_alllayers.checked then (
					local layersToAnimate = getObjectsinLayers()
					for l in layersToAnimate do append objectsToAnimate l
				)
				objectsToAnimate =  for o in objects where matchpattern o.layer.name pattern:(ddl_layers.selected) collect o
			)
			*/
			--la = LayerManager.getLayerFromName "orig"
			animLayer = LayerManager.getLayerFromName "animLayer"
			if animLayer == undefined then animLayer = LayerManager.newLayerFromName "animLayer"
			--if la == undefined then la = LayerManager.newLayerFromName "orig"
			/*
			for s in thearr do (
				--s = snapshot o
				animLayer.addnode s
				--la.addnode o
				
			)
			*/
			--la.ishidden = true
			
			max select none

			thecount=objectsToAnimate.count as float
			
			thestartframe = SPN_TheStartFrame.value --frames
			
			theendframe = SPN_TheFinalEndFrame.value --frames
			
			case of
					(
						(thestartframe>theendframe):therange = (thestartframe-theendframe) as float
						default:therange = (theendframe-thestartframe) as float
					)
					
			case of
					(
						(therange<0): therange=therange*-1
						default: therange
					)

			local theinterval = SPN_Duration.value-SPN_Overlap.value -- (therange)/(thecount)

			local opacityDuration = SPN_opacityDuration.value

			local theduration = SPN_Duration.value --frames

			local thetime=thestartframe as float
					
			fn set_pivot = (
					for o in objectsToAnimate do o.pivot = [o.center[1],o.center[2], o.min[3]]
			)
			

			if chk_anim.checked==true then (
				d = Dummy()
				local tmp = getnodebyname pick_obj.text
				d.name = "starting_point_dummy"
				d.pos = tmp.pos
				qsort objectsToAnimate compareFN          
				delete d
			)
				
			local a,startTransform,startRot
            For b =1 to objectsToAnimate.count do
            (

				a = objectsToAnimate[b]
				if a.rotation.controller!=euler_xyz then a.rotation.controller = euler_xyz()
				if a.position.controller!=position_xyz then a.position.controller = position_xyz()
				startTransform = a.transform
				startRotx = a.rotation.controller[1].value
				startRoty = a.rotation.controller[2].value
				startRotz = a.rotation.controller[3].value

                --a.pos.z = (distance a myD)*.15
                if (CHK_visibility.state) do a.visibility = bezier_float()
-- 					print ("the dur: " + myDur as string)
-- 					print ("the CF: " + thecurrentframe as string)		
				
                with animate on
                (
                        if (chk_scale.state) do
                            (
								case (chk_reversescale.state) of
								(
									true: 
											(
												startscale = startTransform.scalepart
												endscale = [0.0001,0.0001,0.0001]
											)
									default: 
											(
												startscale = [0.0001,0.0001,0.0001]
												endscale = startTransform.scalepart
											)
								)
												if chk_scaleToZero.checked then (
													at time(1) scale a startscale
													at time(thetime) scale a endscale
													at time(thetime+theduration) scale a startscale
												) else (
													at time(1) scale a startscale
													at time(thetime) scale a startscale
													at time(thetime+theduration) scale a endscale
												)
                            )
								
					if debugmode then format "%\n" a
					
					at time(1) in coordsys local a.rotation.controller[1].value += SPN_XROT.value
                    at time(1) in coordsys local a.rotation.controller[2].value += SPN_YROT.value
                    at time(1) in coordsys local a.rotation.controller[3].value += SPN_ZROT.value
                    at time(1) a.position.controller[1].value += SPN_XPOS.value
                    at time(1) a.position.controller[2].value += SPN_YPOS.value
                    at time(1) a.position.controller[3].value += SPN_ZPOS.value
						if (CHK_visibility.checked==true) do at time (1) a.visibility.controller.value = 0.0
							
                    at time(thetime) in coordsys local a.rotation.controller[1].value = a.rotation.controller[1].value 
                    at time(thetime) in coordsys local a.rotation.controller[2].value = a.rotation.controller[2].value 
                    at time(thetime) in coordsys local a.rotation.controller[3].value = a.rotation.controller[3].value 
                    at time(thetime) a.position.controller[1].value = a.position.controller[1].value
                    at time(thetime) a.position.controller[2].value = a.position.controller[2].value
                    at time(thetime) a.position.controller[3].value = a.position.controller[3].value
						if (CHK_visibility.checked==true) then at time(thetime) a.visibility.controller.value = 0.0
					
					/*
					at time(thetime+theduration) a.pos.x  = a.pos.x
                    at time(thetime+theduration) a.pos.y  = a.pos.y
                    at time(thetime+theduration) a.pos.z  = a.pos.z
                    at time(thetime+theduration) in coordsys local a.rotation.controller[1].value = a.rotation.controller[1].value
                    at time(thetime+theduration) in coordsys local a.rotation.controller[2].value= a.rotation.controller[2].value
                    at time(thetime+theduration) in coordsys local a.rotation.controller[3].value = a.rotation.controller[3].value
					*/
					at time(thetime+theduration) a.transform = startTransform
					at time(0) a.transform = startTransform
                    at time(thetime+theduration) in coordsys local a.rotation.controller[1].value = startRotx
                    at time(thetime+theduration) in coordsys local a.rotation.controller[2].value= startRoty
                    at time(thetime+theduration) in coordsys local a.rotation.controller[3].value = startRotz
						if (CHK_visibility.checked==true) then at time(thetime+theduration) a.visibility.controller.value  = 1.0
						if (CHK_visibility.checked==true) do at time (0) a.visibility.controller.value = 1.0
                   --at time (0) a.visibility.controller.value = 0.0
                )
				if thetime == 1 then thetime+=(theinterval-1)
                else thetime+=(theinterval)
				--format ("at % the interval is %\n") thetime theinterval
				--if b==objectsToAnimate.count and SPN_Overlap.value>0 then animationrange = interval 0 (thetime+theInterval)
				--else animationrange = interval 0 (thetime)
			)
		)
)
	
        Createdialog ThePolyAnimator 300 900

)