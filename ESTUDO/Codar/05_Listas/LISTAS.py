meudeus = [8, 1, 4, 3]
print (meudeus)
meudeus.append(5)
meudeus.sort()
meudeus.insert(4, 0)
meudeus.remove(1)
print (meudeus)

valores = [1, 2, 3]

for c, v in enumerate(valores):
    print(f'em {c} tem {v}...', end='')
print ('')

aura = list()
for laura in range(0,5):
    aura.append(int(input(f'DIGITE O VALOR NUMERO {laura}: ')))
print (aura)

a = [1, 2, 3, 4]
b = a[:]
b[2] = 8
print (a)
print (b)