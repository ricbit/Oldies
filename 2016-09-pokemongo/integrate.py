import json

pokemons = json.loads(open("pokemon.json").read())
norm = sum(p[1] for p in pokemons)
formula = []
for name, prob in pokemons:
    formula.append("(1-Exp[-%f*t])" % (prob/norm))
print "NIntegrate[1-%s,{t,0,Infinity}]" % "".join(formula)
