def busca(*notas):
    sm = 0
    dic = {}
    for c in range(len(notas)):
        if c == 0:
            maior = notas[c]
            menor = notas[c]
        elif notas[c]>maior:
            maior = notas[c]
        elif menor>notas[c]:
            menor = notas[c]
        sm += notas[c]
    dic['QUANTIDADE'] = len(notas)
    dic['MAIOR'] = maior 
    dic['MENOR'] = menor
    dic['MEDIA'] = sm/len(notas)
    return dic


print (busca(5,6,4,8,15,5))
#max, min, sum(soma dos elementos)