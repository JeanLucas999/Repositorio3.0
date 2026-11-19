bla = ((input('DIGITE O NOME DO PRODUTO: ')), int(input('AGORA O VALOR: ')), (input('DIGITE O NOME DO PRODUTO: ')), int(input('AGORA O VALOR: ')))
c = 0
tamain = len(bla)

for c in range (0, tamain, 2):
    print (f'PRODUTO: {bla[c]}, VALOR:{bla[c+1]}')
    