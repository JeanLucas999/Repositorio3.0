class Funcionarios():
    def __init__(self, nome = '', setor = 0, cargo = ''):
        if nome != '':
            self.nome = nome
        else:
            self.nome = 'NOME NAO ESPECIFICADO!!!'
        if cargo != '':
            self.cargo = cargo
        else:
            self.cargo = 'CARGO NAO ESPECIFICADO!!!'
        if setor != 0:
            self.setor = setor
        else:
            self.setor = 'SETOR NAO ESPECIFICADO!!!'
    def __str__(self):
        return f'NOME: {self.nome} SETOR: {self.setor} CARGO: {self.cargo}'

time = []

re = ''

while re.upper() != 'N':
    n = input('DIGITE O NOME DO FUNCIONARIO: ')
    s = int(input('SEU SETOR: '))
    c = input('SEU CARGO: ')
    pessoa = Funcionarios(n, s, c)
    time.append(pessoa)
    re = input('QUER ADICIONAR OUTRO FUNCIONARIO? [S/N]: ')

for i in range(len(time)):
    print (f'FUNCIONARIO {i+1}:\n{time[i]}')

    