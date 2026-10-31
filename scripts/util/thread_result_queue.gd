class_name ThreadResultQueue
extends RefCounted

var _mutex: Mutex = Mutex.new()
var _results: Array[Variant] = []

func push_result(result: Variant) -> void:
	_mutex.lock()
	_results.append(result)
	_mutex.unlock()

func pop_all() -> Array[Variant]:
	_mutex.lock()
	var batch: Array[Variant] = _results.duplicate()
	_results.clear()
	_mutex.unlock()
	return batch

func size() -> int:
	_mutex.lock()
	var result_count: int = _results.size()
	_mutex.unlock()
	return result_count
