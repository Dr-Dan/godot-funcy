extends EditorScript
tool

const F = preload("res://addons/funcy/Funcy.gd")

# TODO: 
# combine Funcy <- OpFac
# docs

# LATER:
# autoload
# group-by
# op.to_string
# generators i.e. F.insert()
# qry tree?
# scene example

func print_(x, y):
	prints(x, y)

func _run():
	var oo = F.comp([
		F.filter(F.all([F.Ops.gteq(6), '_x % 2 == 0'])), 
		F.skip(2),
		F.take(3),
		F.sort('_x > _y'),
		])
	print(oo.eval(range(20)))
	
	F.as_args(funcref(self, 'print_'), [[1,2], ["hello", "world"]])
	
	var people = [
		{name="Dan", age=1}, {name="Phil", age=2}]
	var qry = F.comp([
		# F.filter('_x.age > 1'),
#		F.filter({name="Dan"}),
		# F.project(['age', 'name']),
		F.open('age'),
		F.reduce('_x + _y')
])
	print(qry.eval(people))
