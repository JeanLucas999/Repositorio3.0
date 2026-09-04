dos = []
pss = 0
r = 'S'
mais = 0
menos = 0

while r == 'S' or r == 's':
    nome = (input('DIGITE O NOME DA PESSOA: '))
    peso = (int(input('AGORA SEU PESO: ')))
    dos.append([nome, peso])
    if pss == 0 or peso>mais:
        mais = peso
    elif pss == 0 or peso<menos:
        menos = peso
    pss += 1
    r = (input('QUER CONTINUAR? [S/N] ' \
    ''))

print (dos)
print (f'O mais pesado tinha {mais} e foi: ', end = '')
for c in range(0, len(dos)):
    if dos[c][1]==mais:
        print(dos[c][0], end = '')

print ('')

print (f'O mais leve tinha {menos} e foi: ', end = '')
for c in range(0, len(dos)):
    if dos[c][1]==menos:
        print(dos[c][0], end= '')
