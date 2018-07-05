/*

A script by Dave Tyner
January 2018

--july 2018: added select invert function -DaveT
*/

fn megaClusterAttach objs =
(
	gc()
	local ts = timestamp()
	with undo off with redraw off
	(
		local att = meshop.Attach
		local snap = snapShotAsMesh
		local del = deleteItem
		local j = 1
		local meshes = for o in objs collect snap o
		while meshes.count > 1 do
		(
			
			att meshes[j] meshes[j+1]
			del meshes (j+1)
			j += 1
			if (j + 1) > meshes.count then j = 1
		)
		delete objs
		local result = editable_mesh name:"Result"
		result.mesh = meshes[1]
		--print (timeStamp()-ts)
	)
	return result
)

function clusterAttach objArr =
  	(
  		
  		local j = 1
  		local count = objArr.count
  			
  		undo off
  		(
  			while objArr.count > 1 do
  			(				
  				if classof objArr[j] != Editable_Poly then converttopoly objArr[j]
  					
  				polyop.attach objArr[j] objArr[j+1]
  				deleteItem objArr (j+1)
  					
  				j += 1
  					
  				if (j + 1) > objArr.count then j = 1
  				
  			)
  		)
  		return objArr[1]
  	)
	
fn check_mat_arr arr mname = (
	for m = 1 to arr.count do
	(
		if arr[m][1] == mname then return arr[m][2]
	)
	return false
)

fn consolidate_mats =(
	local arr = #()
	for a in geometry where a.material != undefined do (
		if (classof a.material == Multimaterial) then
		(
			hasmat = false
			for b = 1 to a.material.numsubs do
			(
				hasmat = check_mat_arr arr a.material.materialList[b].name
				--format "%\t%\n" hasmat a.material.materialList[b].name
				if hasmat == false then append arr #(a.material.materialList[b].name, a.material.materialList[b])
			)
		) else (
				hasmat = check_mat_arr arr a.material.name
				--format "%\t%\n" hasmat a.material.materialList[b].name
				if hasmat == false then append arr #(a.material.name, a.material)
		)
	)
	
	
	for a in geometry where a.material != undefined do (
		if (classof a.material == Multimaterial) then
		(
			hasmat = false
			for b = 1 to a.material.numsubs do
			(
				mat = check_mat_arr arr a.material.materialList[b].name
				a.material.materialList[b] = mat
				--format "%\t%\n" hasmat a.material.materialList[b].name
			)
		) else (
			mat = check_mat_arr arr a.material.name
			a.material = mat
		)
	)
	return arr
)

fn add_to_layer str objs = (
	local layno = 0
	for l = 1 to layermanager.count-1 do
	(

		lay = (layermanager.getLayer l).name
		--format "%\n" lay
		if lay == str then layno = layermanager.getLayer l
	)
	if layno == 0 or layno == undefined then layno = layermanager.newlayerfromname (substitutestring str " " "_")

	for o in objs do layno.addnode o
)

