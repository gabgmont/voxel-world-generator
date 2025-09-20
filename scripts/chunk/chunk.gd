@tool
extends MeshInstance3D

@export var cube_size: float = 1.0

@export var width: int = 16
@export var height: int = 16
@export var depth: int = 16

@export var center_world: Vector3
@export var radius_world: float

@export var noise: FastNoiseLite
@export var noise_seed: int = 12345
@export var cut_off: float = 0.5

var offset: Vector3i = Vector3i.ZERO

var voxels = []
var uvs = [
	Vector2(0,0),  # canto inferior esquerdo
	Vector2(1,0),  # inferior direito
	Vector2(1,1),  # superior direito
	Vector2(0,1)   # superior esquerdo
]

func _ready() -> void:
	noise.seed = noise_seed
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.01
	
	voxels = generate_voxels()
	if (voxels.size() == 0):
		return
		
	generate_mesh(voxels)

func generate_mesh(_voxels):
	var _surfaces = {
		1: [], #grass
		2: [], #dirt
		3: [], #stone
	}
	
	for x in range(_voxels.size()):
		for y in range(_voxels[x].size()):
			for z in range(_voxels[x][y].size()):
				if _voxels[x][y][z] != 0:
					var _block_type = _voxels[x][y][z]
					if _block_type == 0:
						continue
						
					var _position = Vector3(x, y, z) * cube_size
					var _faces = []
					
					if x == 0 or _voxels[x-1][y][z] == 0:
						_faces.append(create_face(Vector3.LEFT, _position, uvs))
						
					if x == _voxels.size() -1 or _voxels[x + 1][y][z] == 0:
						_faces.append(create_face(Vector3.RIGHT, _position, uvs))
						
					if y == 0 or _voxels[x][y - 1][z] == 0:
						_faces.append(create_face(Vector3.DOWN, _position, uvs))
					
					if y == _voxels[x].size() -1 or _voxels[x][y + 1][z] == 0:
						_faces.append(create_face(Vector3.UP, _position, uvs))
					
					if z == 0 or _voxels[x][y][z - 1] == 0:
						_faces.append(create_face(Vector3.FORWARD, _position, uvs))
						
					if z == _voxels[x][y].size() - 1 or _voxels[x][y][z + 1] == 0:
						_faces.append(create_face(Vector3.BACK, _position, uvs))
					
					_surfaces[_block_type] += (_faces)
	
	var cube_mesh = ArrayMesh.new()
	
	for _block_type in _surfaces.keys():
		var _faces = _surfaces[_block_type]
		if _faces.size() == 0:
			continue

		var _vertices = []
		var _normals = []
		var _uvs = []

		for _face in _faces:
			_vertices += _face["vertices"]
			_normals += _face["normals"]
			_uvs += _face["uvs"]

		var _arrays = []
		_arrays.resize(Mesh.ARRAY_MAX)
		_arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array(_vertices)
		_arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array(_normals)
		_arrays[Mesh.ARRAY_TEX_UV] = PackedVector2Array(_uvs)

		cube_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, _arrays)

		var mat = StandardMaterial3D.new()
		match _block_type:
			1: mat.albedo_texture = load("res://textures/grass.png")
			2: mat.albedo_texture = load("res://textures/dirt.png")
			3: mat.albedo_texture = load("res://textures/stone.png")

		cube_mesh.surface_set_material(cube_mesh.get_surface_count()-1, mat)
	
	self.mesh = cube_mesh
	
	# --- adicionar colisão ---
	var static_body = StaticBody3D.new()
	add_child(static_body)

	var collision_shape = CollisionShape3D.new()
	static_body.add_child(collision_shape)

	var concave_shape = ConcavePolygonShape3D.new()
	concave_shape.data = cube_mesh.get_faces()
	collision_shape.shape = concave_shape

