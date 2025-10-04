@tool
extends Node3D

@export var chunk_scene: PackedScene
@export var world_size: Vector3i = Vector3i(4, 1, 4) 
@export var chunk_size: int = 16
@export var noise_seed: int = 0
@export var noise: FastNoiseLite
@export var cube_size: float = 2

func _ready():
	generate_terrain()

func generate_terrain():
	var center = Vector3(world_size.x * chunk_size / 2.0, 0, world_size.z * chunk_size / 2.0)
	var radius = min(world_size.x * chunk_size, world_size.z * chunk_size) / 2.0
	
	for x in world_size.x:
		for y in world_size.y:
			for z in world_size.z:
				var chunk = chunk_scene.instantiate()
				
				chunk.noise_seed = noise_seed
				chunk.noise = noise
				chunk.cube_size = cube_size
				chunk.offset = Vector3i(x, y, z)
				chunk.width = chunk_size
				chunk.height = chunk_size
				chunk.depth = chunk_size
				chunk.position = Vector3(x, y, z) * chunk_size * cube_size
				
				chunk.center_world = center
				chunk.radius_world = radius
				
				add_child(chunk)
