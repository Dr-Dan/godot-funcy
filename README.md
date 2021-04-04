# Funcy

Written in Godot 3.2

A library to aid a functional programming style in gdscript. 
Provides operators that deal with lists and individual items.

Similar to ramda, underscore.js

Largely untested and probably slow but good for prototyping and speedy development.

## Usage

[examples...](../main/examples)

[Funcy.gd](../main/addons/funcy/Funcy.gd)

### Quick demo
```gdScript
const F = Funcy

# open fields for each
F.map(F.open(['inv/weapon', 'name', 'age']))

# get only the items that pass validation
F.filter(F.all([F.gt(4), F.lteq(9)]))

F.expr('_x.age < _y.age'), 
F.fn(self, 'plus_xy', [2]), 

# compose operators
F.comp([
    # map, filter
    F.map([
        F.expr('_x + 3'),
        F.fn(self, 'plus_xy', [2])]),
    F.filter(F.gt(5))
    ])
```

### eval
There are multiple ways to trigger evaluation of a query

```gdScript
# use query later
F.map(op)

# these have the same effect
F.map(op).eval(data)
F.map(op, data)
F.do(F.map(op), data)
```

## Installation

Download from the Asset Store

Or place addons/Funcy in the addons folder of your project.