from random import randint
from abc import ABC, abstractmethod
from time import sleep
from math import floor
import json

from ataques import listaAtaques, listaCuras, listaDefesas
from funcoes import *

#Seria legal varias frases para cada ataque (Dependendo tambem da classe do inimigo), por exemplo, varias frases de falha etc, ataques com criticos diferentes e erros diferentes
#Da pra fazer algo muito legal
#Sistema de energia para balancear mais


def iniciarJogo():
    global jogo
    resposta = 0
    erro = False
    temSave = False
    linha()
    print('Continuar ou criar um novo save?')

    
    while erro or resposta == 0:
        try:
            resposta = int(input('1- Continuar\n2- Criar novo save\n3- Apagar save\nEscolha: '))
            if resposta == 1:
                erro = False
                temSave = False

                #Ler saves
                with open('PROJETINHOS/04_RogueLikeTxt/saves.json', 'r', encoding='utf-8') as arq:
                    personagens = json.load(arq)

                    #Verificar se tem saves
                    for c in personagens['geral']:
                        if c['usado']:
                            temSave = True

                    #Se tiver, mostrar eles e depois fazer a escolha de um
                    if temSave:
                        print('for2')

                        for i, c in enumerate(personagens['geral']):
                            if c['usado']:
                                print(f'{i+1}- {c['nome']}, maior camara alcançada:{c['camaraMaxima']}')

                        escolhaSave = int(input('Escolha um save(0 PARA VOLTAR): '))
                        if escolhaSave == 0:
                            #Erro para voltar pro menu inicial 
                            erro = True

                        elif personagens['geral'][escolhaSave-1]['usado']:
                            print('ok')

                        else:
                            raise ValueError

                    #Senao, subir o erro e voltar pro inicio
                    else:
                        print('Voce ainda nao possui saves')
                        sleep(1)

                        erro = True

            elif resposta == 2:
                erro = False
                certeza = False

                with open('PROJETINHOS/04_RogueLikeTxt/saves.json', 'r', encoding='utf-8') as arq:

                    personagens = json.load(arq)
        
                    while not certeza:
                        try:
                            print('Onde quer colocar seu novo save? ')

                            for i, c in enumerate(personagens['geral']):
                                print(f'{i+1}- {c['nome']}, maior camara alcançada:{c['camaraMaxima']}')
                            novoSave = int(input('Escolha(0 PARA VOLTAR): '))

                            if 0 < novoSave < 4:
                                #cria o save por cima do que tem
                                try:
                                    respostaCerteza = input(f'VOCÊ TEM CERTEZA QUE DESEJA APAGAR O SAVE {novoSave}- {personagens['geral'][novoSave]['nome']} [S/N] ')

                                    if respostaCerteza.upper() == 'S':
                                        certeza = True
                                        nomeProta = str(input('DIGITE O NOME DO SEU PROTAGONISTA: '))
                                        resetSave(novoSave, nomeProta)
                                        protafake = Protagonista(nomeProta)
                                        jogo = Jogo(protafake)

                                    elif respostaCerteza.upper() == 'N':
                                        certeza = False
                                        print('Voltando e apagando texto')

                                    else:
                                        raise KeyError
                                    
                                except KeyError:
                                    print('DIGITE UM VALOR VALIDO!!!') 

                            elif novoSave == 0:
                                erro = True

                            else: raise ValueError

                        except ValueError:
                            print('DIGITE UM NUMERO VALIDO!!!')

                        
                        

                #criar o save

            elif resposta == 3:
                #erro = True para voltar pro menu sempre
                erro = True
                certeza = False
                temSave = False
                certeza = False



                with open('PROJETINHOS/04_RogueLikeTxt/saves.json', 'r', encoding='utf-8') as arq:
                    personagens = json.load(arq)
                    for c in personagens['geral']:
                        if c['usado']:
                            temSave = True

                    if temSave:
                        print('Qual save deseja apagar?')

                        while not certeza:
                            for i, c in enumerate(personagens['geral']):
                                print(f'{i+1}- {c['nome']}, maior camara alcançada:{c['camaraMaxima']}')

                            apagarSave = int(input('Escolha(0 PARA VOLTAR): '))

                            if 0 < apagarSave < 4:
                                try:
                                    respostaCerteza = input(f'VOCÊ TEM CERTEZA QUE DESEJA APAGAR O SAVE {novoSave}- {personagens['geral'][apagarSave]['nome']} [S/N] ')

                                    if respostaCerteza.upper() == 'S':
                                        certeza = True
                                        resetSave(apagarSave, '', True)

                                    elif respostaCerteza.upper() == 'N':
                                        certeza = False
                                        print('Voltando e apagando texto')

                                    else:
                                        raise KeyError

                                    if personagens['geral'][apagarSave]['usado']:
                                        resetSave(apagarSave, '', True)
                                        
                                    else:
                                        print('Personagem não existe!!!')

                                except KeyError:
                                    print('DIGITE UM VALOR VALIDO')
                    else:
                        print('AINDA NAO EXISTEM SAVES')
            else:
                raise ValueError
                
        except ValueError:
            erro = True

            print('Digite um numero presente!!!')

        #except TypeError:
            #erro = True

            #print('Digite um numero!!!')


