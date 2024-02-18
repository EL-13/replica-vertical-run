extends Node2D


signal collect_coin


func _ready():
	var coins = get_tree().get_nodes_in_group("Coins")
	for i in coins:
		i.collect.connect(connect_coin_signal)

func connect_coin_signal():
	collect_coin.emit()
