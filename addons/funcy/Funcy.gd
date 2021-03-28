class_name Funcy

const ListOps = preload("ListOperators.gd")
const Operators = preload("Operators.gd")
const OpBase = Operators.OperatorBase

static func process_op(list_cls, data=null):
	if data != null:
		return list_cls.eval(data)
	return list_cls

# ==============================================================================

static func map(op, data=null) -> OpBase:
	op = Operators.Util.get_map_op(op)
	return process_op(ListOps.Map.new(op), data)

static func project(input, data=null) -> OpBase:
	if input is String:
		input = [input]
	return map(open(input), data)
		
static func filter(op, data=null) -> OpBase:
	op = Operators.Util.get_filter_op(op)
	return process_op(ListOps.Filter.new(op), data)

static func take_while(op, data=null) -> OpBase:
	op = Operators.Util.get_filter_op(op)
	return process_op(ListOps.TakeWhile.new(op), data)

static func take(n, data=null) -> OpBase:
	return process_op(ListOps.Slice.new(0, n-1), data)

static func skip(n, data=null) -> OpBase:
	return process_op(ListOps.Slice.new(n, -1), data)
	
static func sort(op, data=null) -> OpBase:
	return process_op(ListOps.Sort.new(op), data)
 
# ------------------------------------------------------------------------------

static func insert(item, data=null):
	return process_op(ListOps.Insert.new(item), data)
	
static func remove(item, data=null):
	return process_op(ListOps.Remove.new(item), data)
	
static func pop(data=null):
	return process_op(ListOps.Pop.new(), data)
	
# ------------------------------------------------------------------------------

static func defer(op, data):
	if op is Array: op = comp(op)
	return ListOps.Defer.new(op, data)
	
# ------------------------------------------------------------------------------
	
static func do(op, data):
	if op is Array: op = comp(op)
	return op.eval(data)
	
static func first(op, data=null):
	return filter(op, data).front()

static func last(op, data=null):
	return filter(op, data).back()

static func reduce(op, data=null):
	op = Operators.Util.get_map_op(op)
	return process_op(ListOps.Reduce.new(op), data)

# ------------------------------------------------------------------------------
	
static func comp(ops:Array, data=null) -> OpBase:
	return process_op(Operators.OperatorIterator.new(ops), data)

# same as comp but translates input to filter-ops
static func comp_f(ops:Array, data=null) -> OpBase:
	return comp(
		Operators.Util.get_filter_op_arr(ops), data)
		
# same as comp but translates input to map-ops
static func comp_m(ops:Array, data=null) -> OpBase:
	return comp(
		Operators.Util.get_map_op_arr(ops), data)

# runs exit_op.eval for each and exits early if it returns false
static func comp_exit(ops:Array, exit_op:OpBase, data=null) -> OpBase:
	return process_op(Operators.OperatorIterator.new(ops, exit_op), data)

# ------------------------------------------------------------------------------

static func and_(items: Array) -> OpBase:
	return Operators.And.new(items)

static func or_(items: Array) -> OpBase:
	return Operators.Or.new(items)

# ------------------------------------------------------------------------------

# return true if all ops eval to true. Exits early.
static func all(items: Array) -> OpBase:
	return and_(Operators.Util.get_filter_op_arr(items))

# return true if any ops eval to true. Exits early.
static func any(items: Array) -> OpBase:
	return or_(Operators.Util.get_filter_op_arr(items))

static func not_(op) -> OpBase:
	return Operators.Not.new(Operators.Util.get_filter_op(op))
			
# ------------------------------------------------------------------------------
	
# uses each item as arguments to a function
# NOTE: items must be of type Array
static func as_args(fn:FuncRef, data=null) -> OpBase:
	return map(Operators.FuncAsArgs.new(fn), data)


# returns 'val'
static func value(val) -> OpBase:
	return Operators.Value.new(val)

# returns what goes in
static func identity() -> OpBase:
	return Operators.Identity.new()
	
