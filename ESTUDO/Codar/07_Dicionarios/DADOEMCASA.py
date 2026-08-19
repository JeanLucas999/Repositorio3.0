from random import randint
from operator import itemgetter

dado = {'jogador1': randint(1,6),
    'jogador2': randint(1,6),
    'jogador3': randint(1,6),
    'jogador4': randint(1,6)
            }
ranking = []

for c, v in dado.items():
    print(f'{c} tirou {v}')

ranking = sorted(dado.items(), key=itemgetter(1), reverse = True)

for c, v in enumerate(ranking):
    print (f'O {c+1}o foi {v[0]} quer tirou {v[1]}')