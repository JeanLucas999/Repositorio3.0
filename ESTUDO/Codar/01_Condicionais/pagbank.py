val = int(input('DIGITE O VALOR DO PRODUTO: '))

print('''Qual sera o metodo de pagamento?
[ 1 ] para a vista (10% de desconto)
[ 2 ] para cartao (ate 5% de desconto)''')
re = int(input('Opcao: '))

if re == 1:
    preco = val*0.90

if re == 2:
    print('''A vista: 5% de desconto
2 vezes: preco padrao
3 vezes ou mais: 20% de juros''')
    re = int(input('Em quantas vezes? '))

    if re == 1:
        preco = val*0.95

    elif re == 2:
        preco = val

    else:
        preco = val*1.30
print(f'O valor do produto sera de R${preco:.2f}')