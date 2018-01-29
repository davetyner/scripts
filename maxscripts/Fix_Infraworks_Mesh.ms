/*
--***********************************************************************************************
--
--  Created:  September 2016
--  Author:   Dave Tyner
--  Infraworks Meshinator-inator
--
--***********************************************************************************************

This script will 
- fix the black tiles after an Infraworks import
- Fix the Infraworks texture file paths
- Rename all objects and materials to the names of their textures
--OPTIONAL
- Add normal maps to material bump slot
	
--***********************************************************************************************
-- ALWAYS MAKE A BACKUP OF YOUR ORIGINAL SCENE BEFORE PERFORMING BATCH PROCESSING
-- USE AND MODIFY THIS AT YOUR OWN RISK

--***********************************************************************************************
*/


	/*(
		clearlistener()
		new_path = @"C:\Users\dave\Documents\iwx\tex"
		fixMulti = true --fix black tiles
		cleanBitmaps = true --scrub the . from the file/path name
		setMaterial = false --rename material and tile to new texture name
		addBump = true
		swapMaterial = false
	*/

	/*
	--***********************************************************************************************
	-- DON'T MODIFY BELOW HERE UNLESS YOU'RE OSOM
	--***********************************************************************************************
	*/

	--fix the black tiles after an Infraworks import
	fn fix_multi = (
		local objs, m, map, b

		objs = for o in selection where superclassof o == GeometryClass collect o
		for o in objs do (
			m = o.material
			if (classof m == Multimaterial) then 
			(
				-- This is a multi-sub material, so loop through all submaterials
				for i in m.materialIdList do 
				(
					submat = m[i]
					map = submat.diffusemap
					if map == undefined then continue
					if classof map == MultiTile then (
						if (map.getTileTexmap 1)!=undefined then (
							b = bitmaptexture()
							current_texture = (map.getTileTexmap 1).filename
							b.filename = current_texture
							b.coords.V_Tiling = -1
							submat.diffusemap = b
						)
					)
				)
			) else (			
				map = m.diffusemap
				if map == undefined then continue
				if classof map == MultiTile then (
					if (map.getTileTexmap 1)!=undefined then (
						b = bitmaptexture()
						current_texture = (map.getTileTexmap 1).filename
						b.filename = current_texture
						b.coords.V_Tiling = -1
						m.diffusemap = b
					)
				)
			)
		)
	)

	--This function will rename the objects material and mesh to the texture name
	fn set_object_material_name = (
		local objs
	objs = for o in selection where superclassof o == GeometryClass and o.material!=undefined collect o
			max select none
		local m, b, n, bm, bitmap_path
		for o in objs do (
			select o
			m = o.material
			if classof m==multimaterial then continue
			if m == undefined or (isproperty m.diffusemap "filename") == false then continue
			b = m.diffusemap.filename
			bitmap_file = getfilenamefile b
			o.name = bitmap_file
			o.material.name = bitmap_file
		)
	)

	fn add_bump what = (
		local objs = for o in selection collect o
			max select none
		for o in objs do (
			try(
			select o
		local m, b, n, bm, bitmap_path
			m = o.material
			if m == undefined or (isproperty m.diffusemap "filename") == false then continue-- m.diffusemap == undefined then continue
		b = m.diffusemap.filename
		if what == "normal" then (
		n = normal_bump()
			bm = Bitmaptexture()
			bitmap_path = getfilenamepath b
			bm_filename = (bitmap_path) + (getfilenamefile b) + "_nrm.jpg"
			bm.filename = bm_filename
			--n.bump_map = bm
			m.bumpmap=bm
			--update
		) else if what == "diffuse" then (
			bitmap_path = getfilenamepath b
			bm_filename = bitmap_path + (getfilenamefile b) + ".jpg"
			m.diffusemap.filename = bm_filename
			--o.material = m
		)
		) catch ( print "fail")
		--max select none
		)
	)

	fn assign_properties m mat metallic roughness = (
		if classof m == DirectX_9_Shader then continue
		if m.diffusemap != undefined then (
					mat.TEX_color_map = openBitmap m.diffusemap.filename
					mat.use_color_map = 1.0
				)
				if m.bumpmap != undefined then(
					mat.TEX_normal_map = openBitmap m.bumpmap.filename
					mat.use_normal_map = 1.0
				)
				if m.opacitymap != undefined then (
					mat.TEX_opacity_map = openBitmap m.opacitymap.filename
					mat.use_opacity_map = 1.0
				)
				mat.base_color = m.diffuse
				mat.metallic = metallic
				mat.roughness = roughness
				
				return mat
	)

	fn swap_material = (
		local objs, mat, xm, dif, nrm, metallic, roughness, newmat
		
		metallic = 1.0
		roughness = .91 
		
		objs = for o in selection where o.material != undefined collect o
			
		mat = $box001.material
		
		for o in objs do (
			/*
					-- set the bitmap tile to 1.0 and offset to 0.0
			obj.material.diffusemap.coordinates.U_Offset = 0.0
			obj.material.diffusemap.coordinates.V_Offset = 0.0
			obj.material.diffusemap.coordinates.U_Tiling = 1.0
			obj.material.diffusemap.coordinates.V_Tiling = 1.0

			-- transform UV's to match textures
			addModifier obj (uvw_xform())
			obj.modifiers[1].V_Tile = -1.0
																			   
			-- collapse stack
			collapseStack obj
			*/
			m = undefined
			m = o.material
			if classof o.material == Multimaterial then(
				for i = 1 to o.material.materiallist.count do (
					m = o.material.materiallist[i]
					xmat = copy mat
					xmat.name = m.name
					m.name = "_old_" + m.name
					newmat = assign_properties m xmat metallic roughness
					o.material.materiallist[i] = newmat
				)
			) else (
				xmat = copy mat
				xmat.name = m.name
				m.name = "_old_" + m.name
				newmat = assign_properties m xmat metallic roughness
				o.material = newmat
			)
			
			
		)
	)

		-- Determines if the file exists.
		fn FileExists filePath = (
			(getfiles filePath).count != 0
		)
		
	fn clean_bitmaps new_path = (
		local _objs,objs,fullpath,filename,extension,newfilename,fromfile,tofile,result,mat
		_objs = for o in selection where o.material != undefined  collect o
		objs = for o in _objs where o.material.diffusemap != undefined collect #(o,o.material)
		
		for o in objs do (
			result = undefined
			mat = o[2]
			fullPath = mat.diffusemap.filename --filenameFromPath texMap.filename
			filename = getFilenameFile fullPath
			extension = getFilenameType fullPath
			-- New material name - substitute periods "." with underscores "_"
			newFilename = substituteString filename "." "_"
			o[1].name = newFilename
			o[2].name = newFilename
			-- If no changes are required to the filename then return.
			--if newFilename == filename then return result
			
			-- Rename the original filename
			fromFile = fullPath
			toFile = new_path + @"\" + newFilename + extension
			
			-- Delete the existing file if it exists.
			if (FileExists toFile) then (
				o[2].diffusemap.fileName = toFile
				continue
			) --renameFile toFile ("_old" + toFile)
			
			-- Copy the file to the desired location.
			
			if copyFile fromFile toFile == false then (
				-- do nothing.
				print ("fromFile: " + fromFile)
				print ("toFile: " + toFile)
				print "COPY FAILED"
			) else (
				--result = toFile
			)
			
			if (FileExists toFile) then (
				o[2].diffusemap.fileName = toFile
				--o[2].diffusemap.reload()
			)
			
		)
		
	)

	try(destroyDialog polyform_meshinator_form)catch()
	--try(destroyDialog polyform_meshinator_form.PolyLMParent)catch() --try to destroy it if it already exists as a dialog
	rollout polyform_meshinator_form "Polyform IWX Meshinator" height:500--define the rollout 
	(
		group "Deselect All"
		(
			button btn_deselect "Deslect All"
		)
		on btn_deselect pressed do (
			max select none
		)
			
			group "Clean Up"
				(
					checkbox chk_unparent "Unparent Objects" align:#left
					checkbox chk_deleteHelpers "Delete Helpers" align:#left
					checkbox chk_centerPivot "Center Pivot" align:#left
					--checkbox chk_deleteSplines "Delete Splines" align:#left
					button btn_cleanGo "Clean It" width:150 height:25
				)
		on btn_cleanGo pressed do
		(
			if chk_unparent.state == true then for o in geometry do o.parent = undefined
			if chk_deleteHelpers.state == true then delete helpers
			if chk_centerPivot.checked == true then (
				for o in geometry do o.pivot = o.center
			)
		)
			group "Bitmap Options"
				(
					button btn_new_path "Browse" enabled:true
					edittext bws_ExportTextures "New Texture Path" enabled:true
					label bws_label ""
					checkbox fixMulti "Fix Black Tiles" checked:true	
					checkbox cleanBitmaps "Clean Bitmaps" checked:true	
					button btn_go "Go" enabled:true width:150 height:50
					--checkbox setMaterial "Export Objects to FBX" checked:true	
					--checkbox swapMaterial "Export Objects to FBX" checked:true	
				)
				
		on btn_new_path pressed do
		(
			local folderPath = getSavePath()
			if folderPath!=undefined and folderPath!= "" then bws_ExportTextures.text = folderPath
		)
		
		fn checkpath p = (
			local str = filterstring p "\\"
			if str.count > 1 then (
				return true
			)
			else return false
		)
		on btn_go pressed do (
			local txt = bws_ExportTextures.text
			local b  = checkpath txt
			if b == true and doesfileexist txt  == true then (
				local thepath = bws_ExportTextures.text
				if fixMulti.checked == true then fix_multi()
				if cleanBitmaps.checked == true then clean_bitmaps thepath
			) else (
				bws_label.text = "INVALID PATH"
			)
		)
		--end do
			--if fixMulti then fix_multi()
			--if cleanBitmaps then clean_bitmaps new_path
			--if setMaterial then set_object_material_name()
			--if swapMaterial then swap_material()
			--if addBump then add_bump "normal"
			--undo on
	)

		createdialog polyform_meshinator_form 300 400

		--addsubrollout polyform_meshinator_form.PolyLMParent PolyExportOptions rolledup:false

		--polyform_meshinator_form.PolyLMParent.height = 512
