@tool
extends MeshInstance3D

@export var cube_size: float = 1.0
var cube_mesh: ArrayMesh

@export var width: int = 16
@export var height: int = 16
@export var depth: int = 16

@export var noise: FastNoiseLite
@export var noise_seed: int = 12345
@export var cut_off: float = 0.5

var offset: Vector3i = Vector3i.ZERO

var voxels = []
var uvs = [0, 0, 0, 0, 0, 0]

func _ready() -> void:
	noise.seed = noise_seed
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.05
		
	voxels = generate_voxels()
	generate_mesh(voxels)

func generate_mesh(_voxels):
	var _faces = []
	
	for x in range(_voxels.size()):
		for y in range(_voxels[x].size()):
			for z in range(_voxels[x][y].size()):
				if _voxels[x][y][z] != 0:
					var _position = Vector3(x, y, z) * cube_size
					
					if x == 0 or voxels[x-1][y][z] == 0:
						_faces.append(create_face(Vector3.LEFT, _position, uvs))
						
					if x == voxels.size() -1 or voxels[x + 1][y][z] == 0:
						_faces.append(create_face(Vector3.RIGHT, _position, uvs))
						
					if y == 0 or voxels[x][y - 1][z] == 0:
						_faces.append(create_face(Vector3.DOWN, _position, uvs))
					
					if y == voxels[x].size() -1 or voxels[x][y + 1][z] == 0:
						_faces.append(create_face(Vector3.UP, _position, uvs))
					
					if z == 0 or voxels[x][y][z - 1] == 0:
						_faces.append(create_face(Vector3.FORWARD, _position, uvs))
						
					if z == voxels[x][y].size() - 1 or voxels[x][y][z + 1] == 0:
						_faces.append(create_face(Vector3.BACK, _position, uvs))
	
	var _vertices = []
	var _normals = []
	var _uvs = []
	
	for face in _faces:
		_vertices += face["vertices"]
		_normals += face["normals"]
		_uvs += face["uvs"]
	
	var _vertex_array = PackedVector3Array(_vertices)
	var _normal_array = PackedVector3Array(_normals)
	var _uv_array = PackedVector2Array(_uvs)
	
	var _arrays = []
	_arrays.resize(Mesh.ARRAY_MAX)
	_arrays[Mesh.ARRAY_VERTEX] = _vertex_array
	_arrays[Mesh.ARRAY_NORMAL] = _normal_array
	_arrays[Mesh.ARRAY_TEX_UV] = _uv_array
	
	cube_mesh = ArrayMesh.new()
	cube_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, _arrays)
	
	self.mesh = cube_mesh

func generate_voxels() -> Array:
	var _array = []
	_array.resize(width)
	
	for x in width:
		_array[x] = []
		_array[x].resize(height)
		
		for y in height:
			_array[x][y] = []
			_array[x][y].resize(depth)
	
	var cx = width / 2
	var cz = depth / 2
	var R = cx  # raio do hexágono em células
	
	for x in width:
		for z in depth:
			var wx = x + offset.x * width
			var wz = z + offset.z * depth
			var height_val = int(noise.get_noise_2d(wx, wz) * (height/2) + height/2)
			
			# coordenadas axiais (ou cube) para hex
			var q = x - cx
			var r = z - cz
			var s = -q - r
			
			for y in height:
				# só gerar voxels dentro do hexágono e abaixo do ruído
				if abs(q) <= R and abs(r) <= R and abs(s) <= R and y <= height_val:
					_array[x][y][z] = 1
				else:
					_array[x][y][z] = 0
	
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
