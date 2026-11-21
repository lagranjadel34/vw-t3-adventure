class_name VanMesh
## Carga el modelo low-poly exportado por tools/sprites/export_mesh3d.py (triángulos con color)
## y lo convierte en una malla con sombreado plano.

static func load_van(path: String) -> MeshInstance3D:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for t in data.tris:
		var c := Color(t.c[0], t.c[1], t.c[2])
		var v: Array[Vector3] = []
		for p in t.v:
			v.append(Vector3(p[0], p[1], p[2]))
		var n := Vector3(t.n[0], t.n[1], t.n[2])
		for i in 3:
			st.set_color(c)
			st.set_normal(n)
			st.add_vertex(v[i])
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.vertex_color_is_srgb = true
	mat.roughness = 0.9
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	return mi


## Modelo con curvas de tools/sprites/t3_sdf.py: float32, 9 valores por vértice
## (posición, normal, color), tres vértices por triángulo.
static func load_van_bin(path: String) -> MeshInstance3D:
	var f := FileAccess.get_file_as_bytes(path).to_float32_array()
	var n := f.size() / 9
	var pos := PackedVector3Array()
	var nor := PackedVector3Array()
	var col := PackedColorArray()
	pos.resize(n)
	nor.resize(n)
	col.resize(n)
	for i in n:
		var k := i * 9
		pos[i] = Vector3(f[k], f[k + 1], f[k + 2])
		nor[i] = Vector3(f[k + 3], f[k + 4], f[k + 5])
		col[i] = Color(f[k + 6], f[k + 7], f[k + 8])
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = pos
	arr[Mesh.ARRAY_NORMAL] = nor
	arr[Mesh.ARRAY_COLOR] = col
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.vertex_color_is_srgb = true
	mat.roughness = 0.75
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	return mi


## Carga el modelo con curvas si existe; si no, el de polígonos planos.
static func load_best(bin_path: String, json_path: String) -> MeshInstance3D:
	if FileAccess.file_exists(bin_path):
		return load_van_bin(bin_path)
	return load_van(json_path)
