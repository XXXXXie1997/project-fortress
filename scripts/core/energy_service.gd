class_name EnergyService
extends RefCounted

# All stores use {energy: float, capacity: float}; callers retain ownership.
static func transfer(source: Dictionary, target: Dictionary, requested: float) -> float:
	if is_same(source, target) or not is_finite(requested) or requested <= 0.0:
		return 0.0
	if not valid_store(source) or not valid_store(target):
		return 0.0
	var amount: float = minf(requested, minf(source.energy, target.capacity - target.energy))
	source.energy -= amount
	target.energy += amount
	return amount

static func valid_store(store: Dictionary) -> bool:
	if not store.has_all(["energy", "capacity"]):
		return false
	if not (store.energy is float or store.energy is int) or not (store.capacity is float or store.capacity is int):
		return false
	return is_finite(store.energy) and is_finite(store.capacity) and store.energy >= 0.0 and store.capacity >= store.energy
