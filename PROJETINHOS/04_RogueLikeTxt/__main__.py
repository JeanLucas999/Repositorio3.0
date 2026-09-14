from rpg import *

def iniciarJogo():
    global jogo, prota
    nomeProta = str(input('DIGITE O NOME DO SEU PROTAGONISTA: '))
    prota = Protagonista(nomeProta)
    jogo = Jogo(prota)

def actionEnemie():
    #COMENTAR O ACONTECIDO
    pass

iniciarJogo()
    