extends Resource
class_name Opfactory

const Operators = preload("Operators.gd")
const Op = Operators.OperatorBase

# returns 'val'
static func value(val) -> Op:
	return Operators.Value.new(val)

static func identity() -> Op:
	return Operators.Identity.new()
	
# ------------------------------------------------------------------------------

static func even() -> Op:
	return Operators.Even.new()
	
# ------------------------------------------------------------------------------

static func gt(item=0) -> Op:
	return Operators.GT.new(item)
	
static func lt(item=0) -> Op:
	return Operators.LT.new(item)

static func eq(item=0) -> Op:
	return Operators.Eq.new(item)

static func gteq(item=0) -> Op:
	return or_([gt(item), eq(item)])
	
static func lteq(item=0) -> Op:
	return or_([lt(item), eq(item)])

# ------------------------------------------------------------------------------

static func in_(item) -> Op:
	return Operators.In.new(item)

static func is_(cls) -> Op:
	return Operators.Is.new(cls)
	
static func is_var(type:int) -> Op:
	return Operators.IsVariantType.new(type)

static func contains(item) -> Op:
	return Operators.Contains.new(item)

static func has(item) -> Op:
	return Operators.HasField.new(item)

# ------------------------------------------------------------------------------

static func func_(obj:Object, func_name:String, args=[]) -> Op:
	var fn = funcref(obj, func_name)
	return Operators.Func.new(fn, args)

static func call_fn(func_name:String, args=[], return_item=false) -> Op:
	return Operators.CallFunc.new(func_name, args, return_item)	
	
static func func_as_args(obj:Object, func_name:String) -> Op:
	var fn = funcref(obj, func_name)
	return Operators.FuncAsArgs.new(fn)

static func expr(expr_str:String, fields=null, target=null) -> Op:
	if fields is Dictionary:
		return Operators.ExprArgsDict.new(expr_str, fields, target)
	elif fields is Array:
		return Operators.ExprArgsDeep.new(expr_str, fields, target)
	elif fields is String:
		return Operators.ExprArgsDeep.new(expr_str, [fields], target)
	return Operators.Expr.new(expr_str, target)

# ------------------------------------------------------------------------------

static func open_v(fields:Array) -> Op:
	return Operators.GetValue.new(fields)

static func open(field) -> Op:
	if field is Array:
		return Operators.OpenMultiDeep.new(field)
	elif field is Dictionary:
		return Operators.OpenMultiDeepDict.new(field)
	assert(field is String)
	return Operators.OpenDeep.new(field)
	
static func open_idx(field, defval=null) -> Op:
	if field is Array:
		return Operators.OpenIndexMultiDeep.new(field, defval)
	elif field is String:
		return Operators.OpenIndexDeep.new(field, defval)
	return Operators.OpenIndex.new(field, defval)
