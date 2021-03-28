static func pr_break(ctr:String='-', heading:String='', ln:int=30):
	print("%s\n%s" % [heading, ctr.repeat(ln)])
	
static func pr_array(txt:String='', result=[]):
	pr_break('-')
	print('%s\n' % txt)
	for i in result:
		print(i)
