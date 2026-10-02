from random import randint
from abc import ABC, abstractmethod
from time import sleep

from ataques import listaAtaques, listaCuras, listaDefesas

#Seria legal varias frases para cada ataque (Dependendo tambem da classe do inimigo), por exemplo, varias frases de falha etc, ataques com criticos diferentes e erros diferentes
#Da pra fazer algo muito legal
#Sistema de energia para balancear mais


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

        #self.__jogadaPlayer = True
        self.turno = 1

        prota = objetoProta
        self.inimigoNovo()

        self.fimClick = False
        
        self.jogando = True

        self.chamber = 1

        self.porcProta = prota.vida/prota.vidaMax

        self.porcInimigo = inimigoAtual.vida/inimigoAtual.vidaMax

        self.batalhas()


    def menuBatalha(self):
        #Boss a cada 10 Câmaras
        print(f'Câmara: {self.chamber}')
        linha()
        print(f'{inimigoAtual.nome} LVL {inimigoAtual.lvl}\nVida: {inimigoAtual.vida}/{inimigoAtual.vidaMax}|{inimigoAtual.vida * 100 / inimigoAtual.vidaMax}% Aura: {inimigoAtual.aura} Atq:{inimigoAtual.atq} Vel: {inimigoAtual.speed}')

        linha()
        print(f'{prota.nome} LVL {prota.lvl}\nVida: {prota.vida}/{prota.vidaMax}|{prota.vida * 100 / prota.vidaMax}% Aura: {prota.aura} Atq:{prota.atq} Vel: {prota.speed}')
        linha()

        sleep(2)

    def inimigoNovo(self):
        global inimigoAtual
        nomes = ['Aranha ', 'Goblin ', 'Paladino ', 'Leprechaum ', 'Urso ']
        complementos = ['Gigante', 'Bazukeiro', 'Demoniaco', 'Malabarista', 'Peludo', 'Lambedor', 'Foguento', 'Serio']
        self.decisao1 = randint(0, len(nomes)-1)
        self.decisao2 = randint(0, len(complementos)-1)

        #Da pra fazer ataques diferentes por complemento dentro da classe inimigo, a classe pode receber o self.complemento alem do nome e com isso ter alguns ataques diferentes, uma classe para cada, cada complemento tem buff nos stats

        self.nomeFeito = nomes[self.decisao1] + complementos[self.decisao2]
        print (f'Voce enfrentara um(a) {self.nomeFeito}\n')
        sleep(2)

        #if pelo decisao 1
        inimigoAtual = Aranha(self.nomeFeito, self.decisao1, self.decisao2)
        #Classe do inimigo no lugar do inimigo, if para cada indice do nomes
        pass



    def acaoPlayer(self, movDecidida, acaoDecidida):
        #Preciso de algo para mov de prioridade
        #Talvez mandar para a decidirOrdem um parametro bool que o muda o self.vezPlayer
        #Pode ter maneiras melhores

        if movDecidida == 1:
            prota.atacar()
        elif movDecidida == 2:
            prota.defender()
        elif movDecidida == 3:
            prota.curar(acaoDecidida)
        pass

    def acaoInimigo(self):
        self.porcProta = prota.vida/prota.vidaMax

        self.porcInimigo = inimigoAtual.vida/inimigoAtual.vidaMax

        #Turno inimigo, randint com porcentagens diferentes para cada caso, tipo se tiver com pouca vida preferir curar ou defender etc
        #Defender pode ter chance de contra ataque
        #A ia tambem deveria pensar dependendo da speed
        #escolha do inimigo
        #Se for lerdo eh uma boa usar algo com prioridade
        #Tambem deve levar em consideracao a vida do prota
        #Usar cura seguida para isso

        dadoEscolha = randint(1, 100)

        if self.porcInimigo >= 0.8:
            inimigoAtual.atacar()

        elif 0.8 > self.porcInimigo > 0.5:
            if dadoEscolha <= 75 or self.porcProta <= 0.15:
                inimigoAtual.atacar()
            else:
                inimigoAtual.curar()

        elif 0.25 >= self.porcInimigo <= 0.5:
            if dadoEscolha <= 50 and self.porcProta >= 0.15:
                #Deve ter chances diferentes para cada tipo de cura
                inimigoAtual.curar()
            else:
                inimigoAtual.atacar()

        else:
            if dadoEscolha <=75:
                inimigoAtual.curar()
            else:
                inimigoAtual.atacar()

    def decidirOrdem(self, movimento, acao, prioridade:str = 'nao'):
        #Decidir ordem de movimento
        #Precisa de um parametro tipo prioridade player que muda o self.vezPlayer, facin facin
        #str deve ser player ou inimigo
        self.vezPlayer = None
        self.prioridade = prioridade

        if self.prioridade == 'nao':
            if prota.speed > inimigoAtual.speed:
                #Se a velocidade do prota for maior
                self.vezPlayer = True

            elif inimigoAtual.speed > prota.speed:
                #Se for menor
                self.vezPlayer = False
            
            else:
                #Se forem iguais
                prota.girarDado()

                if prota.dado6 > 3:
                    self.vezPlayer = True

                else:
                    self.vezPlayer = False

        if self.prioridade == 'player':
            self.vezPlayer = True
        elif self.prioridade == 'inimigo':
            self.vezPlayer = False
        

        if self.vezPlayer:
            self.acaoPlayer(movimento, acao)
            if inimigoAtual.vivo:
                self.acaoInimigo()

        if not self.vezPlayer:
            self.acaoInimigo()
            if prota.vivo:
                self.acaoPlayer(movimento, acao)



    def batalhas(self):
        #OR ERRO?
            while prota.vivo and inimigoAtual.vivo:
                self.menuBatalha()
                movimento = int(input('1- Atacar  2- Defender  3- Curar: '))
                try:
                    if 0 < movimento < 4:
                        if movimento == 1:
                            self.fimClick = False
                            self.decidirOrdem(movimento, 0)
                            pass

                        if movimento == 2:
                            self.fimClick = False
                            pass

                        if movimento == 3:
                            self.fimClick = False
                            while not self.fimClick:
                                self.curaEscolhida = int(input(f'1- Cura Simples: {listaCuras[0]['desc']} \n 2- Cura Media: {listaCuras[1]['desc']}\n  3- Cura Avançada: {listaCuras[1]['desc']}\nEscolha: '))
                                if 0 < self.curaEscolhida < 4:
                                    self.fimClick = True
                                self.decidirOrdem(movimento, self.curaEscolhida)

                        self.turno += 1
                    else:
                        raise ValueError
                except ValueError:
                    print('Numero invalido, tente novamente')







