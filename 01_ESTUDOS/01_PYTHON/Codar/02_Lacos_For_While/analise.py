si = 0
me = 0
maisvelho = ''
idd = 0
fe = 0
for c in range (0,4):
    nome = (input('DIGITE SEU NOME: '))
    sexo = (input('DIGITE SEU SEXO [M/F]: '))
    idade = int(input('DIGITE SUA IDADE: '))
    si += idade
    if sexo=='M':
        if idade>idd:
            maisvelho = nome
    idd = idade
    if sexo == 'F' and idade>=20:
        fe += 1
me = si/4
print (f'O homem mais velho eh {maisvelho}')
print (f'{fe} mulheres tem mais de 20 anos')
print (f'A media de idade eh {me} anos')