def resetSave(numRecebido=0, nomeProta='', apagar:bool = False):
    with open('PROJETINHOS/04_RogueLikeTxt/saves.json', 'r+', encoding='utf-8') as arq:
        personagens = json.load(arq)

        numArrumado = numRecebido-1
        if apagar == False:
            personagens['geral'][numArrumado]['nome'] = nomeProta
            personagens['geral'][numArrumado]['camaraMaxima'] = 0
            personagens['geral'][numArrumado]['upgrades'] = []
            personagens['geral'][numArrumado]['usado'] = True

        if apagar == True:
            personagens['geral'][numArrumado]['nome'] = 'Inexistente'
            personagens['geral'][numArrumado]['camaraMaxima'] = 0
            personagens['geral'][numArrumado]['upgrades'] = []
            personagens['geral'][numArrumado]['usado'] = False

        arq.seek(0) #VOLTA O CURSOR PARA PRIMEIRA LINHA
        json.dump(personagens, arq, indent=4, ensure_ascii=False)
        arq.truncate() #APAGA SOBRAS


class Jogo:
    def __init__(self, objetoProta, camaraMaxima:int = 0, upgrades:list = []):
        #Ainda preciso do menu de batalha
        #Uma forma de balancear os monstros
        global prota

        #self.__jogadaPlayer = True
        self.turno = 1

        prota = objetoProta

        self.chamber = 1

        prota.lvlUp()
        
        self.inimigoNovo()

        self.fimClick = False
        
        self.jogando = True

        self.porcProta = prota.vida/prota.vidaMax

        self.porcInimigo = inimigoAtual.vida/inimigoAtual.vidaMax

        self.batalhas()


    def menuBatalha(self):
        #Boss a cada 10 Câmaras

        print(f'Câmara: {self.chamber}')
        linha()
        print(f'{blackBg}{redTxt}{inimigoAtual.nome} LVL {inimigoAtual.lvl}{fecharcor}\n{greenTxt}{blackBg}Vida: {inimigoAtual.vida}/{inimigoAtual.vidaMax}|{inimigoAtual.vida * 100 / inimigoAtual.vidaMax:.0f}%{fecharcor}{blackBg} {purpleTxt}Atq:{inimigoAtual.atq}{fecharcor}{blackBg} {blueTxt}Vel: {inimigoAtual.speed}{fecharcor}')

        linha()
        print(f'{blackBg}{blueTxt}{prota.nome.capitalize()} LVL {prota.lvl}{fecharcor}\n{blackBg}{greenTxt}Vida: {prota.vida}/{prota.vidaMax}|{prota.vida * 100 / prota.vidaMax:.0f}% {fecharcor}{blackBg}{purpleTxt}Atq:{prota.atq}{fecharcor}{blackBg}{blueTxt} Vel: {prota.speed}{fecharcor}')
        linha()

        sleep(1)

    def inimigoNovo(self):
        global inimigoAtual
        nomes = ['Aranha ', 'Goblin ', 'Paladino ', 'Leprechaum ', 'Urso ']
        complementos = ['Gigante', 'Bazukeiro', 'Demoniaco', 'Malabarista', 'Peludo', 'Lambedor', 'Foguento', 'Serio']
        self.decisao1 = randint(0, len(nomes)-1)
        self.decisao2 = randint(0, len(complementos)-1)

        #Da pra fazer ataques diferentes por complemento dentro da classe inimigo, a classe pode receber o self.complemento alem do nome e com isso ter alguns ataques diferentes, uma classe para cada, cada complemento tem buff nos stats

        self.nomeFeito = nomes[self.decisao1] + complementos[self.decisao2]
        print (f'{redBg}{blackTxt}  Voce enfrentara um(a) {self.nomeFeito}  {fecharcor}')
        sleep(2)

        if self.decisao1 == 0:
            inimigoAtual = Aranha(self.nomeFeito, self.decisao1, self.decisao2, self.chamber)
            print('Criei aranha')

        elif self.decisao1 == 1:
            inimigoAtual = Aranha(self.nomeFeito, self.decisao1, self.decisao2, self.chamber)
            print('Criei goblin')


        elif self.decisao1 == 2:
            inimigoAtual = Aranha(self.nomeFeito, self.decisao1, self.decisao2, self.chamber)
            print('Criei Paladino')


        elif self.decisao1 == 3:
            inimigoAtual = Aranha(self.nomeFeito, self.decisao1, self.decisao2, self.chamber)
            print('Criei Leprechaum')


        else:
            inimigoAtual = Aranha(self.nomeFeito, self.decisao1, self.decisao2, self.chamber)
            print('Criei urso')



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

        #escolha do inimigo

        dadoEscolha = randint(1, 100)

        if self.porcInimigo >= 0.8:
            inimigoAtual.atacar()

        elif 0.8 > self.porcInimigo > 0.5:
            if dadoEscolha <= 75 or self.porcProta <= 0.15:
                inimigoAtual.atacar()
            else:
                inimigoAtual.curar()

        elif 0.20 >= self.porcInimigo <= 0.5:
            if dadoEscolha <= 50 and self.porcProta >= 0.2:
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
        selecionado = False
        while prota.vivo and inimigoAtual.vivo:
            selecionado = False
            
            self.menuBatalha()
            try:
                movimento = int(input('1- Atacar  2- Defender  3- Curar: '))

                if 0 < movimento < 4:
                    if movimento == 1:
                        self.decidirOrdem(movimento, 0)
                        selecionado = True

                    if movimento == 2:
                        selecionado = True

                    if movimento == 3:
                        while not selecionado:
                            linha()
                            print(f'{redTxt}{blackBg}A CADA CURA SEGUIDA VOCÊ TEM MAIS CHANCE DE ERRAR!!!.{fecharcor}')
                            print(f'{redTxt}{blackBg}{prota.curasSeguidas*20}% A MAIS DE CHANCE DE ERRO!!!{fecharcor}')
                            self.curaEscolhida = int(input(f'{yellowTxt}1- {greenTxt}Cura Simples:{fecharcor} {listaCuras[0]['desc']} \n{yellowTxt}2- {greenTxt}Cura Media:{fecharcor} {listaCuras[1]['desc']}\n{yellowTxt}3- {greenTxt}Cura Avançada:{fecharcor} {listaCuras[1]['desc']}\n{yellowTxt}4- {redTxt}Voltar{fecharcor}\nEscolha: '))

                            if 0 < self.curaEscolhida < 4:
                                selecionado = True
                                self.decidirOrdem(movimento, self.curaEscolhida)

                            elif self.curaEscolhida == 4:
                                limparTela()
                                break
                            

                    self.turno += 1

                else:
                    raise ValueError

            except ValueError:
                print('Numero invalido, tente novamente')

            if not inimigoAtual.vivo:
                prota.novaChamber()
                prota.xpUp()

                self.chamber += 1
                self.inimigoNovo()








