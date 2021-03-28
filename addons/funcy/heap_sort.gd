# https://www.geeksforgeeks.org/heap-sort/

static func heapify(arr, n, i, op):
	var largest = i # Initialize largest as root
	var l = 2 * i + 1     # left = 2*i + 1
	var r = 2 * i + 2     # right = 2*i + 2
  
	# See if left child of root exists and is 
	# greater than root 
	if l < n and op.eval2(arr[i], arr[l]):
		largest = l
  
	# See if right child of root exists and is 
	# greater than root 
	if r < n and op.eval2(arr[largest], arr[r]):
		largest = r
  
	# Change root, if needed 
	if largest != i:
		var t = arr[largest]
		arr[largest] = arr[i] # swap
		arr[i] = t
  
		# Heapify the root. 
		heapify(arr, n, largest, op)
  
# The main function to sort an array of given size 
static func heap_sort(op, arr):
	arr = [] + arr
	var n = len(arr)
	# Build a maxheap. 
	for i in range(n/2 - 1, -1, -1):
		heapify(arr, n, i, op)
  
	# One by one extract elements 
	for i in range(n-1, 0, -1):
		var t = arr[i]
		arr[i] = arr[0]
		arr[0] = t
		heapify(arr, i, 0, op)
	return arr
  
#func _run():
#	var arr = [12, 11, 13, 5, 6, 7]
#	arr = heap_sort(ops.expr('_x < _y'), arr)
#	var n = len(arr)
#	print("Sorted array is")
#	for i in range(n):
#		print ("%d" %arr[i])
