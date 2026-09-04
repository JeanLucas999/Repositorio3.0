def transmoeda(v = 0, moeda = 'R$'):
    return f'{moeda}{v:.2f}'.replace('.', ',')

def aumentar(n, form = ''):
    n *= 1.10
    if form.upper() == 'N':
        return (n)
    else:
        return transmoeda(n)

def diminuir(n, form = ''):
    n *= 0.90
    if form.upper() == 'N':
        return n
    else:
        return transmoeda(n)

def metade(n, form = ''):
    n /= 2
    if form.upper() == 'N':
        return n
    else:
        return transmoeda(n)

def dobro(n, form = ''):
    n *= 2
    if form.upper() == 'N':
        return n
    else:
        return transmoeda(n)

def resumo(n):
        print ('-'*len('       RESUMO       '))
        print ('       RESUMO       ')
        print ('-'*len('       RESUMO       '))

        print(f'VALOR: {transmoeda(n)}')
        print(f'DOBRO: {dobro(n)}')
        print(f'METADE: {metade(n)}')
        print(f'AUMENTO: {aumentar(n)}')
        print(f'DIMINUICAO: {diminuir(n)}')