# ------------------------------------------------------------------------------

static func even() -> OpBase:
	return Operators.Even.new()
	
static func odd() -> OpBase:
	return not_(even())
		
# ------------------------------------------------------------------------------

static func gt(item=0) -> OpBase:
	return Operators.GT.new(item)
	
static func lt(item=0) -> OpBase:
	return Operators.LT.new(item)

static func eq(item=0) -> OpBase:
	return Operators.Eq.new(item)

static func gteq(item=0) -> OpBase:
	return or_([gt(item), eq(item)])
	
static func lteq(item=0) -> OpBase:
	return or_([lt(item), eq(item)])

# ------------------------------------------------------------------------------

# preds: a dictionary in the form {field0=some_op_or_value_to_compare, ...}
# _any: if true, return true if any fields are valid; false by default
# _fail_missing: fail if any field not found
static func dict_cmpr(preds:Dictionary, _any=false, _fail_missing=true) -> OpBase:
	return Operators.DictCompareOpen.new(preds, _any, _fail_missing)

# input: a dictionary as above but only accepting operators as values
# other: the fields to select alongside those stated in input
# open_if_found: if true will pass the value of a field (if it exists) in the object to the op
#   -otherwise the whole object is passed. false by default
static func dict_apply(input:Dictionary, other=[], open_if_found=false) -> OpBase:
	return Operators.DictApplied.new(input, other, open_if_found)

# ------------------------------------------------------------------------------
# FLOW
static func if_(pred, then, else_) -> OpBase:
	return Operators.RunIf.new(pred, then, else_)
	
static func run(field, op) -> OpBase:
	return Operators.RunOp.new(field, op)

# ------------------------------------------------------------------------------

static func in_(item) -> OpBase:
	return Operators.In.new(item)

static func is_(cls) -> OpBase:
	return Operators.Is.new(cls)
	
static func is_var(type:int) -> OpBase:
	return Operators.IsVariantType.new(type)

static func contains(item) -> OpBase:
	return Operators.Contains.new(item)

# true if field is present in item. Can go deep i.e. 'inventory/coins'
static func has(item) -> OpBase:
	return Operators.HasField.new(item)

# ------------------------------------------------------------------------------

static func func_(obj:Object, func_name:String, args=[]) -> OpBase:
	var fn = funcref(obj, func_name)
	return Operators.Func.new(fn, args)

static func call_fn(func_name:String, args=[], return_item=false) -> OpBase:
	return Operators.CallFunc.new(func_name, args, return_item)
	
static func func_as_args(obj:Object, func_name:String) -> OpBase:
	var fn = funcref(obj, func_name)
	return Operators.FuncAsArgs.new(fn)

static func expr(expr_str:String, fields=null, target=null) -> OpBase:
	if fields is Dictionary:
		return Operators.ExprArgsDict.new(expr_str, fields, target)
	elif fields is Array:
		return Operators.ExprArgsDeep.new(expr_str, fields, target)
	elif fields is String:
		return Operators.ExprArgsDeep.new(expr_str, [fields], target)
	return Operators.Expr.new(expr_str, target)

# ------------------------------------------------------------------------------

static func open(field) -> OpBase:
	if field is Array:
		return Operators.OpenMultiDeep.new(field)
	assert(field is Dictionary)
	return Operators.OpenMultiDeepDict.new(field)
	
# returns only the field specified.
static func open_one(field:String) -> OpBase:
	return Operators.OpenDeep.new(field)

# returns only the fields specified	. Output will be wrapped in Array.
static func open_val(fields:Array) -> OpBase:
	return Operators.GetValue.new(fields)
	
static func open_idx(field, defval=null) -> OpBase:
	if field is Array:
		return Operators.OpenIndexMultiDeep.new(field, defval)
	elif field is String:
		return Operators.OpenIndexDeep.new(field, defval)
	return Operators.OpenIndex.new(field, defval)
