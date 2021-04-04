tool
extends EditorScript

const ex_util = preload("example_utils.gd")
const F = Funcy

"""
To use: File > Run
(Ctrl+Shift+X)
"""

# Funcy will convert input to some functions based on context
# 	observe...

var name_table = [
	{name="Mike", age=22, addr_id=0, inv={money={coin=25}, weapon={gun=1, knife=2}, food={nut=2}}},
	{name="The Oldest One", age=112, addr_id=0, inv={money={coin=1}, weapon={gun=1}, food={nut=2}}},
	{name="Jane Doe", age=16, addr_id=1, inv={weapon={knife=2}, food={}}},
	{name="John Doe", age=54, addr_id=1, inv={weapon={gun=1}, food={berry=1}}},
	{name="xXx", age=42, addr_id=1, inv={money={coin=2000}, weapon={knife=10, gun=2}, food={}, drink={relentless=1}}},
]
func _run():
	var expr_apply_arr = [F.open_one('name'), '_x + " is my name"']
	var expr_cmp_arr = [{addr_id=1}, {age=F.all([F.gt(10), '_x < 50'])}]

	var conversions = [
		[
			"map(open('')) == project('')",
			F.map(F.open('name')),
			F.project('name')
		],
		[
			"map(open([''])) == project([''])",
			F.map(F.open(['name', 'age'])),
			F.project(['name', 'age'] )
		],
		[
			"map(expr('')) == map('')",
			F.map(F.expr('_x.name')),
			F.map('_x.name' )
		],
		[
			"filter(expr('')) == filter('')",
			F.filter(F.expr('_x.age > 22')),
			F.filter('_x.age > 22' )
		],
		[
			"map({}) == map(dict_apply({}))",
			#	NOTE: dict_apply treats input the same as map
			#		i.e. dict_apply({x='_x...'}) == dict_apply({x=expr('_x...')})
			F.map(F.dict_apply({age='_x.age + 5'}) ),
			F.map({age=F.expr('_x.age + 5')}),
		],
		[
			"filter({}) == filter(dict_cmpr({}))",
			#	NOTE: non-operator values in dict_cmpr are wrapped in F.eq()
			#		i.e. dict_cmpr({x=2}) == dict_cmpr({x=eq(2)})
			F.filter(F.dict_cmpr({age=F.gt(20), addr_id=0}) ),
			F.filter({age=F.gt(20), addr_id=F.eq(0)}),
		],
		[
			"map([]) == map(comp([]))",
			# NOTE: nested arrays will also be wrapped with comp()
			F.map(expr_apply_arr),
			F.map(F.comp(expr_apply_arr)),
		],
		[
			"filter([]) == filter(all([]))",
			# NOTE: nested arrays will also be wrapped with all()
			F.filter(expr_cmp_arr),
			F.filter(F.all(expr_cmp_arr)),
		]
	]
	for c in conversions:
		var data = [c[1].eval(name_table), c[2].eval(name_table)]
		printt(c[0])
#		printt('result: ', data)
		printt('hashes are equal:', F.reduce('_x and _y', F.zip(F.hash_eq(), data)))
		print()

