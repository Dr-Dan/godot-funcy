tool
extends EditorScript

# ==============================================================	

"""
To use: File > Run
(Ctrl+Shift+X)
"""

const ex_util = preload("example_utils.gd")
const F = Funcy

func _run():
		
	ex_util.pr_break('=')
	evaluation()
	
	ex_util.pr_break('=')
	print("using a collection of objects (Dictionary)\n")
	open_operators()

	ex_util.pr_break('=')
	sorting()

	ex_util.pr_break('=')
	more()
	
	ex_util.pr_break('=')
	example_enumerate()

# ==============================================================	
# DATA
# ==============================================================	
class Human:
	var name: String
	var age: int
	var addr_id: int
	var inv:Dictionary
	var idx = -1
	
	func _init(name, age, addr_id, inv):
		self.name = name
		self.age = age
		self.addr_id = addr_id
		self.inv = inv
		
	func speak():
		print('hi, my name is %s' % name)
		return self
	
var name_table = [
	{name="Mike", age=22, addr_id=0, inv={money={coin=25}, weapon={gun=1, knife=2}, food={nut=2}}},
	{name="The Oldest One", age=112, addr_id=0, inv={money={coin=1}, weapon={gun=1}, food={nut=2}}},
	{name="Jane Doe", age=16, addr_id=1, inv={weapon={knife=2}, food={}}},
	{name="xXx", age=42, addr_id=1, inv={money={coin=2000}, weapon={knife=10, gun=2}, food={}, drink={relentless=1}}},
	Human.new("Carla", 49, 2, {money={coin=248}, food={berry=20}}),
	Human.new("Jing", 87, 2, {money={coin=300}, weapon={knife=1}, food={berry=20}}),
]

var addr_table = [
	{addr_id=0, street="vale road", value=20000},
	{addr_id=1, street="the lane", value=10000},
	{addr_id=2, street="london road", value=35250}]

# ==============================================================	

func evaluation():
	ex_util.pr_array('first 3',
		F.take(3, name_table))

	ex_util.pr_array('skip 3, get name', F.comp(
		[F.skip(3), F.map(F.open_one('name'))],
		name_table))
	
	ex_util.pr_array('take_while ...',
		F.take_while(F.expr('_x.age > 20'),
		name_table))


# ==============================================================	

func sorting():
	print('Sorting')
	ex_util.pr_array('sort by age',
		F.sort(
			F.expr('age < _y.age', ['age']),
			F.map(F.open(['name', 'age'])).eval(name_table)))

	ex_util.pr_array('sort by wealth', 
		F.comp([
			F.filter(F.has('inv/money/coin')),
			F.project(['name', 'inv/money/coin']),
			F.sort('_x.coin > _y.coin')], 
			name_table))
	
# ==============================================================	

# an operator for reducing should implement eval2(input_next, input_accumulated)
class Add:
	extends F.OpBase
	var val
	
	func _init(val_=0):
		val = val_

	func eval(x):
		return x + val
			
	func eval2(x_next, x_total):
		# if no item found, do nothing
		if x_total == null: return x_next
		return x_next + x_total


