/*
%YAML 1.1
%TAG !u! tag:unity3d.com,2011:
--- !u!21 &2100000
Material:
  serializedVersion: 6
  m_ObjectHideFlags: 0
  m_PrefabParentObject: {fileID: 0}
  m_PrefabInternal: {fileID: 0}
  m_Name: squarebricks
  m_Shader: {fileID: 46, guid: 0000000000000000f000000000000000, type: 0}
  m_ShaderKeywords: 
  m_LightmapFlags: 4
  m_EnableInstancingVariants: 0
  m_DoubleSidedGI: 0
  m_CustomRenderQueue: -1
  stringTagMap: {}
  disabledShaderPasses: []
  */
clearlistener()

fn get_material_header filename = (
material_header = "%YAML 1.1
%TAG !u! tag:unity3d.com,2011:
--- !u!21 &2100000
Material:
  serializedVersion: 6
  m_ObjectHideFlags: 0
  m_PrefabParentObject: {fileID: 0}
  m_PrefabInternal: {fileID: 0}
  m_Name: " + filename + "
  m_Shader: {fileID: 46, guid: 0000000000000000f000000000000000, type: 0}
  m_ShaderKeywords: 
  m_LightmapFlags: 4
  m_EnableInstancingVariants: 0
  m_DoubleSidedGI: 0
  m_CustomRenderQueue: -1
  stringTagMap: {}
  disabledShaderPasses: []
  m_SavedProperties:
    serializedVersion: 3"
	
	return material_header
)

fn get_string_type file_type = (
	
	--what kind of img is this? 
	case file_type of
	(
		"nrm": type = "normal"
		"spec": type = "specular"
		"metallic": type = "metallic"
		"opacity": type = "opacity"
		default: type = "diffuse"
	)		
	return type
)

