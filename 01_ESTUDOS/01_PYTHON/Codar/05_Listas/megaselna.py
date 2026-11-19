from random import randint

re = int(input('DIGITE QUANTOS JOGOS QUER GERAR: '))
mega = []
#pronto = [] no lugar de ficar dentro do loop

for p in range (re):
    pronto = []
    while len(pronto)<6:
        sorteio = (randint(1,60))
        if sorteio not in pronto:
            pronto.append(sorteio)
    pronto.sort()
    mega.append(pronto[:])
    #pronto.clear() no lugar de ficar dentro do loop

for p, c in enumerate(mega):
    print (f'JOGO {p+1}: {c}')
