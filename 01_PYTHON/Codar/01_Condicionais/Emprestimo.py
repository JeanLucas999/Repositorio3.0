sal = float(input('Digite seu salario: '))
casa = float(input('Digite o valor da casa: '))
time = int(input('Digite a quantidade de anos: '))
val = casa/(time*12)
valm = val/0.30
if sal*0.30>=val:
    print ('A casa saira por R${:.2f} mensais'.format(val))
else:
    print ('Voce nao atende o requisito de 30% do salario como valor maximo da parcela')
    print ('Voce precisaria ganhar no minimo R${:.2f} para realizar esse emprestimo'.format(valm))