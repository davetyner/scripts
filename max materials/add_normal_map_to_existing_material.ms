clearlistener()
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
		bitmap_extension = getFilenameType b
		bm_filename = (bitmap_path) + (getfilenamefile b) + "_nrm." + bitmap_extension
		bm.filename = bm_filename
		--n.bump_map = bm
		m.bumpmap=bm
		--update
	) else if what == "diffuse" then (
		bitmap_path = getfilenamepath b
		bm_filename = bitmap_path + (getfilenamefile b) + "." + bitmap_extension
		m.diffusemap.filename = bm_filename
		--o.material = m
	)
	) catch ( print "fail")
	--max select none
	)
)

fn doit = 
(
	--undo off
	add_bump "normal"
	--undo on
)

doit()
