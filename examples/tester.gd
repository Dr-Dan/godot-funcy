extends EditorScript
tool

#const F = preload("res://addons/funcy/Funcy.gd")
const F = Funcy
# TODO: 
# 

# LATER:
# docs - generate
# scene example
# generators i.e. F.insert()
# group-by
# op.to_string
# qry tree?
			
func print_(x, y):
	prints(x, y)

func _run():
	var qry_num = F.comp([
		F.filter([F.gteq(6), '_x % 2 == 0']), 
		F.skip(2),
		F.take(3),
		F.sort(F.gt())
		])
	print(qry_num.eval(range(20)))
#	print(F.do(qry_num, range(20)))
#	F.as_args(funcref(self, 'print_'), [[1,2], ["hello", "world"]])

#	var people = [
#		{name="Dan", age=1}, {name="Phil", age=2}]
#	var qry = F.comp([
#		# F.filter('_x.age > 1'),
##		F.filter({name="Dan"}),
#		# F.project(['age', 'name']),
#		F.map(F.open_one('age')), # TODO: o
##		F.reduce('_x + _y')
#])
#	print(qry.eval(people))