aura = {}
gols = []
jugadores = []
tot = 0

while True:
    aura['NOME'] = input('DIGITE O NOME DO JOGADOR: ')
    aura['JOGOS'] = int(input('AGORA O NUMERO DE JOGOS: '))
    print ('-'*35)

    for c in range (aura["JOGOS"]):
        gols.append(int(input(f'QUANTOS GOLS {aura["NOME"]} FEZ NA PARTIDA {c+1}? ')))
        tot += gols[c]
    print ('-'*35)

    aura['GOLS'], aura['TOTAL DE GOLS'] = gols[:], tot

    jugadores.append(aura.copy())

    gols.clear()
    aura.clear()
    tot = 0

    re = input('QUER CONTINUAR [S/N]: ')
    print ('-'*35)
    if re.upper() != 'S':
        break

for c in jugadores:
    print (c)
    print ('-'*35)

for c in range(len(jugadores)):
    print (jugadores)
    print (f'{jugadores[c]["NOME"]} JOGOU {jugadores[c]["JOGOS"]} JOGOS')
    for i in range(jugadores[c]['JOGOS']):
        print (f'     NA PARTIDA {i+1} {jugadores[c]["NOME"]} FEZ {jugadores[c]["GOLS"][i]} GOLS')
    print (f'FOI UM TOTAL DE {jugadores[c]["TOTAL DE GOLS"]} GOLS')
    print ('')
    print ('-'*35)