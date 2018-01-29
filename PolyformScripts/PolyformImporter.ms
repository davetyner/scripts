--for installation instructions, please visit www.davetyner.com
--Use this script at your own risk.

macroScript Polyform_Importer category: "PolyFormTools"
(
	Rollout ImportExport "Import/Export"
(
	group "Directory and files"
		(
			edittext txt_dir "Directory" align:#left across:2 width:225
			button btn_browse "..." align:#right width:20 
			edittext txt_pre "Prefix:" text:"" tooltip:"Put your file prefix here" align:#left width:105 across:2
			button btnUpdate "Update" enabled:false
			edittext txt_ext "Extension" text:"dwg" align:#left width:105
			--edittext txt_suf "Sufffix: *" text:"" tooltip:"Put your suffix here" align:#left width:105
			label lblNumFiles "No files selected"
		)
	group "Import Options"
		(
			checkbox chkFLM "Link File"
			checkbox chkIMP "Import" checked:true	
			checkbox chkCreateMaxFile "Save import as .Max file" across:2
			checkbox chkMergeXrefs "Merge Xrefs" enabled:false align:#right
			checkbox chk_prefixmodelname "File Name Prefix" tooltip:"This will prefix each object with the file that it came from" align:#left --offset:[-45,0]
			checkbox chkSmooth "Smooth Modifier" across:2 enabled:false
			edittext txt_NoSmoothType text:"beam,stair,steel" width:75 tooltip:"Do not apply smooth modifier to files with this prefix"
			checkbox chk_unparent "Unparent Objects" align:#left checked:true
			label lbl_status "Ready"
		)
		
		group "Do it!"
		(
			button btn_Import "GO" width:75 height:40
		)
		
		on chkFLM changed state do
		(
			chkIMP.checked = false
		)
		
		on chkCreateMaxFile changed state do
		(
			if not chkMergeXrefs.enabled then chkMergeXrefs.enabled = true else chkMergeXrefs.enabled = false
			--if chkMergeXrefs.enabled == false then chkMergeXrefs.enabled = true else chkMergeXrefs.enabled = false
		)
		
		on chkIMP changed state do
		(
			chkFLM.checked = false
		)
		
		on chk_prefixmodelname changed state do
		(
			if not chkSmooth.enabled then chkSmooth.enabled = true else chkSmooth.enabled = false
		)
		
		on btn_browse pressed do
		(
			local fpath = getSavePath initialDir:@"F:\Projects\Autodesk\Technical Conference\dataset" caption:"Select any file in the source directory:" 
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
					global importDrawingPath = fpath + "\\" + pfix + "." + extension 
					txt_dir.text = fpath
				)
			)
			btnUpdate.enabled = true
		)
		
		on btnUpdate pressed do
		(
			local pfix = if txt_pre.text == "" then pfix = "*" else pfix = txt_pre.text 
				format "%\n" pfix
			local thepath = (getfilenamepath importDrawingPath) +  pfix + "." + txt_ext.text
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

	
			fn importObjects filename nsmooth sm=
						(
										local impobjs = for o in objects where o.isfrozen == false collect o
										--for obj in impobjs where classof obj == Editable_mesh do obj.name = (substring obj.name (6+1) obj.name.count)
										for obj in impobjs do obj.name = (substring obj.name (6+1) obj.name.count)
										--for obj in impobjs where classof obj == Editable_mesh  do obj.name = (filename + "_" + obj.name)
										for obj in impobjs do obj.name = (filename + "_" + obj.name)
										local smootharr = #()
										if chkSmooth.checked == true then 
											(
														 --copy of all objects
												
														for ns = 1 to nsmooth.count do
														(	
															local cfilter = "*" + nsmooth[ns] + "*" -- ("*" + nsmooth[ns] + "*")
																	for imp = impobjs.count to 1 by -1 where matchpattern impobjs[imp].name pattern:cfilter == true do
																	(
																			deleteitem impobjs imp
																	)
														)
														
														if impobjs.count > 0 then for i = 1 to impobjs.count where impobjs[i].modifiers.count == 0 do addmodifier impobjs sm
											)
											
											local impobjs = for o in objects where o.isfrozen == false do freeze o
						)
			

						fn unparent =
							
						(
														startobjects = objects.count
														thedel=#()
														for o in geometry do (
														o.controller=prs()
														if classof o.parent == LinkComposite then
														(
															o.parent = undefined
														) else ( 
															o.parent = undefined
														)
														)
															for sp in objects where classof sp == splineshape do append thedel sp
															for o in geometry where classof o == LinkComposite do converttomesh o --append thedel o
															for o in geometry where classof o == LinkComposite do append thedel o
															for o in objects where classof o == NURBSCurveshape do append thedel o

															local count = thedel.count
															delete thedel
															count
						)
						
						
			local startimp=timestamp()
			local theobj = #()
			local thedwg = #()
			local s = smooth()
			local noSmooth = filterstring txt_NoSmoothType.text ","
			s.autosmooth=true
			clearlistener()	
			disablesceneredraw()
			local exportfilelog = txt_dir.text + "\\importlog.txt"
			local importFileList = txt_dir.text + "\\importFileList.txt"
			if doesFileExist exportfilelog == false then
				( 
					cf = createFile exportfilelog
					close cf
				)
						--importDrawingPath = "C:\\Users\\dave\\Downloads\\test\\test\\"
						for f in getfiles (importDrawingPath) do append thedwg f
						for tf = 1 to thedwg.count do
									(
										local logarr = #()
										local mfn = getfilenamefile thedwg[tf]
										local startIntTime = timestamp()
												local filename = filenameFromPath thedwg[tf]
												if chkFLM.checked then
												(
													
													filelinkmgr.attach thedwg[tf]
													
												) else (
															if chkCreateMaxFile.checked == true then
															(
																					resetmaxfile #noprompt
																					savefile = txt_dir.text + "\\" + mfn + ".max" --@"C:\Dropbox\projects\iso15926\Plant3D Sample\exported acad file\" + mfn + ".max"
																					if tf != 1 then importFile thedwg[tf] #noprompt else importFile thedwg[tf]
																					
																					
																					append logarr #("File saved successfully: ", savefile)
															)	else (												
																					if tf != 1 then importFile thedwg[tf] #noprompt else importFile thedwg[tf]
																					append logarr #("File imported successfully: ", thedwg[tf])
															)
												)
												
												
										if chk_unparent.checked == true then
													(
														local thecount = unparent()
														lbl_Status.text = "Deleted " + thecount as string + " objects"
													)		
										if chk_prefixmodelname.checked == true then local impobjs = importObjects mfn nosmooth	s					
										if chkCreateMaxFile.checked == true then savemaxfile savefile
													
										local finIntTime = timestamp()

										local intTotal = ((finIntTime-startIntTime)/1000) as float
										append logarr #("File Import Time: ", intTotal)
										writetolog txt_dir.text logarr exportfilelog
										format "imported % in %\n" filename intTotal
									)
									
		local tend=timestamp()
		local mbool = false
		local intTotal = ((tend-startimp)/1000) as float
		if chkMergeXrefs.checked == true then mbool = true
		if chkCreateMaxFile.checked == true then xrefobjs txt_dir.text mbool
		format "imported % files in %\n seconds" thedwg.count intTotal 
		lbl_Status.text = "Imported " + thedwg.count as string + " files in " + intTotal as string + " seconds"

													
													
							
		enablesceneredraw()									
		
		)
)
TheImportTools=newrolloutfloater "PolyForm Tools Importer" 300 415
addrollout ImportExport TheImportTools  rolledUp:false
)
