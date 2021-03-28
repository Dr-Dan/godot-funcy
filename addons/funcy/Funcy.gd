const Ops = preload("OperatorFactory.gd")
const ListOps = preload("ListOperators.gd")

static func process_op(list_cls, data=null):
	if data != null:
		return list_cls.eval(data)
	return list_cls
	
# ==============================================================================

static func map(op, data=null):
	op = Ops.Operators.Util.get_map_op(op)
	return process_op(ListOps.Map.new(op), data)

static func project(input, data=null):
	if input is String: 
		input = [input]
	return map(Ops.open(input), data)
		
static func filter(op, data=null):
	op = Ops.Operators.Util.get_filter_op(op)
	return process_op(ListOps.Filter.new(op), data)

static func take_while(op, data=null):
	op = Ops.Operators.Util.get_filter_op(op)
	return process_op(ListOps.TakeWhile.new(op), data)

static func take(n, data=null):
	return process_op(ListOps.Slice.new(0, n-1), data)

static func skip(n, data=null):
	return process_op(ListOps.Slice.new(n, -1), data)
	
static func sort(op, data=null):
	return process_op(ListOps.Sort.new(op), data)

# ------------------------------------------------------------------------------
static func first(op, data=null):
	return filter(op, data).front()

static func last(op, data=null):
	return filter(op, data).back()

static func reduce(op, data=null):
	op = Ops.Operators.Util.get_map_op(op)
	return process_op(ListOps.Reduce.new(op), data)

# ------------------------------------------------------------------------------
	
static func comp(ops:Array, exit_op=null, is_predicate=false):
	return Ops.Operators.OperatorIterator.new(ops, exit_op, is_predicate)

static func comp_f(ops:Array, exit_op=null, is_predicate=false):
	return comp(
		Ops.Operators.Util.get_filter_op_arr(ops), exit_op, is_predicate)
		
static func comp_m(ops:Array, exit_op=null, is_predicate=false):
	return comp(
		Ops.Operators.Util.get_map_op_arr(ops), exit_op, is_predicate)

# ------------------------------------------------------------------------------

static func all(items: Array):
	return Ops.and_(Ops.Operators.Util.get_filter_op_arr(items))

static func any(items: Array):
	return Ops.or_(Ops.Operators.Util.get_filter_op_arr(items))

static func not_(op):
	return Ops.not_(Ops.Operators.Util.get_filter_op(op))
			
# ------------------------------------------------------------------------------
	
# uses each item as arguments to a function
# NOTE: items must be of type Array
static func as_args(fn:FuncRef, data=null):
	return map(Ops.Operators.FuncAsArgs.new(fn), data)

# ------------------------------------------------------------------------------

static func and_(items: Array) -> Op:
	return Operators.And.new(items)

static func or_(items: Array) -> Op:
	return Operators.Or.new(items)

static func not_(item) -> Op:
	return Operators.Not.new(item)
	
# ------------------------------------------------------------------------------

# preds: a dictionary in the form {field0=some_op_or_value_to_compare, ...}
# _any: if true, return true if any fields are valid; false by default
# _fail_missing: fail if any field not found
static func dict_cmpr(preds:Dictionary, _any=false, _fail_missing=true) -> Op:
	return Operators.DictCompareOpen.new(preds, _any, _fail_missing)

# input: a dictionary as above but only accepting operators as values
# other: the fields to select alongside those stated in input
# open_if_found: if true will pass the value of a field (if it exists) in the object to the op
#   -otherwise the whole object is passed. false by default
static func dict_apply(input:Dictionary, other=[], open_if_found=false) -> Op:
	return Operators.DictApplied.new(input, other, open_if_found)

# ------------------------------------------------------------------------------
# FLOW
static func if_(pred, then, else_) -> Op:
	return Operators.RunIf.new(pred, then, else_)
	
# static func run(field, op) -> Op:
# 	return Operators.RunOp.new(field, op)
