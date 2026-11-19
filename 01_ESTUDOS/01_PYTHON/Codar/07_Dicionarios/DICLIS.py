grupo = {}
grupodogrupo, molieres, acima = [], [], []
sexo = ''
re = ''
si = 0
media = 0.0

while re.upper() != 'N':
    grupo['NOME'] = input('Nome: ')
    grupo['IDADE'] = int(input('Idade: '))
    si += grupo['IDADE']
    while True:
        sexo = input('Sexo [M/F]: ')
        if sexo.upper() != 'M' and sexo.upper() != 'F':
            print ('Erro!!! digite um sexo valido')
        else:
            break
    if sexo.upper() == 'F':
        molieres.append(grupo['NOME'])
    grupo['SEXO'] = sexo.upper()

    grupodogrupo.append(grupo.copy())
    grupo.clear()
    print ('-'*35)
    re = input('Quer continuar [S/N]? ')
    print ('-'*35)

print (f'{len(grupodogrupo)} pessoas foram registradas')

for c in range(len(molieres)):
    if c == 0:
        print ('As mulheres sao: ', end ='')
    if c+1 < len(molieres):
        print (molieres[c], end = ', ')
    else:
        print (molieres[c])

media = si/(len(grupodogrupo))

print (f'A media de idade do grupo foi de: {media:.2f}')

for c in range(len(grupodogrupo)):
    if grupodogrupo[c]['IDADE']>media:
        acima.append(grupodogrupo[c])
for c in acima:
    print(f'{c['NOME']} com {c['IDADE']} anos esta acima da media de {media:.2f}')
