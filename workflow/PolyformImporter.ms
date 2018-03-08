/*
--***********************************************************************************************
--
--  Created:  December 2012
--  Author:   Dave Tyner
--  Polyform Importer Tool
--
--***********************************************************************************************

This script will batch import files into 3DS Max

--***********************************************************************************************
-- 
-- MODIFY THIS AT YOUR OWN RISK
--***********************************************************************************************
*/

				
macroScript PolyformImporter category:"PolyFormTools"
(

	try(destroyDialog ImportExport)catch()

fn clean_file_name theName = (
	local str = ""
	local nm = filterstring theName "\\\"*/?><!@#$%^&()[]:,;- _'"
	if nm.count>0 then	str = nm[nm.count]
	else str = str
		--str = nm[nm.count]
		--format "%\n" str
	return str
)

fn add_to_layer obj str = (
	local layno, lay, searchStr
	layno = 0
	for l = 1 to layermanager.count-1 do
	(
		lay = (layermanager.getLayer l).name
		--format "%\n" lay
		if lay == str then layno = layermanager.getLayer l
	)
	if layno == 0 then layno = layermanager.newlayerfromname (clean_file_name str)

	layno.addnode obj
	--if (LayerManager.getLayerFromName str).current ==false then (LayerManager.getLayerFromName str).current = true
)

fn writetolog dir larr fileLog=
(				
			local t = localtime							
			local exportlog = openfile fileLog mode:"a"
			format "%\n" t to:exportlog
			for i = 1 to larr.count do format "% % seconds\n" larr[i][1] larr[i][2] to:exportlog
			format "<--##############################-->\n" to:exportlog	
			close exportlog
)

fn xrefobjs dirname mergebool = 
(
				resetmaxfile #noprompt
				for f in (getFiles (dirName+"\\*.max")) do
				 (
					mf = xrefs.addNewXrefFile f
					if mergebool then merge mf
				 )
)


fn unparent =
(
	local startobjects = objects.count
	local delete_these_items=#()
	for o in geometry where o.parent != undefined do (
		o.controller=prs()
		if classof o.parent == LinkComposite then
		(
			o.parent = undefined
		) else ( 
			o.parent = undefined
		)
	)
	for sp in objects where classof sp == splineshape do append delete_these_items sp
	for o in geometry where classof o == LinkComposite do converttomesh o --append delete_these_items o
	for o in geometry where classof o == LinkComposite do append delete_these_items o
	for o in objects where classof o == NURBSCurveshape do append delete_these_items o
	for o in objects where classof o == Dummy do append delete_these_items o
		
	local count = delete_these_items.count
	local layer_name = "delete_this"
	if count > 0 then (
		for d = 1 to delete_these_items.count do (
			--add_to_layer delete_these_items[d] layer_name
		)
	)
	return delete_these_items
)

	Rollout ImportExport "Import/Export"
(

	group "Directory and files"
		(
			edittext txt_dir "Directory" align:#left across:2 width:400
			button btn_browse "..." align:#right width:20 
			edittext txt_pre "Prefix:" text:"" tooltip:"Put your file prefix here" align:#left width:105 
			edittext txt_ext "Extension" text:"fbx" align:#left width:105
			--edittext txt_suf "Sufffix: *" text:"" tooltip:"Put your suffix here" align:#left width:105
			label lblNumFiles "No files selected"
			button btnUpdate "Update" align:#center
		)
	group "File Options"
		(
			checkbox chk_file_link_manager "Link File"
			checkbox chkIMP "Import" checked:true	
			checkbox chkCreateMaxFile "Save import as .Max file" across:2
			checkbox chkMergeXrefs "Merge Xrefs" enabled:false offset:[-50,0]
			checkbox chk_prefixmodelname "File Name Prefix" tooltip:"This will prefix each object with the file that it came from" align:#left --offset:[-45,0]
		)
	group "Scale and Offset Options"
		(
			checkbox chk_scale "Scale Objects" across:2 
			spinner spn_scale_value value:1.0 offset:[-250,0] width:50 enabled:false range:[-10000,10000.0,1.0]
			checkbox chk_auto_offset "Automatically Offset Models" 
			checkbox chk_offset "Offset Models" across:4
			spinner spn_offset_x "X" offset:[-50,0] width:100 enabled:false range:[-1000000,1000000.0,1.0] 
			spinner spn_offset_y "Y" offset:[-50,0] width:100 enabled:false range:[-1000000,1000000.0,1.0]
			spinner spn_offset_z "Z" offset:[-50,0] width:100 enabled:false range:[-1000000,1000000.0,1.0]
		)
		group "Edit Geometry" (
			checkbox chkSmooth "Smooth Modifier" across:2 enabled:false
			edittext txt_NoSmoothType text:"beam,stair,steel" width:75 tooltip:"Do not apply smooth modifier to files with this prefix"
			checkbox chk_unparent "Unparent Objects" align:#left checked:true
			label lbl_status "Ready"
		)
		group "Do it!"
		(
			button btn_Import "GO" width:75 height:40
		)
		

		
		fn stringEscape str =
			"\"" + str + "\" "

		fn tryParse str =
			 str
		
		local outputPath = getDir #temp
		local objExportConfig = objExp.getIniName()
		local objImportConfig = objImp.getIniName()
		local iniFile = getDir #temp + "\\polyformimporter.ini"
		
	fn loadIniFile single bool str = (
		if doesFileExist iniFile do	 (
			format "%\t%\t%\t%\n" iniFile single bool str
			
			for ctrl in ImportExport.controls do case (classOf ctrl) of
			(
				RadioControl : if single.TryParse (getIniSetting iniFile "Controls" ctrl.name) &res1 then (ctrl.state = res1; ctrl.changed res1)
				SpinnerControl : if single.TryParse (getIniSetting iniFile "Controls" ctrl.name) &res2 then ctrl.value = res2
				CheckBoxControl : if bool.TryParse (getIniSetting iniFile "Controls" ctrl.name) &res3 then ctrl.checked = res3
				EditTextControl: (
					--format "EditTextControl: %\n" (getIniSetting iniFile "Controls" ctrl.name)
					ctrl.text = (getIniSetting iniFile "Controls" ctrl.name)
				)
			)
		)
	)

	fn saveIniFile = (
		for ctrl in ImportExport.controls do case (classOf ctrl) of
		(
			RadioControl : setIniSetting iniFile "Controls" ctrl.name (ctrl.state as string)
			SpinnerControl : setIniSetting iniFile "Controls" ctrl.name (ctrl.value as string)
			CheckBoxControl : setIniSetting iniFile "Controls" ctrl.name (ctrl.checked as string)
			EditTextControl : setIniSetting iniFile "Controls" ctrl.name (ctrl.text as string)
		)
	)
		
	on ImportExport open do
	(
		local single = dotNetClass "System.Single"
		local bool = dotNetClass "System.Boolean"
		local str = dotNetClass "System.String"
		loadIniFile single bool str
	)
	
	on ImportExport close do
	(
		saveIniFile()
	)
	
		on chk_file_link_manager changed state do
		(
			chkIMP.checked = false
		)
		
		on chk_offset changed state do
		(
			spn_offset_x.enabled = state
			spn_offset_y.enabled = state
			spn_offset_z.enabled = state
		)
		
		on chk_scale changed state do
		(
			spn_scale_value.enabled = state
		)
		
		on chkCreateMaxFile changed state do
		(
			if not chkMergeXrefs.enabled then chkMergeXrefs.enabled = true else chkMergeXrefs.enabled = false
			--if chkMergeXrefs.enabled == false then chkMergeXrefs.enabled = true else chkMergeXrefs.enabled = false
		)
		
		on chkIMP changed state do
		(
			chk_file_link_manager.checked = false
		)
		
		on chk_prefixmodelname changed state do
		(
			if not chkSmooth.enabled then chkSmooth.enabled = true else chkSmooth.enabled = false
		)
		
		on btn_browse pressed do
		(
			local fpath = getSavePath initialDir:sysinfo.currentdir caption:"Select any file in the source directory:" 
			importDrawingPath = fpath
			--shellLaunch "explorer.exe" (getdir #scene)
			if fpath != undefined then
			(
			local extension = txt_ext.text
			local pfix = if txt_pre.text == "" then pfix = "*" else pfix = txt_pre.text 
			local thepath = fpath + "\\" +  pfix + "." + extension
			local dcount = (for f in getfiles (thepath) collect f).count
			if dcount > 0 then 
				(
					lblNumFiles.text = dcount as string + " files will be imported"
					importDrawingPath = fpath + "\\" + pfix + "." + extension 
					txt_dir.text = fpath
				)
			)
			btnUpdate.enabled = true
		)
		
		on btnUpdate pressed do
		(
			local importDrawingPath = ImportExport.txt_dir.text
			local pfix = ImportExport.txt_pre.text
			if pfix == "" then pfix = "*"
				format "%\n" (getfilenamepath importDrawingPath)
				format "%\n" pfix
				format "%\n" ImportExport.txt_ext.text
			local thepath = importDrawingPath + "\\" +  pfix + "." + ImportExport.txt_ext.text
			format "%\n" thepath
			if not importDrawingPath == undefined then  importDrawingPath = thePath else global importDrawingPath = thePath
			local dcount = (for f in getfiles (thepath) collect f).count
						if dcount > 0 then 
									(
										lblNumFiles.text = dcount as string + " files will be imported"
										--txt_dir.text = thepath
									) else (
										lblNumFiles.text = "No files will be imported"
									)
		)
		
		on btn_Import pressed do
		(
			
			clearlistener()	
			--disablesceneredraw()
			fn clean_file_name theName = (
				local str = ""
				if theName == undefined then continue
				local nm = filterstring theName "\\\"*/?><!@#$%^&()[]:,;- _\\\r\\\n'"
				if nm.count>0 then (
					for n = 1 to nm.count do (
						if n==1 then str = nm[n]
						else str = str+"_"+nm[n]
					)
					--str = nm[nm.count]
					--format "%\n" str
					return str
				)
				return theName
			)


				

						
						
			local starttime=timestamp()
			local theobj = #()
			local thedwg = #()
			local s = smooth()
			local noSmooth = filterstring txt_NoSmoothType.text ","
			s.autosmooth=true

			local exportfilelog = txt_dir.text + "\\importlog.txt"
			local importFileList = txt_dir.text + "\\importFileList.txt"
			if doesFileExist exportfilelog == false then
				( 
					cf = createFile exportfilelog
					close cf
				)
			local importDrawingPath = ImportExport.txt_dir.text
			local pfix = ImportExport.txt_pre.text
			if pfix == "" then pfix = "*"
			local thepath = importDrawingPath + "\\" +  pfix + "." + ImportExport.txt_ext.text
						--importDrawingPath = "C:\\Users\\dave\\Downloads\\test\\test\\"
						for f in getfiles (thepath) do append thedwg f
						for tf = 1 to thedwg.count do
									(
										local logarr = #()
										local mfn = clean_file_name (getfilenamefile thedwg[tf])
										format "%\n" mfn
										--set current layer to 0
										(layermanager.getlayer 0).current = true
										--create new layer
										local lay = layermanager.newlayerfromname mfn
										--set new layer as current
										lay.current = true
										local startIntTime = timestamp()
												local filename = filenameFromPath thedwg[tf]
												if chk_file_link_manager.checked then
												(
													
													filelinkmgr.attach thedwg[tf]
													
												) else (
															if chkCreateMaxFile.checked == true then
															(
																resetmaxfile #noprompt
																savefile = txt_dir.text + "\\" + mfn + ".max" --@"C:\Dropbox\projects\iso15926\Plant3D Sample\exported acad file\" + mfn + ".max"
																if tf != 1 then importFile thedwg[tf] #noprompt else importFile thedwg[tf]

																
																append logarr #(savefile)
															)	else (												
																if tf != 1 then importFile thedwg[tf] #noprompt 
																else importFile thedwg[tf]
																--importObjects thedwg[tf] false false
-- 																					for o = 1 to geometry.count where geometry[o].isfrozen == false do (
-- 																						obj = geometry[o]
-- 																						local t_name =  (clean_file_name obj.name)
-- 																						obj.name = t_name + "_" + (o as string)
-- 																						add_to_layer obj mfn
-- 																					)
-- 																					geometry.isfrozen = true
																append logarr #(thedwg[tf])
															)
												)
												
												--add all objects to layer 0
												--for o in objects do add_to_layer o ""
													

													

												--add_to_layer p mfn
												
												local objs = for o = 1 to objects.count where objects[o].layer.name == mfn collect objects[o] 
												--objs.parent = p
												for o = 1 to objs.count do ( --(superclassof o) == GeometryClass and objects[o].layer.name == "" do (
													obj = objs[o]
													if (isvalidnode obj) == false then continue
													local t_name =  (clean_file_name obj.name)
													if chk_prefixmodelname.checked == true then obj.name = mfn + "_" + t_name + "_" + (o as string)
													else obj.name = t_name + "_" + (o as string)
												)
													
												if chk_unparent.checked == true then
												(
													local deleted_items = unparent()
													if deleted_items.count > 0 then (
														for del in deleted_items do add_to_layer del "deleted"
													)
													delete deleted_items
													lbl_Status.text = "Deleted " + thecount as string + " helpers"
												)	
												
												--local p = point name:mfn
												
												
										--if chk_prefixmodelname.checked == true then local impobjs = importObjects mfn nosmooth	s					
										if chkCreateMaxFile.checked == true then savemaxfile savefile
													
										local finIntTime = timestamp()

										local intTotal = ((finIntTime-startIntTime)/1000) as float
										append logarr #("File Import Time: ", intTotal)
										writetolog txt_dir.text logarr exportfilelog
										format "imported % in %\n" filename intTotal
									)
								
								local parent_points = #()
								for x = 1 to layermanager.count-1 do (
									local lay = layermanager.getlayer x
									local objs = for o = 1 to geometry.count where geometry[o].layer.name == lay.name collect geometry[o]
									--format "%\t%\n" objs.count lay.name
									lay.current = true
									local master_parent = point name:("OG_" + lay.name)
									append parent_points master_parent
									for o in objs do (
										o.parent = master_parent 
									)
								)	
								
								local new_objs = #()
								local max_distance = 0
								local offset = [0,0,0]
								local scale_factor = 1.0
									
								
								--collect the parents
								--scale the model if selected
								if ImportExport.chk_scale.checked == true then (
									scale_factor = spn_scale_value.value
									if parent_points.count > 0 then 
									(
										for n = 1 to parent_points.count do (
											local obj = parent_points[n]
											if ImportExport.chk_scale.checked == true then (
												scale obj [scale_factor,scale_factor,scale_factor]
												--local x = xform()
												--addmodifier obj x
												--converttomesh obj
												--update obj
											)
										)
									)
								)
								
								--get max distance from 0,0,0	
								for o in geometry do (
									append new_objs o
									local dist = (distance [0,0,0] o.pos) 
									if dist > max_distance then (
										max_distance = dist
										offset = o.center
									)
								)
								--if we're auto offsetting, we have it ready
								if ImportExport.chk_auto_offset.checked == true then(
									for obj in geometry do 
									(
										obj.pos = obj.pos-offset
										obj.pivot = obj.center
										ImportExport.spn_offset_x.value = offset.x
										ImportExport.spn_offset_y.value = offset.y
										ImportExport.spn_offset_z.value = offset.z
									)
								) else (
									if ImportExport.chk_offset.checked == true then (
										for obj in geometry do 
										(
											local x = ImportExport.spn_offset_x.value
											local y = ImportExport.spn_offset_y.value
											local z = ImportExport.spn_offset_z.value
												offset = [x,y,z]
												obj.pos = obj.pos-offset
												obj.pivot = obj.center
										)
									)
								)
								--new_objs.isfrozen = true		
												
	
		local tend=timestamp()
		local mbool = false
		local intTotal = ((tend-starttime)/1000) as float
		if chkMergeXrefs.checked == true then mbool = true
		if chkCreateMaxFile.checked == true then xrefobjs txt_dir.text mbool
		format "imported % files in %\n seconds" thedwg.count intTotal 
		lbl_Status.text = "Imported " + thedwg.count as string + " files in " + intTotal as string + " seconds"
		enablesceneredraw()									
		
		)
)

 Createdialog ImportExport 450 500
)
