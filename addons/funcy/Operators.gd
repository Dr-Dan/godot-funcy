extends Resource
# the name that will be used to refer to the current
# 	object in an expression i.e. {dmg = 2} =>'_x.dmg * 4'
const EXPR_NAME = '_x'
const EXPR_NAME2 = '_y'

## =======================================================
## UTILS
class Util:
	static func get_op(input)\
	-> OperatorBase:
		if input is OperatorBase:
			return input
		elif input is FuncRef:
			return Func.new(input)		
		elif input is String:
			return ExprArgsDeep.new(input)
		return null

	static func get_map_op(input)\
		-> OperatorBase:
		var r = get_op(input)
		if r != null:
			return r
		elif input is Dictionary:
			return DictApplied.new(input)
		elif input is Array:
			return OperatorIterator.new(get_map_op_arr(input))
		return null

	static func get_filter_op(input)\
		-> OperatorBase:
		var r = get_op(input)
		if r != null:
			return r
		elif input is Dictionary:
			return DictCompareOpen.new(input)
		elif input is Array:
			return And.new(get_filter_op_arr(input))
		return null

	static func get_map_op_arr(items:Array) -> Array:
		for i in items.size():
			items[i] = get_map_op(items[i])
		return items

	static func get_filter_op_arr(items:Array) -> Array:
		for i in items.size():
			items[i] = get_filter_op(items[i])
		return items
		

# ==============================================================
	
class OperatorBase:

	# func auto_eval(item0, item1):
	# 	if item1 != null:
	# 		return eval2(item0, item1)
	# 	assert(item0 != null)
	# 	return eval(item0)
		
	func eval(item):
		return false

	func eval2(x_next, x_total):
		push_warning('using default eval2 in Operator')
		return eval(x_next)
	
class Identity:
	extends OperatorBase
	func eval(item):
		return item

class Value:
	extends OperatorBase
	var value
	func _init(value_):
		value = value_
		
	func eval(item):
		return value

class RunOp:
	extends OperatorBase
	
	var field:String
	var op:OperatorBase
	
	func _init(field_: String, op_:OperatorBase):
		field = field_
		op = op_
		
	func eval(item):
		return op.eval(item[field])
		
class RunIf:
	extends OperatorBase
	
	var _then:OperatorBase
	var _else:OperatorBase
	var _pred:OperatorBase
	
	func _init(pred_: OperatorBase, then_:OperatorBase, else_:OperatorBase):
		_pred = pred_
		_then = then_
		_else = else_
		
	func eval(item):
		if _pred.eval(item):
			return _then.eval(item)
		return _else.eval(item)
				
class OperatorIterator:
	extends OperatorBase

	var ops = []
	var exit_op: OperatorBase = null
	var is_pred:bool
	
	func _init(ops_:Array, exit_op_:OperatorBase=null, is_predicate_:bool=false):
		ops = ops_
		exit_op = exit_op_
		is_pred = is_predicate_

	func eval(item):
		for op in ops:
			item = op.eval(item)
			if exit_op != null:
				var e = exit_op.eval(item)
				if not e:
					if is_pred:
						item = e
					break
		return item

	# func eval2(x_next, x_total):
	# 	for op in ops:
	# 		x_total = op.eval2(x_next, x_total)
	# 		if exit_op != null:
	# 			var e = exit_op.eval(item)
	# 			if not e:
	# 				if is_pred:
	# 					item = e
	# 				break		
	# 	return item

# ==============================================================
# DICTIONARY OPERATORS;

"""
Compare a dictionary of values with those in an object
Any naked values (i.e. 'field0' below) will be wrapped with an Eq operator

usage:
	DictCompare.new(
		{field0=value, field1=ops.eq(value), field2=ops.gt(value)}
	)

"""
class DictCompare:
	extends OperatorBase
	var fields:Dictionary
	var any:bool
	var fail_missing:bool

	func _init(fields_: Dictionary, _any=false, _fail_missing=true):
		fields = fields_
		for p in fields:
			if not fields[p] is OperatorBase:
				fields[p] = Eq.new(fields[p])
		any = _any
		fail_missing = _fail_missing

	func eval(item):
		return item_valid(item, fields)

	func item_valid(item, comps: Dictionary)->bool:
		for key in comps:
			if key in item:
				if comps[key].eval(item[key]):
					if any:
						return true
				else:
					return false
			elif fail_missing:
				return false
		return true

