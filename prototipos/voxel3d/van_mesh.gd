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
