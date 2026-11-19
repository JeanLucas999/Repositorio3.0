dic = {}

dic['nome: '] = input('DIGITE O NOME DO ALUNO: ').upper()
dic['media: '] = float(input(f'AGORA DIGITE A MEDIA DE {dic['nome: ']}: '))
if dic['media: ']>=6:
    dic['situacao:'] = 'APROVADO'
else:
    dic['situacao:'] = 'REPROVADO'

for k, v in dic.items():
    print (k, v)