class DictCompareOpen:
	extends OperatorBase
	var fields:Dictionary
	var any:bool
	var fail_missing:bool

	func _init(fields_: Dictionary, _any=false, _fail_missing=true):
		# fields = fields_
		for p in fields_:
			var op = fields_[p]
			if not op is OperatorBase:
				op = Eq.new(fields_[p])
			var open = OpenDeep.new(p)
			p = open.fields.back()
			fields[p] = {op=op, open=open}
		any = _any
		fail_missing = _fail_missing

	func eval(item):
		return item_valid(item, fields)

	func item_valid(item, comps: Dictionary)->bool:
		for key in comps:
			var r = comps[key].open.eval(item)
			if r == null and fail_missing:
				return false
			else:
				if comps[key].op.eval(r):
					if any:
						return true
				else:
					return false
		return true

						
# NOTE: will not actually stop user from mutating an object
class DictApplied:
	extends OperatorBase
	var fields:Dictionary
	var open:OpenMultiDeep
	var open_if_found:bool

	func _all_ops(fields_:Dictionary):
		for v in fields_.values():
			if not v is OperatorBase and not v is String:
				return false
		return true

	func _init(fields_:Dictionary, other_:Array=[], open_if_found_=false).():
		fields = fields_
		for k in fields:
			fields[k] = Util.get_map_op(fields[k])
		assert(_all_ops(fields_))
		open = OpenMultiDeep.new(other_)
		open_if_found = open_if_found_

	func eval(item):
		return result(item, fields)

	func result(item, fields: Dictionary):
		var r = {}
		for key in fields:
			if open_if_found and key in item:
				r[key] = fields[key].eval(item[key])
			else:
				r[key] = fields[key].eval(item)
		var other = open.eval(item)
		for k in other:
			r[k] = other[k]
		return r

# ==============================================================
# EVALUATIVE OPERATORS; 'eval' should return a bool
		
# ------------------------------------------------------------ 
# LOGICAL
"""
	returns true if all operators in 'cmps' are true
	will exit early if a result is false
	Expects an array of operators

	usage:
		var comp = And.new([GT.new(20), LT.new(70)]) # 20 < age < 70

"""
class And:
	extends OperatorBase
	var cmps
	func _init(cmps=[]):
		self.cmps = cmps
		
	func eval(item):
		for c in cmps:
			if not c.eval(item):
				return false
		return true

	func eval2(x_next, x_total):
		for c in cmps:
			if not c.eval(x_total) or not c.eval(x_next):
				return false
		return true

	
"""
	returns true if any operators in 'cmps' are true
	Expects an array of operators

	usage:
		var comp = Or.new([Eq.new("Mike"), Eq.new("Anna")])

	"""
class Or:
	extends OperatorBase
	var cmps
	func _init(cmps=[]):
		self.cmps = cmps
		
	func eval(item):
		for c in cmps:
			if c.eval(item):
				return true
		return false

	func eval2(x_next, x_total):
		for c in cmps:
			if c.eval(x_total) and c.eval(x_next):
				return true
		return false
"""
	returns false if 'cmp.eval(item)' returns true and vice versa
"""
class Not:
	extends OperatorBase
	var cmp
	
	func _init(cmp):
		self.cmp = cmp
		
	func eval(item):
		if cmp.eval(item):
			return false
		return true

"""
	returns false for any item
"""
class Is:
	extends OperatorBase
	var type
	func _init(type_):
		type = type_
		
	func eval(item):
		return item is type
		
class IsVariantType:
	extends OperatorBase
	var type:int
	func _init(type_:int):
		type = type_
		
	func eval(item):
		return typeof(item) == type
				
# ------------------------------------------------------------ 
# COMPARITIVE
	
"""
	Less than
"""
class Even:
	extends OperatorBase
	var val
		
	func eval(item):
		return item % 2 == 0
	
"""
	Less than
"""
class LT:
	extends OperatorBase
	var val
	func _init(val=0):
		self.val = val
		
	func eval(item):
		return eval2(item, val)

	func eval2(item0, item1):
		return item0 < item1


"""
	Greater than
"""
class GT:
	extends OperatorBase
	var val
	func _init(val=0):
		self.val = val
		
	func eval(item):
		return eval2(item, val)

	func eval2(item0, item1):
		return item0 > item1
				
"""
	Equal to
"""
class Eq:
	extends OperatorBase
	var val
	func _init(val=0):
		self.val = val
		
	func eval(item):
		return eval2(item, val)
		
	func eval2(item0, item1):
		return item0 == item1
		