class Combatente(ABC):
    def __init__(self):
        #Preciso de status absolutos, tipo, o self.dano nao deve ser o que vai bater, mas sim apenas o que vai ser multiplicado para descobrir o que vai bater, talvez nao
        #talvez seja apenas colocar um * depois do self.atq

        self.vida = 50
        self.vidaMax = self.vida

        self.atq = 10
        self.atqMax = self.atq

        self.speed = 25
        self.speedMax = self.speed

        self.vivo = True

        self.aura = 100

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

    def upHp(self):
        self.vida += 5
        self.vidaMax = self.vida

    def upAtq(self):
        self.atq += 1
        self.atqMax = self.atq

    def upSpeed(self):
        self.speed += 5
        self.speedMax = self.speed

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
        self.atq = 1000
        self.vidaMax = self.vida
        self.atqMax = self.atq
        self.speedMax = self.speed
        self.lvl = 0
        self.sp = 0
        self.xp = 0
        self.erro = None

    def skillMenu(self):
        print(f'{purpleTxt}{whiteBg}             Skill Points:{self.sp}             {fecharcor}')
        print(f'{purpleTxt}{whiteBg}           O que deseja upar?           {fecharcor}')
        linha()

    def lvlUp(self):
        self.lvl += 1
        self.sp += 3
        self.skillMenu()
        while self.sp != 0 or self.erro == True:
            upar = int(input(f'{yellowTxt}1- {greenTxt}VIDA: {self.vida}{fecharcor} + 5\n{yellowTxt}2- {redTxt}ATAQUE: {self.atq}{fecharcor} + 1\n{yellowTxt}3- {blueTxt}VELOCIDADE {self.speed}{fecharcor} + 5\nEscolha: '))
            if 0 < upar < 4:
                self.erro = False
                self.sp -= 1
                if upar == 1:
                    self.upHp()

                elif upar == 2:
                    self.upAtq()

                elif upar == 3:
                    self.upSpeed()

                limparTela()

                if self.sp > 0:
                    self.skillMenu()
            else:
                print('Digite um número valido!')
                self.erro == True

    def xpUp(self):
        #25% de xp a mais se o inimigo for lvl menor
        #50% se tiverem os lvls iguais
        #100% se o inimigo tiver lvl maior
        #Precisa balancear

        if inimigoAtual.lvl > self.lvl: self.xp += 50

        elif inimigoAtual.lvl == self.lvl: self.xp += 75

        elif inimigoAtual.lvl < self.lvl: self.xp += 100

        while self.xp >= 100:
            self.xp -= 100
            self.lvlUp()
        

    def atacar(self):
        self.curasSeguidas = 0
        self.danoCritico()
        inimigoAtual.vida -= self.dano
        if inimigoAtual.vida <= 0:
            inimigoAtual.morrer()

    def novaChamber(self):
        self.vida = self.vidaMax
        self.atq = self.atqMax
        self.speed = self.speedMax

    def morrer(self):
        prota.vivo = False
        sleep(1)
        limparTela()
        print(f'{blackBg}{redTxt}Voce morreu :({fecharcor}')
        sleep(1)

        re = str(input(f'{blueTxt}Quer continuar?{fecharcor} [{greenTxt}S{fecharcor}/{redTxt}N{fecharcor}]: '))
        if re.upper() == 'S':
            iniciarJogo()
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

            self.curasSeguidas += 1
        else:
            texto = randint(0, len(listaCuras[self.curaDecidida]['erro'])-1)
            if texto == -1: texto = 0
            print(f'{self.nome} {listaCuras[self.curaDecidida]['erro'][texto]}')

            self.curasSeguidas = 0
            
        if self.vida>self.vidaMax:
            #SE PASSAR DE 100%
            self.vida = self.vidaMax

        

    def defender(self):
        self.curasSeguidas = 0
        #defesa tambem
        #80% de defender um golpe fisico
        #30% tentativa de parry(stunna inimigo 1 rodada)
        pass






