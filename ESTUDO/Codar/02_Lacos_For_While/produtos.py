re = 'S'
umk = 0
c = 0
soma = 0
while re == 'S':
    c += 1
    nome = (input('DIGITE O NOME DO PRODUTO: '))
    valor = int(input('DIGITE O VALOR DO MESMO: '))
    soma += valor
    if c == 1:
        mb = valor
    if valor>1000:
        umk += 1
    if valor<mb:
        mb = valor
        mbn = nome
    re = (input('QUER CONTINUAR? [S/N]:'))
print (f'O produto mais barato foi {mbn} custando R${mb:.2f}')
print (f'{umk} produtos custaram mais que R$1000.00')
print (f'A soma desses produtos deu: R${soma:.2f}')