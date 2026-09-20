from random import randint
from abc import ABC, abstractmethod
from time import sleep

#Seria legal varias frases para cada ataque (Dependendo tambem da classe do inimigo), por exemplo, varias frases de falha etc, ataques com criticos diferentes e erros diferentes
#Da pra fazer algo muito legal

def iniciarJogo():
    global jogo
    nomeProta = str(input('DIGITE O NOME DO SEU PROTAGONISTA: '))
    protafake = Protagonista(nomeProta)
    jogo = Jogo(protafake)

def linha():
    print('-'*40)

class Jogo:
    def __init__(self, objetoProta):
        #Ainda preciso do menu de batalha
        #Uma forma de balancear os monstros
        global prota

        self.__turnoPlayer = True
        self.turno = 1

        prota = objetoProta
        self.inimigoNovo()

        self.jogando = True

        self.chamber = 1

        self.menuBatalha()

    def menuBatalha(self):
        while self.jogando:
            #Boss a cada 10 Câmaras
            print(f'Câmara: {self.chamber}')
            linha()
            print(f'{inimigoAtual.nome} LVL {inimigoAtual.lvl}\nVida: {inimigoAtual.vida}|{inimigoAtual.vida * 100 / inimigoAtual.vidaMax}% Aura: {inimigoAtual.aura} Atq:{inimigoAtual.atq} Vel: {inimigoAtual.speed}')

            linha()
            print(f'{prota.nome} LVL {prota.lvl}\nVida: {prota.vida}|{prota.vida * 100 / prota.vidaMax}% Aura: {prota.aura} Atq:{prota.atq} Vel: {prota.speed}')
            linha()

            sleep(2)

            self.acaoAtual()

    def inimigoNovo(self):
        global inimigoAtual
        nomes = ['Aranha ', 'Goblin ', 'Paladino ', 'Leprechaum ', 'Urso ']
        complementos = ['Gigante', 'Bazukeiro', 'Demoniaco', 'Malabarista', 'Peludo', 'Lambedor', 'Foguento', 'Serio']
        self.decisao1 = randint(0, 4)
        self.decisao2 = randint(0, 7)
        self.nomeFeito = nomes[self.decisao1] + complementos[self.decisao2]
        print (f'Voce enfrentara um(a) {self.nomeFeito}\n')
        sleep(2)
        inimigoAtual = Inimigo(self.nomeFeito)
        pass

    def acaoAtual(self):
        if self.__turnoPlayer:
            self.rodando = True

            while self.rodando:
                self.__turnoPlayer = False

                acao = int(input('1- Atacar  2- Defender  3- Curar: '))

                try:
                    if 0 < acao < 4:

                        #varias acoes diferentes para cada uma
                        if acao == 1:
                            prota.atacar()
                        elif acao == 2:
                            prota.defender()
                        elif acao == 3:
                            prota.curar()
                        self.turno += 1

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
        self.vida = 50
        self.vidaMax = self.vida
        self.atq = 10

        self.vivo = True

        self.aura = 100
        self.speed = 25
        self.taxa = 5
        self.crit = 1.5
        self.dano = 0.0
        self.dado6 = 1

    def girarDado(self):
        self.dado6 = randint(1,6)

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
        #CLASSES COM STATS DIFERENTES
        super().__init__()
        self.nome = nome
        self.vidaMax = self.vida
        self.lvl = 1
        self.sp = 3

    def decidirStats(self):
        linha()
        print(f'PONTOS DISPONIVEIS: {self.sp}')
        print(f'O que deseja upar?')
        linha()
        while self.sp != 0 or self.erro == True:
            upar = int(input(f'1- VIDA: {self.vida} + 10\n2- ATAQUE: {self.atq} + 2\n3- TAXA {self.taxa}% + 1%\n4- VELOCIDADE {self.speed} + 5\n Escolha'))
            if 0 < upar > 6:
                self.erro = False
                self.sp -= 1
                #if de cada
            else:
                print('Digite um número valido!')
                self.erro == True
        pass

    def atacar(self):
        self.danoCritico()
        inimigoAtual.vida -= self.dano
        if inimigoAtual.vida <= 0:
            inimigoAtual.morrer()

    def morrer(self):
        print('Voce morreu :(')
        re = int(input('Quer continuar?'))
        if re.upper() == 'S':
            #Uma roleta para tentar reviver kkkkk

            #Drop de item
            #Resetar Jogo
            #Eh um roguelike.
            #Contador de inimigos mortos
            #Sistema de buffs para novas jogadas
            #Preciso salvar apenas as informacoes que continuam com a morte para continuar(Upgrades e ultima sala alcancada)
            #Botao de novo save
            #Dificuldade procedural de acordo com a room
            pass
        else:
            print('Fim de jogo')

    def curar(self):
        #90% de curar 10% de vida
        #50% de curar 25%
        #10% de curar 100%
        pass

    def defender(self):
        #80% de defender um golpe fisico
        #30% tentativa de parry(stunna inimigo 1 rodada)
        pass



class Inimigo(Combatente):
    def __init__(self, nome):
        super().__init__()
        self.nome = nome
        self.vidaMax = self.vida
        self.decidirStats()

    def decidirStats(self):
        self.girarDado()

        if self.dado6 == 3:
            self.lvl = prota.lvl

        elif self.dado6 > 3:
            self.lvl = prota.lvl + randint(1,3)

        else:
            if prota.lvl > 3:
                self.lvl = prota.lvl - randint(1,3)
            else:
                self.lvl = prota.lvl
        #Depois disso aqui tem que puxar um metodo nos inimigos filhos, para decidir os stats deles baseado no tipo de cada um
        #Chances de colocar mais de cada stat diferente pra cada classe

    def atacar(self):
        #super().metodoPai() Puxa o metodo pai e pode sobrescrever a vontade sem perder nada
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