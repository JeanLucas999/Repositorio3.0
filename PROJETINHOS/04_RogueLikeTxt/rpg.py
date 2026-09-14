from random import randint
from abc import ABC, abstractmethod

#Seria legal varias frases para cada ataque (Dependendo tambem da classe do inimigo), por exemplo, varias frases de falha etc, ataques com criticos diferentes e erros diferentes
#Da pra fazer algo muito legal

class Jogo:
    def __init__(self, objetoProta):
        global prota
        self.__turnoPlayer = True
        prota = objetoProta
        self.inimigoNovo()
        self.jogando = True

        while self.jogando:
            self.acaoAtual()

    def inimigoNovo(self):
        global inimigoAtual
        nomes = ['Aranha ', 'Goblin ', 'Paladino ', 'Leprechaum ', 'Urso ']
        complementos = ['Gigante', 'Bazukeiro', 'Demoniaco', 'Malabarista', 'Peludo', 'Lambedor', 'Foguento', 'Serio']
        self.decisao1 = randint(0, 4)
        self.decisao2 = randint(0, 7)
        self.nomeFeito = nomes[self.decisao1] + complementos[self.decisao2]
        print (f'Voce enfrentara um(a) {self.nomeFeito}')
        inimigoAtual = Inimigo(self.nomeFeito)
        pass

    def acaoAtual(self):
        if self.__turnoPlayer:
            self.rodando = True

            while self.rodando:
                self.__turnoPlayer = False

                acao = int(input('O que deseja fazer?\n1- Atacar\n2- Defender\n3- Curar\nNUMERO: '))

                try:
                    if 0 < acao < 4:

                        #varias acoes diferentes para cada uma
                        if acao == 1:
                            prota.atacar()
                        if acao == 2:
                            prota.defender()
                        if acao == 3:
                            prota.curar()

                    else:
                        raise ValueError
                    
                except ValueError:
                    print('Numero invalido, tente novamente')
        else:
            #Turno inimigo, randint com porcentagens diferentes para cada caso, tipo se tiver com pouca vida preferir curar ou defender etc
            #Defender pode ter chance de contra ataque
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

    def atacar(self):
        self.danoCritico()
        inimigoAtual.vida -= self.dano
        if inimigoAtual.vida <= 0:
            inimigoAtual.morrer()

    def morrer(self):
        print('Voce morreu :(')
        re = int(input('Quer continuar?'))
        if re.upper() == 'S':
            #Resetar Jogo
            #Eh um roguelike.
            #Contador de inimigos mortos
            #Sistema de buffs para novas jogadas
            #Preciso salvar para continuar
            #Botao de novo save
            pass
        else:
            print('Fim de jogo')

    def curar(self):
        pass

    def defender(self):
        pass

class Inimigo(Combatente):
    def __init__(self, nome):
        super().__init__()
        self.nome = nome
        self.vida = 10
        self.atq = 1

    def atacar(self):
        #COMENTAR O ACONTECIDO
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

#Uma classe filha para cada inimigo