fn clean_file_name_mat theName = (
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



fn collect_data search_key search_val hidden = (
	local arr = #()
	if hidden == true then objs = for o in geometry collect o
	else objs = for o in geometry where o.ishidden == false collect o
	for o in objs do (
		str = (getUserPropBuffer o)
		theprops = filterstring str "=\n"
		search_key = tolower(clean_file_name_mat search_key)
		search_val = tolower(clean_file_name_mat search_val)
		for p = 3 to theprops.count by 2 do (
				key = trimright theprops[p]
				key = trimleft key
				key= clean_file_name_mat key
				val = trimright theprops[p+1]
				val = trimleft val
				val= clean_file_name_mat val

				if tolower(key) == tolower(search_key) and tolower(search_val) == tolower(val) then (
					--format "%\t" key
					--format "%\n" val
					appendifunique arr o
				)
			--format "%\n" key
		)
	)
	return arr
)


fn collect_unique_property_values search_keys hidden = (
	local arr = #()
	local objarr = #()
	if hidden == true then objs = for o in geometry collect o
	else objs = for o in geometry where o.ishidden == false collect o
		
	--format "search_key.count: %\n" search_keys.count
	for i = 1 to objs.count do (
		
		o = objs[i]
		str = (getUserPropBuffer o)
		local my_keys, my_val_str
		
		theprops = filterstring str "=\n"
		if search_keys.count>1 then (
			keystr = ""
			for mykey in search_key do (
				
				mykey = tolower(clean_file_name_mat mykey)
				
				next_obj = false
				for p = 3 to theprops.count by 2 do (
					if next_obj == false then (
						key = trimright theprops[p]
						key = trimleft key
						key= tolower(clean_file_name_mat key)

						val = trimright theprops[p+1]
						val = trimleft val
						val = tolower(clean_file_name_mat val)
						
						if key == mykey then (
							my_val_str += val
						)
					--format "key: %\tval: %\tsearch_key: %\n" key val search_key
					--format "%\n" val
					)
				)
			)
			if my_keys == true then (
				appendifunique arr val
				next_obj = true
			)
			
		) else (
			search_key = tolower(clean_file_name_mat search_keys[1])
			
			next_obj = false
			for p = 3 to theprops.count by 2 do (
				if next_obj == false then (
					key = trimright theprops[p]
					key = trimleft key
					key= tolower(clean_file_name_mat key)
					val = trimright theprops[p+1]
					val = trimleft val
					val = tolower(clean_file_name_mat val)
				--format "key: %\tval: %\tsearch_key: %\n" key val search_key
				--format "%\n" val
					if key == search_key then (
						--format "key: %\tval: %\tsearch_key: %\n" key val search_key
						--format "key: %\tval: %\n" key val
						appendifunique arr val
						next_obj = true
					)
				)
			)
		)
			--format "%\n" key
	)
	return arr
)

function select_bbox obj selected = (
	local arr,bbo,myobj,dec,ar,bb,n,objs
	arr=#()
	bbo = obj.min-obj.max
	for x = 1 to 3 do bbo[x] = ceil(bbo[x])
	myobj = obj
	if selected == true then (
		objs = for o in geometry where o.ishidden == false collect o
	) else (
		objs = for o in geometry collect o
	)
	for i = 1 to objs.count do (
		o = objs[i]
		ar = 0
		--if o.numfaces > 8 then ar = polyop.getfacearea o 9
		--if ar == myarea then append arr o
		bbhigh = [0,0,0]
		bblow = [0,0,0]
		bb = o.min-o.max
		n=0
		tol = .2
		isokay = true
		for x = 1 to 3 do (
			bbhigh[x] = ceil(bb[x] + (ceil(bb[x])*tol)) -- ((dotNetClass "System.Math").round bb[x] dec) as float

			if bbhigh[x] > ceil(bbo[x]) then
			( 
				isokay = false
			) else isokay = true
			--format "% less %:%=%\n" o.name bbhigh[x] bb[x]  isokay
			--if isokay == false then continue
				
			bblow[x] = ceil(bb[x] - (ceil(bb[x])*tol)) -- ((dotNetClass "System.Math").round bb[x] dec) as float
				
			if bblow[x] < floor(bbo[x]) then
			( 
				isokay = false
			) else isokay = true
			--format "% more %:%=%\n" o.name bblow[x] bb[x] isokay
			if isokay == false then continue
		)
		if isokay == true then append arr o
	)
	return arr
)

try(destroyDialog polyform_selectby_form)catch()

	--try(destroyDialog polyform_selectby_form.PolyLMParent)catch() --try to destroy it if it already exists as a dialog
	rollout polyform_selectby_form "Polyform Selectinator"--define the rollout 
	(
		local dotcolor = dotnetclass "System.Drawing.Color"
		
		group "Hide Stuff"
		(
			checkbox chk_hide_lights "Hide Lights"
			checkbox chk_hide_cameras "Hide Cameras"
		)
		group "Select Stuff"
		(
			edittext txt_name "Object Name"
			checkbox chk_vis "only select visible" checked:true
			checkbox chk_invert "Invert the selection" tooltip:"This means that unselected objects will be affected"
			dotnetcontrol lb_0 "Label" text:"Apply to SELECTION" width:130 height:30 across:2
			button btn_select "Select Objects" height:50
			--button btn_material "Select by Material"
			--button btn_bbox "Select by Bounding Box"
		)
		
		group "Attach Selected Stuff"
		(
			button btn_attach "Attach Selected" height:50
		)
		
		group "Automatic Attachment of Stuff" (
			dropdownlist ddl_attach_by "Attach By:" items:#("Material","Family Name","Family and Type","Category Name","Type Name")
			checkbox chk_add_to_layer "Create Layers" checked:false
			button btn_go "GO" height:50 width:150
		)
		
		on chk_invert changed chk do (
			local dotcolor = dotnetclass "System.Drawing.Color"	
			if chk == true then (
				lb_0.text = "Apply to INVERSE"
				lb_0.Backcolor = dotcolor.Orange
			) else (
				lb_0.text = "Apply to Selection"
				lb_0.Backcolor = dotcolor.White
			)
			
		)
		
		on chk_hide_lights changed chk do (
			lights.ishidden = chk
		)
		
		on chk_hide_cameras changed chk do (
			cameras.ishidden = chk
		)
		
		on btn_select pressed do (
			max select none
			local nm = "*"+txt_name.text+"*"
			if chk_invert.checked == false then (
				select(for o in geometry where matchpattern o.name pattern:nm collect o)
			) else (
				select(for o in geometry where matchpattern o.name pattern:nm == false collect o)
			)
		)
		
		on btn_material pressed do (
			if chk_vis.checked == true then(
				select(for o in geometry where o.ishidden==false and o.material == undefined and o.material == selection[1].material collect o)
			) else (
				select(for o in geometry where o.material == undefined and o.material == selection[1].material collect o)
			)
		)
		
		on btn_attach pressed do (
			local objs
			objs = for o in selection collect o
			for o in objs do format "%\n" o.name
			ClusterAttach objs
		)
		
		on btn_bbox pressed do (
			local obj = selection[1]
			select(select_bbox obj chk_vis.checked )
		)
		
		on btn_go pressed do 
			(
				total_start_time = timestamp()
				clearlistener()
				if ddl_attach_by.text !="Material" then (
					start_time = timestamp()
					arr = #()
					search_key = #(ddl_attach_by.text)
					props = collect_unique_property_values search_key false
					format "collected unique properties in % seconds\n" ((timestamp()-start_time)/1000)
					
					for p in props do (
						start_time = timestamp()
						objs = collect_data search_key[1] p false
						format "collected % objects with property:% in % seconds\n" objs.count p ((timestamp()-start_time)/1000)
						--format "objs:%\n" objs
						if objs.count > 0 then (
							if chk_add_to_layer.checked == true then (
								add_to_layer (tolower(clean_file_name_mat p)) objs
							)
							start_time = timestamp()
							obj = clusterAttach objs
							format "attached % objects with property:% in % seconds\n" objs.count p ((timestamp()-start_time)/1000)
							obj.name = p
						)
					)
					
				) else (
					local matarr
					--matarr = consolidate_mats()
					local cnt = 0
					for mat in scenematerials do (
						objs = for o in geometry where o.material == mat collect o
						if objs.count>0 then (
							--format "%\t%\t%\n" mat objs objs.count
							cnt+=objs.count
							nm = objs[1].name
							new_obj = megaClusterAttach objs
							new_obj.name = nm --mat.name
							new_obj.material = mat
							--new_obj.ishidden = true
							if chk_add_to_layer.checked == true then (
								add_to_layer (tolower(clean_file_name_mat p)) objs
							)
						)
					)
				)
				
				format "Completed all tasks in % seconds, there are now % geometries\n"  ((timestamp()-total_start_time)/1000) geometry.count
				
			)
	)
	
	createdialog polyform_selectby_form 300 500