class HashEq:
	extends OperatorBase
	var val
	func _init(val=null):
		self.val = val
		
	func eval(item):
		return eval2(item, val)
		
	func eval2(item0, item1):
		return item0.hash() == item1.hash()
		

# ------------------------------------------------------------ 
# COLLECTION OPERATORS
class In:
	extends OperatorBase
	var container
	func _init(container=[]):
		self.container = container
		
	func eval(item):
		# for i in container:
		# 	if item == i: return true
		# return false
		return eval2(item, container)
		
	func eval2(item0, item1):
		# return item0 in item1	
		for i in item1:
			if item0 == i: return true
		return false


class Contains:
	extends OperatorBase
	var item
	func _init(item):
		self.item = item
		
	func eval(container):
		for i in container:
			if item == i: return true
		return false
#		return self.item in item

	# func eval2(item0, item1):
	# 	return item1 in item0	
			
# ==============================================================
# FUNCTION-Y; 'eval' can return anything
# ------------------------------------------------------------ 
# FUNCREF

"""
Call a function on an object
	usage:
		func validate(item):
			...
			return true

		Func.new(funcref(self, "validate"), [arg1, ..., argN])
"""

class Func:
	extends OperatorBase
	
	var args:Array
	var func_ref:FuncRef

	func _init(func_ref:FuncRef, args:Array=[]):
		self.func_ref = func_ref
		self.args = args

	func eval(item):
		return func_ref.call_funcv([item] + args)

	func eval2(item0, item1):
		return func_ref.call_funcv([item0, item1] + args)
		
"""
	Use each element in 'item' as an argument to the target function.
	in eval, 'item' must be an array
"""
class FuncAsArgs:
	extends OperatorBase
	
	var func_ref:FuncRef

	func _init(func_ref:FuncRef):
		self.func_ref = func_ref

	func eval(item):
		return func_ref.call_funcv(item)

	func eval2(item0, item1):
		return func_ref.call_funcv(item0 + item1)

class CallFunc:
	extends OperatorBase
	
	var fn_name:String
	var args:Array
	var return_item = false
	
	func _init(fn_name_:String, args:Array=[], return_item_=false):
		fn_name = fn_name_
		args = args
		return_item = return_item_
		
	func eval(item):
		var r = item.callv(fn_name, args)
		if return_item:
			return item
		return r

	# func eval2(item0, item1):
	# 	return func_ref.call_funcv([item0, item1] + args)
				
class Expr:
	extends OperatorBase
	
	var expr:Expression = Expression.new()
	var target
	var expr_str
	func _init(expr_str_:String, _target=null).():
		expr.parse(expr_str_, [EXPR_NAME, EXPR_NAME2])
		expr_str = expr_str_
		target = _target
		
	func eval(item):
		return expr.execute([item], target)

	func eval2(item0, item1):
		return expr.execute([item0, item1], target)
				
class ExprArgs:
	extends OperatorBase
	
	var expr:Expression = Expression.new()
	var fields = []
	var target
	
	func _init(expr_str:String, fields:Array=[], _target=null).():
		for f in fields:
			self.fields.append(Open.new(f))
		expr.parse(expr_str, [EXPR_NAME] + fields)
		target = _target
		
	func eval(item):
		var args = []
		for f in fields:
			args.append(f.eval(item))
		return expr.execute([item] + args, target)

class ExprArgsDeep:
	extends OperatorBase
	
	var expr:Expression = Expression.new()
	var fields = []
	var target
	
	func _init(expr_str:String, fields_:Array=[], _target=null).():
		var r = []
		for f in fields_:
			var f_split = f.split("/")
			r.append(f_split[f_split.size()-1])
			fields.append(OpenDeep.new(f))
		expr.parse(expr_str,  [EXPR_NAME] + r + [EXPR_NAME2])
		target = _target
		
	func eval(item):
		var args = []
		for f in fields:
			args.append(f.eval(item))
		return expr.execute([item] + args, target)

	func eval2(item0, item1):
		var args = []
		for f in fields:
			args.append(f.eval(item0))
		return expr.execute([item0] + args + [item1], target)
			

class ExprArgsDict:
	extends OperatorBase
	
	var expr:Expression = Expression.new()
	var fields = {}
	var target
	var expr_str:String
	func _init(expr_str_:String, _fields:Dictionary={}, _target=null).():
		fields = _fields
		expr.parse(expr_str_, [EXPR_NAME] + fields.keys() + [EXPR_NAME2])
		expr_str = expr_str_
		target = _target
		
	func eval(item=null):
		return expr.execute([item] + fields.values(), target)
	
	func eval2(item0, item1):
		return expr.execute([item0] + fields.values() + [item1], target)
		
