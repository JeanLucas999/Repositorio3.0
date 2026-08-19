from datetime import date
clt = {}

clt['NOME'] = input('NOME: ')
ano = int(input('ANO DE NASCIMENTO: '))
clt['IDADE'] = (date.today().year)-ano 
clt['CLT'] = int(input('CLT (0 PARA NAO TEM): '))

if clt['CLT'] != 0:
    clt['ANO DE CONTRATACAO'] = int(input('ANO DE CONTRATACAO: '))
    clt['SALARIO'] = float(input('SALARIO: '))
    clt['APOSENTADORIA'] = ((date.today().year)-clt['ANO DE CONTRATACAO'])+40

print ('-'*30)
for c, v in clt.items():
    print (f'{c} tem valor {v}')