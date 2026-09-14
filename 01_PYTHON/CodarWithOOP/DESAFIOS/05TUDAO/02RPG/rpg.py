from random import randint
from abc import ABC, abstractmethod

#Seria legal varias frases para cada ataque, por exemplo, varias frases de falha etc, ataques com criticos diferentes
#Da pra fazer algo muito legal

class Jogo:
    def __init__(self, nomeprota):
        global prota
        self.atacante = 'Jogador'
        self.turno = 1
        prota = Protagonista(nomeprota)
    pass

class Combatente(ABC):
    def __init__(self):
        self.vida = 10
        self.atq = 1

        self.vivo = True

        self.taxa = 5
        self.crit = 1.5
        self.dano = 0.0
        
        self.aura = 1000

    def danoCritico(self):

        self.num = randint(1, 101)

        if self.num <= self.taxa:
            print('DANO CRITICO!!!')
            self.dano = self.crit*self.atq
        elif self.num == 101:
            print('O atacante tentou atacar, acabou tropeçando em uma pedra, caiu de cara no chão, perdeu "10%" de vida e 100 de aura')
            self.vida -= self.vida*0.10
            self.aura -= 100
            self.dano = 0
        else:
            print('Dano normal')
            self.dano = self.atq

    @abstractmethod
    def curar(self):
        pass

    def atacar(self):
        pass

    def defender(self):
        pass

class Protagonista(Combatente):
    def __init__(self, nome:str = 'Prota'):
        super().__init__()
        self.nome = nome
        self.lvl = 1
        self.sp = 3
        self.vida = 10
        self.atq = 1

    def acao(self, num: int = 1):
        pass

    def atacar(self, inimigo):
        self.danoCritico()
        inimigo.vida -= self.dano
        if inimigo.vida <= 0:
            inimigo.morrer()

    def morrer(self):
        print('Voce morreu:(')
        re = int(input('Quer continuar?'))
        if re.upper() == 'S':
            pass
        else:
            print('Fim de jogo')

    def curar(self):
        pass

    def defender(self):
        pass

class Inimigo(Combatente):
    def __init__(self):
        super().__init__()
        self.nome = 'Inimigo'
        self.vida = 10
        self.atq = 1

    def atacar(self):
        self.danoCritico()
        prota.vida -= self.dano
        if prota.vida <= 0:
            prota.morrer()

    def curar(self):
        pass

    def defender(self):
        pass

    def morrer(self):
        print('O protagonista venceu')
        self.vivo = False
        pass
