class_name RealtimeHurtbox
extends Area2D

var receiver: Node

func receive_realtime_hit(damage: int, source_position: Vector2) -> void:
	if receiver != null and receiver.has_method("receive_realtime_hit"):
		receiver.call("receive_realtime_hit", damage, source_position)
