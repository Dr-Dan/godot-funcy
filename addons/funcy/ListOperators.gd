
const Operators = preload("Operators.gd")
const Op = Operators.OperatorBase
			
# ==============================================================================
		
class Defer:
	extends Op
	var op
	var data
	
	func _init(op_, data_):
		op = op_
		data = data_
		
	func eval(data):
		return op.eval(self.data)
				
class Filter:
	extends Op
	var op
	
	func _init(op_):
		op = op_
		
	func eval(data):
		var result = []
		for d in data:
			if op.eval(d):
				result.append(d)
		return result
		
class Map:
	extends Op
	var op
	
	func _init(op_):
		op = op_
		
	func eval(data):
		var result = []
		for d in data:
			result.append(op.eval(d))
		return result
	
class TakeWhile:
	extends Op
	var op
	
	func _init(op_):
		op = op_
		
	func eval(data):
		# faster to count end point and slice data?
		var result = []
		for d in data:
			if not op.eval(d): break
			result.append(d)
		return result
			
class Slice:
	extends Op
	var start:int
	var end:int

	func _init(start_, end_=-1):
		start = start_
		end = end_
		
	func eval(data):
		return data.slice(start,end)
		
class Sort:
	extends Op
	const HeapSort = preload("heap_sort.gd")
	var op
	
	func _init(op_):
		op = op_

	func eval(data):
		return HeapSort.heap_sort(op, data)

class Reduce:
	extends Op
	
	var op
	
	func _init(op_):
		op = op_

	func eval(data):
#		assert(data.size() > 1)
		if data.size() < 2:
			assert(not data.empty())
			return data[0]
		var result = op.eval2(data[0], data[1])
		for i in range(2, data.size()-1):
			result = op.eval2(result, data[i+1])
		return result

# ------------------------------------------------------------------------------

class Zip:
	extends Op

	func eval(data):
		assert(data.size() == 2)
		var result = []
		for i in data[0].size():
			result.append([data[0][i], data[1][i]])
		return result
		
class ZipOp:
	extends Op
	
	var op
	
	func _init(op_):
		op = op_

	func eval(data):
		assert(data.size() == 2)
		var result = []
		for i in data[0].size():
			result.append(op.eval2(data[0][i], data[1][i]))
		return result
				
class Insert:
	extends Op
	var items
	func _init(items_):
		if not items_ is Array:
			items_ = [items_]
		items = items_
		
	func eval(data):
		var result = [] + data
		for d in items:
			result.append(d)
		return result

class Invert:
	extends Op
	
	func eval(data):
		var result = [] + data
		result.invert()
		return result

class Pop:
	extends Op
	func eval(data):
		var result = [] + data
		result.pop_back()
		return result

class Remove:
	extends Op
	var n
	func _init(n_:int):
		n = n_
		
	func eval(data):
		assert(n < data.size())
		var result = [] + data
		result.remove(n)
		return result
					