class Combatente(ABC):
    def __init__(self):
        #Preciso de status absolutos, tipo, o self.dano nao deve ser o que vai bater, mas sim apenas o que vai ser multiplicado para descobrir o que vai bater, talvez nao
        #talvez seja apenas colocar um * depois do self.atq

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
        self.curasSeguidas = 0

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
        self.curasSeguidas = 0
        self.danoCritico()
        inimigoAtual.vida -= self.dano
        if inimigoAtual.vida <= 0:
            inimigoAtual.morrer()

    def morrer(self):
        prota.vivo = False
        print('Voce morreu :(')
        re = str(input('Quer continuar?'))
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

    def curar(self, curaEscolhida):
        #curas seguidas diminuem a proxima chance de acerto
        #20% a menos de chance de acerto por cura seguida
        dado = randint(0, 100)
        self.curaDecidida = curaEscolhida -1

        if dado <= listaCuras[self.curaDecidida]['chance']-self.curasSeguidas*20:
            #if texto = -1: texto = 0
            texto = randint(0, len(listaCuras[self.curaDecidida]['acerto'])-1)
            if texto == -1: texto = 0
            print(f'{self.nome} {listaCuras[self.curaDecidida]['acerto'][texto]}')
            self.vida += self.vidaMax*listaCuras[self.curaDecidida]['vida']/100
        else:
            texto = randint(0, len(listaCuras[self.curaDecidida]['erro'])-1)
            if texto == -1: texto = 0
            print(f'{self.nome} {listaCuras[self.curaDecidida]['erro'][texto]}')
            
        if self.vida>self.vidaMax:
            #SE PASSAR DE 100%
            self.vida = self.vidaMax

        self.curasSeguidas += 1

    def defender(self):
        #defesa tambem
        #80% de defender um golpe fisico
        #30% tentativa de parry(stunna inimigo 1 rodada)
        pass






class Inimigo(Combatente):
    def __init__(self):
        super().__init__()
        self.vidaMax = self.vida
        self.decidirStats()

    def decidirStats(self):
        #GIRAR DADO PARA DECIDIR LVL DO INIMIGO
        self.girarDado()

        if self.dado6 == 3 or self.dado6 == 4:
            self.lvl = prota.lvl

        elif self.dado6 > 4:
            self.lvl = prota.lvl + randint(1,3)

        else:
            if prota.lvl > 3:
                self.lvl = prota.lvl - randint(1,3)
            else:
                self.lvl = prota.lvl
        #Depois disso aqui tem que puxar um metodo nos inimigos filhos, para decidir os stats deles baseado no tipo de cada um
        #super.decidirStats
        #Chances de colocar mais de cada stat diferente pra cada classe

    def atacar(self):
        self.curasSeguidas = 0
        #super().metodoPai() Puxa o metodo pai e pode sobrescrever a vontade sem perder nada
        #COMENTAR O ACONTECIDO
        self.danoCritico()
        prota.vida -= self.dano
        if prota.vida <= 0:
            prota.morrer()

    def curar(self):
        cura = randint(0, 1)
        texto = randint(0, 2)
        dado = randint(1, 100)
        
        if dado <= listaCuras[cura]['chance']-self.curasSeguidas*20:
            texto = randint(0, len(listaCuras[cura]['acerto'])-1)
            if texto == -1: texto = 0
            print(f'{self.nome} {listaCuras[cura]['acerto'][texto]}')
            self.vida += self.vidaMax*listaCuras[cura]['vida']/100
        else:
            texto = randint(0, len(listaCuras[cura]['erro'])-1)
            if texto == -1: texto = 0
            print(f'{self.nome} {listaCuras[cura]['erro'][texto]}')

        if self.vida>self.vidaMax:
            #SE PASSAR DE 100%
            self.vida = self.vidaMax

        self.curasSeguidas += 1

    def defender(self):
        pass

    def morrer(self):
        print('O protagonista venceu')
        self.vivo = False
        pass

class Aranha(Inimigo):
    def __init__(self, nome, base, comp):
        super().__init__()
        self.nome = nome
        self.base = base
        self.complemento = comp

    def atacar(self):
        super().atacar()
        print('ataquei')
#Uma classe filha para cada inimigo
