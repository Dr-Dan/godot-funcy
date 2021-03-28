
const Operators = preload("Operators.gd")
const Op = Operators.OperatorBase
			
# ==============================================================================
		
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
		return HeapSort.heap_sort(Operators.Util.get_filter_op(op), data)

class Reduce:
	extends Op
	
	var op
	
	func _init(op_):
		op = op_

	func eval(data):
		assert(data.size() > 1)
		var result = op.eval2(data[0], data[1])
		for i in range(2, data.size()-1):
			result = op.eval2(result, data[i+1])
		return result