fn get_texture_ids = 
(
	local dir = getfiles @"F:\Unity projects\Character Mocap Study\Assets\iwx_terrain\*.jpg.meta"
	local arr = #()
	texture_id_dic = Dictionary #string

	--d["05_000"] = #(#("diffuse","id"),#("normal","id"))
	for file in dir do (
		local filename, _filename, guid, theFile, n, file_type, type, file_id, has_id
		file_id = ""
		--get the file name without extension - by default Max is using the last "." so we'll have to split it to get the right filename
		_filename = filterstring (getfilenamefile file) "."
		filename = filterstring _filename[1] "_"
		
		--get the count
		count = filename.count
		
		--iterate through results of split
		case of
		(
			(count == 1):
			(
				--set the file's id
				file_id = filename[1]
				type = "diffuse"
			) 
			(count > 1):
			(
				--check if we have a match on the file type
				type = get_string_type filename[count]
				
				--construct the file name minus the last _* value - this will be the same as filename and will most likely be removed
				for a = 1 to count do 
				(
					--construct the infraworks 05_00_123456... filename - I don't love this way
					if type != "diffuse" then 
					(
						if a == 1 then file_id = file_id + filename[a]
						else if a <= count-1 then file_id = file_id + "_" + filename[a]
					) else (
						if a == 1 then file_id = file_id + filename[a]
						else file_id = file_id + "_" + filename[a]
					)
				)	
			)
		)
		
		--does this exist in the texture_id Dictionary yet?
		has_id = HasDictValue texture_id_dic file_id
		
		--add to Dictionary if false - if true, no probs
		if has_id == false then 
		( 
			--add this file_id to the main Dictionary
			PutDictValue texture_id_dic file_id (Dictionary #string)	
		)
		
		try
		(			
			--reset the guid value
			guid = ""
			--open the file
			theFile = openFile file --open the file
			--set our incrementer
			n=1
			
			--iterate through the file to get the GUID
			while not eof theFile do 
			(
				local theline,guid,type
				--read the next line
				theline = readLine theFile
				if n == 2 then (
						
						--set the guid value
						guid = (filterstring theline ": ")[2]
						
						--does the primary Dictionary's key already contain this image type?
						if HasDictValue (GetDictValue texture_id_dic file_id) type == false then
						(
							--add it
							PutDictValue (GetDictValue texture_id_dic file_id) type guid
						)
						--if so, add to it's array
						--if not, create it
					)
					--append arr #((getfilenamefile file),guid)
				n+=1
			)
			close theFile
		) catch (
			if theFile != undefined then close theFile
				throw()
		)
	)
	return texture_id_dic
)

fn write_material_properties filename texture_ids = 
(
	material_properties = #(#())
	local standard_material_parent_property_names = #("m_TexEnvs","m_Floats","m_Colors")
	local standard_material_texenvs_property_name_prefix = "- _"
	local standard_material_texenvs_property_name_suffix = ":\n"
	local standard_material_texenvs_property_names = #("BumpMap","DetailAlbedoMap","DetailMask","DetailNormalMap","EmissionMap","MainTex","MetallicGlossMap","OcclusionMap","ParallaxMap")
	local standard_material_texenvs_property_subnames = #("m_Texture", "m_Scale", "m_Offset")
	local standard_material_texenvs_property_subname_values = #("{fileID: 0}","{x: 1, y: -1}","{x: 0, y: 0}")

	local standard_material_m_floats_property_names = #("BumpScale","Cutoff","DetailNormalMapScale","DstBlend","GlossMapScale","Glossiness","GlossyReflections","Metallic","Mode","OcclusionStrength","Parallax","SmoothnessTextureChannel","SpecularHighlights","SrcBlend","UVSec","ZWrite")
	local standard_material_m_floats_property_values = #(1,0.5,1,0,1,0,1,0,0,1,0.02,0,1,1,0,1)
		
	local standard_material_m_color_property_names = #("Color","EmissionColor")
	local standard_material_m_color_property_values = #("{r: 1, g: 1, b: 1, a: 1}","{r: 0, g: 0, b: 0, a: 0}")
		
	--does our Dictionary contain this object
	key_exists = HasDictValue texture_ids filename
		
	-- if it does, get the ids
	if key_exists == true then 
	(
		diff = GetDictValue (GetDictValue texture_ids filename) "diffuse"
		norm = GetDictValue (GetDictValue texture_ids filename) "normal"
		spec = GetDictValue (GetDictValue texture_ids filename) "specular"
		metallic = GetDictValue (GetDictValue texture_ids filename) "metallic"
		opacity = GetDictValue (GetDictValue texture_ids filename) "opacity"
	)
	
	--set the destination directory
	dir = @"F:\Unity projects\Character Mocap Study\Assets\iwx_terrain\"
		
	mat = get_material_header(filename) + "\n"
	--for a in standard_material_parent_property_names do (
	mat = mat + "    "  + standard_material_parent_property_names[1] + ":\n"
		
		for b in standard_material_texenvs_property_names do (
			mat = mat + "    " + standard_material_texenvs_property_name_prefix + b + standard_material_texenvs_property_name_suffix
			local key = b

			for c = 1 to standard_material_texenvs_property_subnames.count do (
				local key_val = standard_material_texenvs_property_subnames[c]
				val = undefined
				if c == 1 then (
					case key of 
					(
						--{fileID: 2800000, guid: fab17313fa5ccf64cbe845c1a0f4e99f, type: 3}
						"MainTex": 
						(
							if diff != undefined then val = "{fileID: 2800000, guid: " + diff + ", type: 3}"
						)
						"BumpMap": 
						(
							if norm != undefined then val = "{fileID: 2800000, guid: " + norm + ", type: 3}"
						)
						default:val = undefined
					)
				)
				
				if val == undefined then val = standard_material_texenvs_property_subname_values[c]
				--format "%\n" val
				mat = mat + "        " + key_val + ": " + val + "\n"
			)
		)
		
		mat = mat + "    "  + standard_material_parent_property_names[2] + ":\n"
		for b = 1 to standard_material_m_floats_property_names.count do (
			key = standard_material_m_floats_property_names[b]
			val = standard_material_m_floats_property_values[b]
			mat = mat + "        " + standard_material_texenvs_property_name_prefix + key + ": " + (val as string) + "\n"
		)
		
		mat = mat + "    " + standard_material_parent_property_names[3] + ":\n"
		for b = 1 to standard_material_m_color_property_names.count do (
			key = standard_material_m_color_property_names[b]
			val = standard_material_m_color_property_values[b]
			mat = mat + "        " + standard_material_texenvs_property_name_prefix + key + ": " + (val as string) + "\n"
		)

	try(	
		if f != undefined then close f		
		f = createFile (dir + filename + ".mat")
		format "%\n" (mat as string) to:f
		close f
	) catch (
		format "%\n" "error writing material"
		format "%\t%\n" dir filename
		if f!=undefined then close f
		if file != undefined then close file
		format "%\n" (getCurrentException())
			throw()
	)
)

clearlistener()
(
	texture_ids = get_texture_ids()
	for o in selection do (
		filename = o.name
		write_material_properties filename texture_ids
	)
)