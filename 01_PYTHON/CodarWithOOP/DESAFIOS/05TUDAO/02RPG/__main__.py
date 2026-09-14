from rpg import *

def iniciarJogo():
    global Prota
    nomeProta = str(input('DIGITE O NOME DO SEU PROTAGONISTA: '))
    jogo = Jogo(nomeProta)

#ACAO DO PLAYER E INIMIGO
def actionPlayer():
    #MENU
    pass

def actionEnemie():
    #COMENTAR O ACONTECIDO
    pass

def main():
    iniciarJogo()
    Inimigo1 = Inimigo()
    print(Inimigo1.vida)
    print(Inimigo1.nome)
    Inimigo1.atacar()



if __name__ == '__main__':
    main()