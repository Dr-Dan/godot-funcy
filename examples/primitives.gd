tool
extends EditorScript

# ==============================================================	

"""
To use: File > Run
(Ctrl+Shift+X)

An example showing Funcy with lists of primitves. i.e. not Objects.
"""

const ex_util = preload("example_utils.gd")
const F = Funcy

func _run():
	ex_util.pr_break('#')
	print('Nested arrays of primitives')
	ex_util.pr_break()
	nested_arrays()
	
	ex_util.pr_break('#')
	print("Using a collection of primitives (int)\n")
	ex_util.pr_break()
	run_queries()
	
	ex_util.pr_break('#')
	print("Reducing and sorting\n")
	ex_util.pr_break()
	reduce_and_sort()

# ==============================================================	

func nested_arrays():
	var nested = [[0, [1, 2], 3], [4, [5, 6]], [7,[8],[9, 10]]]
	printt('data:', nested, '\n')
	
	var open_idx = [
		{
			msg='x[2] for each',
			op=F.open_idx(2),
		},
		{
			msg='x[1][1] for each',
			op=F.open_idx('1/1'),
		},
		{
			msg='[x[0], x[2]] for each',
			op=F.open_idx([0, 2]),
		},
		{
			msg='[x[0][2]] for each',
			op=F.open_idx([[0, 2]]),
		},
		{
			msg='[x[0], x[2], x[1][0], x[1][1]] for each',
			op=F.open_idx(['0', 2, '1/0', [1,1]]),
		}
	]

	for o in open_idx:
		printt(o.msg, F.map(o.op, nested))
	
# ==============================================================	

func less_than_6(x):
	return x < 6

func plus_xy(x, y):
	return x+y

func mult_xyz(x, y, z):
	return x*y*z

class Div:
	extends F.OpBase
	var val
	
	func _init(val_=1):
		val = val_

	func eval(x):
		return float(x) / val
		
# ---------------------------------------------------------------------

var filter_ops = [
	{
		msg='x is even', 
		op=F.even()
	},
	{
		# can use F.odd() operator but for demonstration...
		msg='x is odd', 
		op=F.odd()
	},
	{
		# some F can wrap others	
		# all takes a list of any size
		# F.any([F]) can also be called
		msg='4 < x <= 9', 
		op=F.all([F.gt(4), F.lteq(9)])
	},
	{
		# use an expression operator
		# _x, _y are the default names for vars in F.expr
		# this can be changed at the top of Operators.gd
		msg='x != 4 and x != 1', 
		op=F.expr('_x != 4 and _x != 1')
	},
	{
		msg='x < 6', 
		op=F.fn(self, 'less_than_6')
	},
]
var map_ops = [
	{
		# identity returns the item as is
		msg='x', 
		op=F.identity()
	},
	{
		msg='x + 2', 
		op=F.expr('_x + 2')
	},
	{
		# call built-in function from expr
		msg='x cubed',
		op=F.expr('pow(_x, 3)')
	},
	{
		# named args can be passed to an expression
		msg='pow(x, y)',
		op=F.expr('pow(_x, y)', {y=10})
	},
	{
		# if-else
		msg='if x < 5: pow(x, 2) else: x * 10',
		op=F.if_(
			F.lt(5), 
			F.expr('pow(_x, 2)'), # then
			F.expr('_x * 10')) # else
	},
	{
		# additional args passed to function
		msg='x + y',
		op=F.fn(self, 'plus_xy', [2]),
	},
	{
		msg='x*y*z',
		op=F.fn(self, 'mult_xyz', [5, 10]),
	},
	{
		# use a class that derives from OperatorBase (^above)
		msg='user-op: x / 2',
		op=Div.new(2),
	},
	{
		# comp(ose) passes each entry through a series of operators
		msg='(((x + 3) + y) > 8)',
		op=F.comp([
			F.expr('_x + 3'),
			F.fn(self, 'plus_xy', [2])])
	},
	{
		# dict_apply returns a Dictionary
		#  it will create new fields if they do not exist (in the data)
		msg='dict_apply => {}\n',
		# an Array will be treated as comp([]) in map
		op=[F.expr('_x + 3'),
			F.dict_apply({value=F.identity(), is_even=F.even()})]
		},
	{
		msg='expr => {}\n',
		# if using '{}' in an expr use quotes outside and speech marks inside: 
		#   expr('{"key":value}')
		op=F.expr('{"value": _x}')
	},
]

var list_ops = [
	{
		msg='take while x < 4',
		op=F.take_while(F.expr('_x < 4'))
	},
	{
		msg='x > 4 -> x * x -> {value=x}',
		op=[F.filter(F.gt(4)), F.map(['_x*_x', {value=F.identity()}])]
	},
	{
		msg='invert data -> 8 > x >= 5',
		op=[F.invert(), F.filter([F.lt(8), F.gteq(5)])]
	}
]
# ---------------------------------------------------------------------
					
func run_queries():
	var data = range(10)
	
	prints('data:', data)
	ex_util.pr_break('=')
	
	printt('filter\n')

	# note that calling ListOps (filter, map etc) with data as the last argument 
	#	will cause evaluation.
	# filter returns all in data where the op returns true
	for f in filter_ops:
		printt(f.msg, F.filter(f.op, data))
	ex_util.pr_break('=')

	printt('map\n')

	# map applies an op to each in data and returns the result
	for m in map_ops:
		printt(m.msg, F.map(m.op, data))
	ex_util.pr_break('=')
	
	printt('list-operators\n')
	for m in list_ops:
		printt(m.msg, F.do(m.op, data))
	ex_util.pr_break('=')


func reduce_and_sort():
	# ---------------------------------------------------------------------
	var data = range(10)
	# reduce passes the next item and previous result to each operator
	# in this case; adding them together
	# for this reason the function 'plus_xy' must take 2 args
	printt('add all items:',
		F.reduce(F.fn(self, 'plus_xy'), data))

	# slice to avoid multiplying by 0
	printt('product:',
		F.reduce(F.expr('_x * _y'), data.slice(1,-1)))

	# not all operators will work with sort, ittr, reduce
	# expr, fn, lt/gt/eq for this purpose
	ex_util.pr_break()
	
	print('Sorting\n')
	printt('sorted',
		F.sort(F.lt(), data))
	printt('sorted (descending)',
			F.sort('_x > _y', data))
	printt('sorted dict',
		F.sort(
			F.expr('_x.x > _y.x'), 
			F.map(F.expr('{"x":_x}'), data)))