class Inimigo(Combatente):
    def __init__(self):
        super().__init__()
        self.vidaMax = self.vida
        self.atqMax = self.atq
        self.speedMax = self.speed
        self.lvlBaseado = 0
        self.decidirLvl()
        self.sp = self.lvl*3
        self.decidirStats()

    def decidirLvl(self):
        self.girarDado()

        #Level baseado na chamber ou no prota msm, depende de quem for maior
        print('CAMARA ANTES DE ESCOLHER LVL: ', self.chamber)
        if prota.lvl > self.chamber:
            self.lvlBaseado = prota.lvl
        else:
            self.lvlBaseado = self.chamber


        if self.dado6 == 3 or self.dado6 == 4:
            self.lvl = self.lvlBaseado

        elif self.dado6 > 4:
            self.lvl = self.lvlBaseado + randint(1,3)*30/100

        else:
            self.lvl = self.lvlBaseado - self.lvlBaseado * randint(1,3)*10 / 100

        print('Lvl Antes: ', self.lvl)

        if self.lvl < 1: self.lvl = 1 

        print('Lvl Baseado:', self.lvlBaseado)
        self.lvl = floor(self.lvl)
        print('Lvl Depois: ', self.lvl)
        
        #Depois disso aqui tem que puxar um metodo nos inimigos filhos, para decidir os stats deles baseado no tipo de cada um
        #super.decidirStats
        #Chances de colocar mais de cada stat diferente pra cada classe

    def decidirStats(self):
        pass

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

            self.curasSeguidas += 1
        else:
            texto = randint(0, len(listaCuras[cura]['erro'])-1)
            if texto == -1: texto = 0
            print(f'{self.nome} {listaCuras[cura]['erro'][texto]}')

            self.curasSeguidas = 0

        if self.vida>self.vidaMax:
            #SE PASSAR DE 100%
            self.vida = self.vidaMax

    def defender(self):
        self.curasSeguidas = 0
        pass

    def morrer(self):
        print('O protagonista venceu')
        self.vivo = False
        pass

class Aranha(Inimigo):
    def __init__(self, nome, base, comp, chamber):
        self.nome = nome
        self.base = base
        self.complemento = comp
        self.chamber = chamber
        super().__init__()

    def atacar(self):
        super().atacar()
        print('ataquei')

    def decidirStats(self):
        c = 1
        dadoStats = randint(1,100)

        for c in range (1, self.sp+1):
            if c%3 == 0:
                self.upSpeed()
            else:
                if dadoStats < 51:
                    self.upAtq()
                else:
                    self.upHp()

                
            



#Uma classe filha para cada inimigo