func generate_voxels() -> Array:
	var _array = []
	_array.resize(width)
		
	for x in width:
		_array[x] = []
		_array[x].resize(height)
		
		for y in height:
			_array[x][y] = []
			_array[x][y].resize(depth)
	
	for x in width:
		for z in depth:
			var wx = x + offset.x * width
			var wz = z + offset.z * depth
			var height_val = int(noise.get_noise_2d(wx, wz) * height/2 + height/2)
			
			for y in height:
				var global_pos = Vector3(
					offset.x * width + x,
					offset.y * height + y,
					offset.z * depth + z
				)
				
				var dx = global_pos.x - center_world.x
				var dz = global_pos.z - center_world.z
				var dist = sqrt(dx * dx + dz * dz)
				
				if y > height_val || dist > radius_world:
					_array[x][y][z] = 0
				else:
						if y == height_val:
							_array[x][y][z] = 1  # grass
						elif y >= height_val - 3:
							_array[x][y][z] = 2  # dirt
						else:
							_array[x][y][z] = 3  # stone
	
	return _array

func create_face(_direction: Vector3, _position: Vector3, _uv_coords: Array) -> Dictionary:
	var _vertices = []
	var _normals = []
	var _uvs = []
	
	_normals.resize(4)
	
	match _direction:
		Vector3.UP:
			_vertices = [
				_position + Vector3(-0.5,  0.5, -0.5) * cube_size,
				_position + Vector3( 0.5,  0.5, -0.5) * cube_size,
				_position + Vector3( 0.5,  0.5,  0.5) * cube_size,
				_position + Vector3(-0.5,  0.5,  0.5) * cube_size
			]
			_normals.fill(Vector3.UP)
			_uvs = _uv_coords
		Vector3.DOWN:
			_vertices = [
				_position + Vector3(-0.5, -0.5, 0.5) * cube_size,
				_position + Vector3(0.5, -0.5, 0.5) * cube_size,
				_position + Vector3(0.5, -0.5, -0.5) * cube_size,
				_position + Vector3(-0.5, -0.5, -0.5) * cube_size
			]
			_normals.fill(Vector3.DOWN)
			_uvs = _uv_coords
		Vector3.LEFT:
			_vertices = [
				_position + Vector3(-0.5, -0.5, -0.5) * cube_size,
				_position + Vector3(-0.5, 0.5, -0.5) * cube_size,
				_position + Vector3(-0.5, 0.5, 0.5) * cube_size,
				_position + Vector3(-0.5, -0.5, 0.5) * cube_size
			]
			_normals.fill(Vector3.LEFT)
			_uvs = _uv_coords
		Vector3.RIGHT:
			_vertices = [
				_position + Vector3(0.5, -0.5, 0.5) * cube_size,
				_position + Vector3(0.5, 0.5, 0.5) * cube_size,
				_position + Vector3(0.5, 0.5, -0.5) * cube_size,
				_position + Vector3(0.5, -0.5, -0.5) * cube_size
			]
			_normals.fill(Vector3.RIGHT)
			_uvs = _uv_coords
		Vector3.FORWARD:
			_vertices = [
				_position + Vector3(-0.5, -0.5, -0.5) * cube_size,
				_position + Vector3(0.5, -0.5, -0.5) * cube_size,
				_position + Vector3(0.5, 0.5, -0.5) * cube_size,
				_position + Vector3(-0.5, 0.5, -0.5) * cube_size
			]
			_normals.fill(Vector3.FORWARD)
			_uvs = _uv_coords
		Vector3.BACK:
			_vertices = [
				_position + Vector3(-0.5, 0.5, 0.5) * cube_size,
				_position + Vector3(0.5, 0.5, 0.5) * cube_size,
				_position + Vector3(0.5, -0.5, 0.5) * cube_size,
				_position + Vector3(-0.5,-0.5, 0.5) * cube_size
			]
			_normals.fill(Vector3.BACK)
			_uvs = _uv_coords
	
	return {
		"vertices": [
			_vertices[0], _vertices[1], _vertices[2],
			_vertices[0], _vertices[2], _vertices[3]
		],
		"normals": [
			_normals[0], _normals[1], _normals[2],
			_normals[0], _normals[2], _normals[3]
		],
		"uvs": [
			_uvs[0], _uvs[1], _uvs[2],
			_uvs[0], _uvs[2], _uvs[3]
		]
	}
