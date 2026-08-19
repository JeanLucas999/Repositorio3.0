class Conta:
    def __init__(self, nome, saldo = 0):
        self.nome = nome
        self.saldo = saldo

    def saque(self):
        self.saldo -= saquei

    def __str__(self):
        return f'Agora voce tem um saldo de R${self.saldo:.2f}'

name = input('QUAL SEU NOME? ')
dinheiro = float(input('QUAL SEU SALDO? '))
pessoa = Conta(name, dinheiro)
re = (input('QUER FAZER UM SAQUE [S/N]: '))


if re.upper() != 'N':
    saquei = int(input('VALOR DO SAQUE: '))
    try:
        if saquei>pessoa.saldo:
            raise ValueError('')
        pessoa.saque()
        print (f'Voce retirou R${saquei:.2f}')
        print (pessoa)
    except:
        print ('VOCE NAO TEM ESSE DINHEIRO')