class Open:
	extends OperatorBase
	
	var field:String
	
	func _init(field:String).():
		self.field = field

	func eval(item):
		var result = null
		if field in item:
			result = item[field]
		return result
	
class OpenMulti:
	extends OperatorBase

	var fields:Array
	
	func _init(_fields:Array).():
		fields = _fields

	func eval(item):
		var n = {}
		for f in fields:
			if f in item:
				n[f] = item[f]
		return n
	
class OpenDeep:
	extends OperatorBase
	
	var fields:Array = []
	
	func _init(field:String).():
		var f_split = field.split("/")
		for s in f_split:
			fields.append(s)

	func eval(item):
		var result = null
		for f in fields:
			if f == "*":
				result = item
				continue
			if f in item:
				result = item[f]
				item = result
				
			else: return null
		return result

class OpenMultiDeep:
	extends OperatorBase

	# filled with OpenDeep
	var ops:Dictionary = {}
	
	func _init(_fields:Array).():
		for f in _fields:
			ops[f] = OpenDeep.new(f)
			assert(not ops[f].fields.empty())

	func eval(item):
		var result = {}
		for f in ops:
			var name = ops[f].fields.back()
			result[name] = ops[f].eval(item)
		return result

# creates dictionary with fields renamed to those supplied
class OpenMultiDeepDict:
	extends OperatorBase

	# filled with OpenDeep
	var ops:Dictionary = {}
	
	func _init(_fields:Dictionary).():
		for k in _fields:
			var v = _fields[k]
			ops[k] = OpenDeep.new(v)
			assert(not ops[k].fields.empty())

	func eval(item):
		var result = {}
		for k in ops:
			# var name = ops[k].fields.back()
			result[k] = ops[k].eval(item)
		return result
		
class OpenIndex:
	extends OperatorBase
	
	var idx:int
	var defval = null
	
	func _init(idx:int, defval_=null).():
		self.idx = idx
		defval = defval_

	func eval(item):
		var result = defval
		if item is Array and idx < item.size():
			result = item[idx]
		return result
	
class OpenIndexMultiDeep:
	extends OperatorBase

	# filled with OpenDeep
	var ops:Dictionary = {}
	
	func _init(idxs_:Array, defval=null).():
		for f in idxs_:
			if f is Array:
				ops[f] = OpenIndexDeepArray.new(f, defval)
			else:
				ops[f] = OpenIndexDeep.new(str(f), defval)
			assert(not ops[f].idxs.empty())

	func eval(item):
		var result = []
		for f in ops:
			if not ops[f].idxs.empty():
				var name = ops[f].idxs.back()
				result.append(ops[f].eval(item))
		return result
		
class OpenIndexDeep:
	extends OperatorBase
	
	var idxs:Array = []
	var defval
	
	func _init(field:String, defval_=null).():
		defval = defval_
		var f_split = field.split("/")
		for s in f_split:
			idxs.append(int(s))

	func eval(item):
		var result = defval
		for f in idxs:
			# if f == "*":
			# 	result = item
			# 	continue
			if item is Array and f < item.size():
				result = item[f]
				item = result
				
			else: return defval
		return result
		
class OpenIndexDeepArray:
	extends OperatorBase
	
	var idxs:Array = []
	var defval
	func _init(path:Array, defval_=null).():
		idxs = path
		defval = defval_

	func eval(item):
		var result = defval
		for i in idxs:
			if item is Array and i < item.size():
				result = item[i]
				item = result
				
			else: return defval
		return result

					
"""
	returns true if field in item.
		i.e. 'item.field' exists
"""
class HasField:
	extends OpenDeep
#	var field

	func _init(field: String).(field):
#		self.field = field
		pass

	func eval(item):
		var r = .eval(item)
		return r != null

# returns in the order provided an array of the requested fields
# ['name', 'age'] => ['mike', 43]
class GetValue:
	extends OperatorBase

	# filled with OpenDeep
	var ops:Array = []

	func _init(_fields:Array).():
		for f in _fields:
			ops.append(OpenDeep.new(f))
			assert(not ops.back().fields.empty())

	func eval(item):
		var result = []
		for f in ops:
			if not f.fields.empty():
				result.append(f.eval(item))
		return result
