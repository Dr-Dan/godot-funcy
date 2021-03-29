# Funcy

Written in Godot 3.2

A library to aid a functional programming style in gdscript. 
Works with lists of objects and primitives.

Similar to ramda, underscore.js

Largely untested but good for prototyping and speedy development.

## Usage

[examples...](../master/addons/funcy/examples)

[funcy file](../master/addons/funcy/Funcy.gd)

### Quick demo
```gdScript
const F = Funcy

# open fields for each
F.map(F.open(['inv/weapon', 'name', 'age']), data)

var qry = F.filter(F.and_([F.gt(4), F.lteq(9)]))
qry.eval(data)
```

### eval
```gdScript
# use query later
F.map(op)

# these have the same effect
F.map(op).eval(data)
F.map(op, data)
```

## Installation

Download from the Asset Store or Github into the addons folder.