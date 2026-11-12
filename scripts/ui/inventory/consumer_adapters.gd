extends RefCounted
# Production already deposits output in warehouse: bind that same container and
# filter product definitions. No spawn or duplicate item ledger occurs here.
static func production(panel: InventoryPanel, products: Array) -> void:
	panel.bind_external_container("warehouse",func(): return panel.at_base,func(item: Dictionary): return item.definition_id in products)
	panel.open_panel()
static func strengthening(panel: InventoryPanel, callback: Callable, at_base: bool) -> void:
	panel.open_selector(func(item: Dictionary):
		return panel.inventory.definitions[item.definition_id].category in ["ranged","melee","armor","backpack","plugin"],callback,at_base)