func open_operators():
	var queries = [
		{
			# get the value of a field from each item
			msg='all names',
			tdx=F.map(F.open_one('name'))
		},
		{
			#  called with Array:
			#  	 open multiple fields; use slashes to go deeeper
			#  result is a dictionary for each with the (final) field name as the key
			msg='view weapons, name and age',
			tdx=F.map(F.open(['inv/weapon', 'name', 'age']))
		},
			{
			#  if 'open' is called with Dictionary
			#  	 will write results to the keys given
			msg='open + rename',
			tdx=F.map(F.open({my_wpns='inv/weapon', my_age='age'}))
		},
		{
			#  open_val(alue) returns just the resulting values in an Array
			# i.e. [v0, v1] instead of [{k0:v0}, {k1:v1}] for each
			msg='view weapons, name and age => []',
			tdx=F.map(F.open_val(['name', 'age', 'inv/weapon']))
		},
		{
			# F.project(x) == F.map(F.open(x))
			# accepts Array and String as input
			msg='project name, inv',
			tdx=F.project(['name', 'inv'])
		},
		{
			msg='who has coin >= 250?',
			tdx=F.comp([
				F.filter(
					# dict_c(o)mp(a)r(e) looks for a given field in the dictionary
					#   and validates it using an op.
					# non-op values are wrapped; {field=2} => {field=ops.eq(2)}
					# you can use slashes in the key
					F.dict_cmpr({'inv/money/coin':F.gteq(250)})),
				F.project(['name', 'inv/money'])])
		},
		{
			# expressions follow the same principle
			msg='age:coin ratio',
			tdx=F.comp([
				F.filter(F.expr('coin != null', 'inv/money/coin')),
				F.map(F.dict_apply({
					age_coin_ratio=F.expr('age/float(coin)', ['inv/money/coin', 'age'])},
					['name']))])
		},
		{
			# dict_apply allows mapping to fields that do not yet exist
			# 	fields that exist will be opened as in F.open
			# if a key is not in the item: 
			#   it will be created and the relevant op will take the entire item
			# 	as an arg instead of item[key]
			msg='who has food?',
			tdx=F.map(
				F.dict_apply(
					{has_food='not _x.inv.food.empty()'},
					['name', 'inv/food'], true))
		},
	]
	# apply expects a Transducer as the first arg
	for itm in queries:
		ex_util.pr_array(itm.msg,
			F.do(itm.tdx, name_table))

	ex_util.pr_break('-')
	
	# sum
	printt('total knives:',
		F.reduce(
			Add.new(),
			F.map(
				F.open_one('inv/weapon/knife'),
				name_table)))
		
# ==============================================================	

func more():
	var value=30000
	var value_qry = F.comp([
		F.filter({value=F.gteq(value)}),
		F.project(["addr_id", "street", "value"])])

	ex_util.pr_array("house value > %d" % value,
		F.do(value_qry, addr_table))

	# select just the addr_id
	var addrs = F.map(
		F.open_one('addr_id'),
		F.do(value_qry, addr_table))

	# select any person where the addr_id is in addrs
	var homeowners = F.do(
		F.comp([
			F.filter({addr_id=F.in_(addrs)}),
			F.project(["name", "addr_id"])]),
		name_table)

	ex_util.pr_array(
		"homeowners filter house value > %d (addr_id in 'addr_ids')" % value,
		homeowners)

	# if the last arg in call_fn is true the item is returned
	#  instead of the function return value
	var is_cls = F.comp([
		F.filter(F.is_(Human)),
		F.project(['name'])])

	# use Variant.Type enum if the class-type can't be used
	var is_dict = F.comp([
		F.filter(F.is_var(TYPE_DICTIONARY)),
		F.project(['name'])])

	ex_util.pr_array('extends Dictionary:', F.do(is_dict, name_table))
	ex_util.pr_array('extends Human:', F.do(is_cls, name_table))

	print('')
	ex_util.pr_break('-', 'calling functions on classes...')	
	F.do([
		F.filter(F.is_(Human)),
		F.map(F.call_fn('speak'))],
		name_table)

# ==============================================================

class Enumeratee:
	var i = -1
	func next():
		i+=1
		return i
	
class EnumerateOp:
	extends F.Operators.OperatorBase
	var i:=-1

	func eval(x):
		i += 1
		return [i, x]

func example_enumerate():
	# enumerate
	var en_wrap = F.expr('{"data":_x, "idx":e.next()}', {e=Enumeratee.new()})
	ex_util.pr_array('enumerated (wrap)', F.map(en_wrap, name_table))

	var en_map = F.dict_apply({idx=F.expr('e.next()', {e=Enumeratee.new()})},
		['name', 'age'])
	ex_util.pr_array('enumerated (map)', F.map(en_map, name_table))

	ex_util.pr_array('enumerated (op)', F.map(EnumerateOp.new(), name_table))
	

