from random import randint, choice
from abc import ABC, abstractmethod
from time import sleep
from math import floor
from sys import stdout
from pathlib import Path
import json

from ataques import listaAtaques, listaCuras, listaDefesas
from funcoes import *

#Seria legal varias frases para cada ataque (Dependendo tambem da classe do inimigo), por exemplo, varias frases de falha etc, ataques com criticos diferentes e erros diferentes
#Da pra fazer algo muito legal
#Sistema de energia para balancear mais

def iniciarDebug():
    global jogo, debug
    debug = True
    protafake = Protagonista('Jean')
    jogo = Jogo(protafake)

def iniciarJogo():
    global jogo, debug, pasta, path

    pasta = Path(__file__).parent
    path = pasta / 'saves.json'

    debug = False
    resposta = 0
    erro = False
    temSave = False
    
    while erro or resposta == 0:
        try:
            linha(50)

            print(f'{BlueYellow}{'Continuar ou criar um novo save?':^50}{fecharcor}')
            resposta = int(input(f'{whiteBg}{'1- Continuar':^50}{fecharcor}\n{whiteBg}{'2- Criar novo save':^50}{fecharcor}\n{whiteBg}{'3- Apagar save':^50}{fecharcor}\nEscolha: '))

            limparTela()

            if resposta == 1:
                erro = False
                temSave = False

                #Ler saves
                with open(path, 'r', encoding='utf-8') as arq:
                    personagens = json.load(arq)

                    #Verificar se tem saves
                    for c in personagens['geral']:
                        if c['usado']:
                            temSave = True

                    #Se tiver, mostrar eles e depois fazer a escolha de um
                    if temSave:
                        linha(50)

                        print(f'{BlueYellow}{'Qual save deseja abrir?':^50}{fecharcor}')

                        for i, c in enumerate(personagens['geral']):
                            listarPersonagens = f'{c['nome']}, maior camara alcançada:{c['camaraMaxima']}'
                            print(f'{whiteBg}{i+1}- {listarPersonagens:^47}{fecharcor}')

                        escolhaSave = int(input('Escolha um save(0 PARA VOLTAR): '))

                        limparTela()

                        if escolhaSave == 0:
                            #Erro para voltar pro menu inicial 
                            erro = True

                        elif personagens['geral'][escolhaSave-1]['usado']:
                            print('ok')

                        else:
                            raise ValueError

                    #Senao, subir o erro e voltar pro inicio
                    else:
                        linha(50)
                        print(f'{BlackRed}{'AINDA NAO EXISTEM SAVES':^50}{fecharcor}')
                        sleep(1)

                        erro = True

            elif resposta == 2:
                erro = False
                certeza = False

                with open(path, 'r', encoding='utf-8') as arq:

                    personagens = json.load(arq)
        
                    while not certeza:
                        try:
                            linha(50)

                            print(f'{BlueYellow}{'Onde quer colocar seu novo save?':^50}{fecharcor}')

                            for i, c in enumerate(personagens['geral']):
                                listarPersonagens = f'{c['nome']}, maior camara alcançada:{c['camaraMaxima']}'
                                print(f'{whiteBg}{i+1}- {listarPersonagens:^47}{fecharcor}')
                            novoSave = int(input('Escolha(0 PARA VOLTAR): '))
                            limparTela()

                            if 0 < novoSave < 4:
                                #cria o save por cima do que tem
                                try:
                                    if personagens['geral'][novoSave-1]['usado']:
                                        respostaCerteza = input(f'VOCÊ TEM CERTEZA QUE DESEJA APAGAR O SAVE {novoSave}- {personagens['geral'][novoSave-1]['nome']} [S/N] ')

                                        if respostaCerteza.upper() == 'S':
                                            certeza = True
                                            nomeProta = str(input('DIGITE O NOME DO SEU PROTAGONISTA: '))
                                            limparTela()
                                            resetSave(novoSave, nomeProta)
                                            protafake = Protagonista(nomeProta)
                                            jogo = Jogo(protafake)

                                        elif respostaCerteza.upper() == 'N':
                                            certeza = False
                                            limparTela()
                                            print('Voltando e apagando texto')

                                        else:
                                            raise KeyError

                                    else:
                                        nomeProta = str(input('DIGITE O NOME DO SEU PROTAGONISTA: '))
                                        limparTela()
                                        resetSave(novoSave, nomeProta)
                                        protafake = Protagonista(nomeProta)
                                        jogo = Jogo(protafake)
                                    
                                except KeyError:
                                    linha()
                                    print(f'{redBg}{'DIGITE UM VALOR VALIDO!!!':^50}{fecharcor}') 

                            elif novoSave == 0:
                                erro = True
                                certeza = True

                            else: raise ValueError

                        except ValueError:
                            linha()
                            print(f'{redBg}{'DIGITE UM NUMERO VALIDO!!!':^50}{fecharcor}') 

                        
                        

                #criar o save

            elif resposta == 3:
                #erro = True para voltar pro menu sempre
                erro = True
                certeza = False
                temSave = False
                certeza = False



                with open(path, 'r', encoding='utf-8') as arq:
                    personagens = json.load(arq)
                    for c in personagens['geral']:
                        if c['usado']:
                            temSave = True

                    if temSave:
                        linha(50)

                        print(f'{redBg}{'Qual save deseja apagar?':^50}{fecharcor}')

                        while not certeza:
                            for i, c in enumerate(personagens['geral']):
                                listarPersonagens = f'{c['nome']}, maior camara alcançada:{c['camaraMaxima']}'
                                print(f'{whiteBg}{i+1}- {listarPersonagens:^47}{fecharcor}')

                            apagarSave = int(input('Escolha(0 PARA VOLTAR): '))
                            limparTela()

                            if 0 < apagarSave < 4:
                                try:
                                    if personagens['geral'][apagarSave-1]['usado']:
                                        respostaCerteza = input(f'VOCÊ TEM CERTEZA QUE DESEJA APAGAR O SAVE {apagarSave}- {personagens['geral'][apagarSave-1]['nome']} [S/N] ')

                                        if respostaCerteza.upper() == 'S':
                                            certeza = True
                                            resetSave(apagarSave, '', True)

                                        elif respostaCerteza.upper() == 'N':
                                            certeza = False
                                            print('Voltando e apagando texto')

                                        else:
                                            raise KeyError
                                    else:
                                        linha()
                                        print(f'{redBg}{'PERSONAGEM INEXISTENTE!!!':^50}{fecharcor}')

                                except KeyError:
                                    linha(50)
                                    print(f'{redBg}{'DIGITE UM VALOR VALIDO!!!':^50}{fecharcor}')
                            if apagarSave == 0:
                                certeza = True
                    else:
                        linha(50)
                        print(f'{BlackRed}{'AINDA NAO EXISTEM SAVES':^50}{fecharcor}')
                        sleep(1)
            else:
                raise ValueError
                
        except ValueError:
            erro = True

            linha(50)
            print(f'{redBg}{'DIGITE UM NUMERO VALIDO!!!':^50}{fecharcor}')

        #except TypeError:
            #erro = True

            #print('Digite um numero!!!')


def resetSave(numRecebido=0, nomeProta='', apagar:bool = False):
    with open(path, 'r+', encoding='utf-8') as arq:
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

        if debug:
            prota.vida = 1000
            prota.vidaMax = prota.vida
            prota.atq = 1000
            prota.atqMax = prota.atq

        self.chamber = 1
    
        prota.lvlUp(1)
        
        self.inimigoNovo()

        self.fimClick = False
        
        self.jogando = True

        self.porcProta = prota.vida/prota.vidaMax

        self.porcInimigo = inimigoAtual.vida/inimigoAtual.vidaMax

        self.batalhas()


    def inimigoNovo(self):
        global inimigoAtual
        nomes = ['Aranha ', 'Goblin ', 'Paladino ', 'Vampiro ', 'Urso ',]
        complementos = ['Gigante', 'Bazukeiro', 'Demoniaco', 'Malabarista', 'Peludo', 'Lambedor', 'Foguento', 'Serio', 'Fedorento', 'Dançarino', 'Sonolento', 'Mal-humorado', 'Raivoso', 'Faminto', 'Congelado', 'Invisivel', 'Cantor', 'Cabeludo', 'Desempregado','Filosofo', 'Bêbado', 'Anabolizado', 'Atrasado']
        self.decisao1 = randint(0, len(nomes)-1)
        self.decisao2 = randint(0, len(complementos)-1)

        #Da pra fazer ataques diferentes por complemento dentro da classe inimigo, a classe pode receber o self.complemento alem do nome e com isso ter alguns ataques diferentes, uma classe para cada, cada complemento tem buff nos stats

        self.nomeFeito = nomes[self.decisao1] + complementos[self.decisao2]
        camaraTxt = f'Camara: {self.chamber}'
        inimigoNovoTxt = f'Voce enfrentara um(a) {self.nomeFeito}'

        print(f'{whiteBg}{camaraTxt:^72}{fecharcor}')
        print (f'{redBg}{inimigoNovoTxt:^72}{fecharcor}')
        sleep(2)

        if self.decisao1 == 0:
            inimigoAtual = Aranha(self.nomeFeito, self.decisao1, self.decisao2, self.chamber)
            print('Criei aranha')

        elif self.decisao1 == 1:
            inimigoAtual = Goblin(self.nomeFeito, self.decisao1, self.decisao2, self.chamber)
            print('Criei goblin')


        elif self.decisao1 == 2:
            inimigoAtual = Paladino(self.nomeFeito, self.decisao1, self.decisao2, self.chamber)
            print('Criei Paladino')


        elif self.decisao1 == 3:
            inimigoAtual = Vampiro(self.nomeFeito, self.decisao1, self.decisao2, self.chamber)
            print('Criei Vampiro')


        else:
            inimigoAtual = Urso(self.nomeFeito, self.decisao1, self.decisao2, self.chamber)
            print('Criei urso')



    def acaoPlayer(self, movDecidido, acaoDecidida):
        #Preciso de algo para mov de prioridade
        #Talvez mandar para a decidirOrdem um parametro bool que o muda o self.vezPlayer
        #Pode ter maneiras melhores

        if movDecidido == 1:
            prota.atacar(acaoDecidida)
        elif movDecidido == 2:
            prota.defender()
        elif movDecidido == 3:
            prota.curar(acaoDecidida)
        pass

    def acaoInimigo(self):
        self.porcProta = prota.vida/prota.vidaMax

        self.porcInimigo = inimigoAtual.vida/inimigoAtual.vidaMax

        self.atqInimigo = randint(0, len(inimigoAtual.ataques)-1)
        #escolha do inimigo

        dadoEscolha = randint(1, 100)

        if self.porcInimigo >= 0.8:
            inimigoAtual.atacar(self.atqInimigo)

        elif 0.8 > self.porcInimigo > 0.5:
            if dadoEscolha <= 75 or self.porcProta <= 0.15:
                inimigoAtual.atacar(self.atqInimigo)
            else:
                inimigoAtual.curar()

        elif 0.20 >= self.porcInimigo <= 0.5:
            if dadoEscolha <= 50 and self.porcProta >= 0.2:
                inimigoAtual.curar()
            else:
                inimigoAtual.atacar(self.atqInimigo)

        else:
            if dadoEscolha <=75:
                inimigoAtual.curar()
            else:
                inimigoAtual.atacar(self.atqInimigo)

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

    def menuBatalha(self):
        
        camaraTxt = f'Câmara: {self.chamber}'
        print(f'{redBg}{camaraTxt:^72}{fecharcor}')

        espacoColorido(72, 'white')

        nomeInimigoTxt = f'{inimigoAtual.nome} LVL {inimigoAtual.lvl}'
        statsInimigoTxt = f'Vida: {inimigoAtual.vida:.0f}/{inimigoAtual.vidaMax}|{inimigoAtual.vida * 100 / inimigoAtual.vidaMax:.0f}% Atq:{inimigoAtual.atq} Vel: {inimigoAtual.speed}'

        print(f'{blackBg}{statsInimigoTxt:^72}{fecharcor}\n{BlackRed}{nomeInimigoTxt:^72}{fecharcor}')

        espacoColorido(72, 'purple')

        nomeProtaTxt = f'{prota.nome.capitalize()} LVL {prota.lvl}'
        statsProtaTxt = f'Vida: {prota.vida:.0f}/{prota.vidaMax}|{prota.vida * 100 / prota.vidaMax:.0f}% Atq:{prota.atq} Vel: {prota.speed}'


        print(f'{BlackBlue}{nomeProtaTxt:^72}{fecharcor}\n{blackBg}{statsProtaTxt:^72}{fecharcor}')

        prota.xpBar()


    def batalhas(self):
        selecionado = False
        while prota.vivo and inimigoAtual.vivo:
            selecionado = False
            
            self.menuBatalha()
            try:
                print(f'{blueBg}{'1- Atacar 2- Defender 3- Curar: ':^72}{fecharcor}')
                movimento = int(input())
                limparTela()

                if 0 < movimento < 4:
                    if movimento == 1:
                        while not selecionado:
                            for i, c in enumerate(prota.ataques):
                                if i % 2 == 0:
                                    cor = BlackBlue
                                    corBarra = 'black'
                                else:
                                    cor = blueBg
                                    corBarra = 'blue'

                                atqTxt = f'{i+1}- {c['nome']} - {c['desc']}'
                                infoTxt = f'{c['chance']}% de acerto, {c['taxa']}% de taxa crítica, {c['critico']}x de multiplicador crítico'

                                
                                print(f'{cor}{atqTxt:^72}{fecharcor}')
                    
                                print(f'{cor}{infoTxt:^72}{fecharcor}')
                                espacoColorido(72, corBarra)

                                
                            self.atqEscolhido = int(input('Escolha(0 PARA VOLTAR): '))

                            if 0 < self.atqEscolhido < len(prota.ataques)+1:
                                selecionado = True
                                limparTela()
                                self.decidirOrdem(movimento, prota.ataques[self.atqEscolhido-1])

                            elif self.atqEscolhido == 0:
                                limparTela()
                                break

                            else:
                                raise ValueError
                            
                    if movimento == 2:
                        selecionado = True

                    if movimento == 3:
                        while not selecionado:
                            print(f'{BlackRed}A CADA CURA SEGUIDA VOCÊ TEM MAIS CHANCE DE ERRAR!!!{fecharcor}')
                            print(f'{BlackRed}{prota.curasSeguidas*20}% A MAIS DE CHANCE DE ERRO!!!{fecharcor}')
                            self.curaEscolhida = int(input(f'{yellowTxt}1- {greenTxt}Cura Simples:{fecharcor} {listaCuras[0]['desc']} \n{yellowTxt}2- {greenTxt}Cura Media:{fecharcor} {listaCuras[1]['desc']}\n{yellowTxt}3- {greenTxt}Cura Avançada:{fecharcor} {listaCuras[1]['desc']}\n{yellowTxt}0- {redTxt}Voltar{fecharcor}\nEscolha: '))

                            if 0 < self.curaEscolhida < 4:
                                selecionado = True
                                self.decidirOrdem(movimento, self.curaEscolhida)

                            elif self.curaEscolhida == 0:
                                limparTela()
                                break

                            else:
                                raise ValueError    

                    self.turno += 1

                else:
                    raise ValueError

            except ValueError:
                print('Numero invalido, tente novamente')

            if not inimigoAtual.vivo:
                prota.novaChamber()
                prota.xpUp()
                prota.roubarAtaque()
                
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

        #QUANTO UPA POR PONTO
        self.vidaX = 4
        self.atqX = 2
        self. speedX = 5


    def atacarPai(self, ataque):
        self.ataque = ataque

        dado = randint(1, 100)

        self.curasSeguidas = 0
        
        if dado < self.ataque['chance']:
            if dado > self.ataque['taxa']:
                texto = randint(0, len(self.ataque['acerto'])-1)

                self.dano = self.atq * self.ataque['dano']

                print(f'{self.nome} {self.ataque['acerto'][texto]} e causou {self.dano:.0f} de dano')

            else:
                texto = randint(0, len(self.ataque['critou'])-1)
                
                self.dano = self.atq * self.ataque['dano'] * self.ataque    ['critico']

                print(f'{self.nome} {self.ataque['critou'][texto]} foi CRÍTICO e causou {self.dano:.0f} de dano')
        else:
            texto = randint(0, len(self.ataque['erro'])-1)

            self.dano = 0

            print(f'{self.nome} {self.ataque['erro'][texto]} NADA aconteceu')

        sleep(2)

    def curarPai(self):
        dado = randint(1, 100)

        if dado <= listaCuras[self.curaDecidida]['chance']-self.curasSeguidas*20:
            texto = randint(0, len(listaCuras[self.curaDecidida]['acerto'])-1)

            print(f'{self.nome} {listaCuras[self.curaDecidida]['acerto'][texto]}')

            self.vida += self.vidaMax*listaCuras[self.curaDecidida]['vida']/100

            self.curasSeguidas += 1
        else:
            texto = randint(0, len(listaCuras[self.curaDecidida]['erro'])-1)

            print(f'{self.nome} {listaCuras[self.curaDecidida]['erro'][texto]}')

            self.curasSeguidas = 0
            
        if self.vida>self.vidaMax:
            #SE PASSAR DE 100%
            self.vida = self.vidaMax

        sleep(2)


    def girarDado(self):
        self.dado6 = randint(1,6)

    def upHp(self):
        self.vida += self.vidaX
        self.vidaMax = self.vida

    def upAtq(self):
        self.atq += self.atqX
        self.atqMax = self.atq

    def upSpeed(self):
        self.speed += self.speedX
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
        self.atq = 10
        self.vidaMax = self.vida
        self.atqMax = self.atq
        self.speedMax = self.speed
        self.lvl = 0
        self.sp = 0
        self.xp = 0
        self.erro = None
        self.ataques = [listaAtaques['investida']]
        print(self.ataques)

    def xpBar(self):
        barSize = 66
        textoXp = f'{self.xp}% XP'
        preenchidas = round(self.xp/100*barSize)
        naoPreenchidas = barSize - preenchidas

        print(f'{greenBg} '*preenchidas, end=f'{fecharcor}')

        if naoPreenchidas > 0:
            print(f'{whiteBg} '*naoPreenchidas, end=f'{fecharcor}')

        print(f'{greenTxt}{textoXp:^6}{fecharcor}')

        
    def skillMenu(self):
        print(f'{purpleTxt}{whiteBg}                             Skill Points:{self.sp}                             {fecharcor}')
        print(f'{purpleTxt}{whiteBg}                           O que deseja upar?                           {fecharcor}')

    def lvlUp(self, ups):
        self.lvl += 1*ups
        self.sp += 3*ups
        self.skillMenu()

        while self.sp != 0 or self.erro == True:
            uparTxt = [f'VIDA: {self.vida} + {self.vidaX}', f'ATAQUE: {self.atq} + {self.atqX}', f'VELOCIDADE {self.speed} + {self.speedX}']

            for i, c in enumerate(uparTxt):
                #Precisa do if por causa das cores diferentes:(, poderia fazer uma lista das cores e puxar por indice mas nem compensa, diminuiria 3 linhas
                
                if i == 0: print(f'{PurpleYellow}{i+1} - {PurpleGreen}{c:^68}{fecharcor}')

                elif i == 1: print(f'{PurpleYellow}{i+1} - {PurpleRed}{c:^68}{fecharcor}')

                else: print(f'{PurpleYellow}{i+1} - {PurpleBlue}{c:^68}{fecharcor}')

            upar = int(input(f'Escolha: '))
            
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
        #50% de xp a mais se o inimigo for lvl menor
        #75% se tiverem os lvls iguais
        #100% se o inimigo tiver lvl maior
        #Precisa balancear
        self.lvlUpado = 0

        if inimigoAtual.chamber > self.lvl:
            self.xpUpado = 20

        else:
            self.xpUpado = 0
    
        if inimigoAtual.lvl < self.lvl:
            self.xpUpado += 40
            self.xp += self.xpUpado

        elif inimigoAtual.lvl == self.lvl:
            self.xpUpado += 60
            self.xp += self.xpUpado

        elif inimigoAtual.lvl > self.lvl:
            self.xpUpado += 90
            self.xp += self.xpUpado

        while self.xp >= 100:
            self.lvlUpado += 1
            self.xp -= 100

        upadoTxt = f'Você upou {self.xpUpado}% de XP!!!'
        lvlTxt= f'E upou {self.lvlUpado} LVL!!!'
        
        print(f'{greenBg}{upadoTxt:^72}{fecharcor}')
        if self.lvlUpado > 0: print(f'{greenBg}{lvlTxt:^72}{fecharcor}')

        sleep(2)
        limparTela()

        if self.lvlUpado > 0:
            self.lvlUp(self.lvlUpado)


    def atacar(self, ataque):
        super().atacarPai(ataque)

        inimigoAtual.vida -= self.dano
        if inimigoAtual.vida <= 0:
            inimigoAtual.morrer()

    def curar(self, curaEscolhida):
        self.curaDecidida = curaEscolhida -1

        super().curarPai()

    def roubarAtaque(self):
        selecionado = False
        while not selecionado:
            try:
                roubarEscolha = input(f'{WhiteGreen}{'Você pode tentar roubar um ataque do inimigo, deseja fazer isso? [S/N]':^72}{fecharcor}')

                if roubarEscolha.upper() == 'S':
                    for i, c in enumerate(inimigoAtual.ataques):
                        if i % 2 == 0:
                            cor = YellowWhite
                            corBarra = 'yellow'
                        else:
                            cor = WhiteYellow
                            corBarra = 'white'

                        atqTxt = f'{i+1}- {c['nome']} - {c['desc']}'
                        infoTxt = f'{c['chance']}% de acerto, {c['taxa']}% de taxa crítica, {c['critico']}x de multiplicador crítico'

                        print(f'{cor}{atqTxt:^72}{fecharcor}')

                        print(f'{cor}{infoTxt:^72}{fecharcor}')
                        espacoColorido(72, corBarra)

                        
                    self.ataqueRoubado = int(input('Escolha(0 para desistir): '))
                    
                    limparTela()

                    if 0 < self.ataqueRoubado <= len(inimigoAtual.ataques):
                        if inimigoAtual.ataques[self.ataqueRoubado-1] not in self.ataques:

                            if len(prota.ataques) == 4:

                                print(f'{redBg}{'Você já tem 4 ataques, deseja trocar um: [S/N]':^72}{fecharcor}')

                                certezaTrocar = input('Escolha:')
                                limparTela()

                                if certezaTrocar.upper() == 'S':
                                    print(f'{redBg}{'Qual?':^72}{fecharcor}')

                                    for i, c in enumerate(prota.ataques):
                                        if i % 2 == 0:
                                            cor = WhiteBlue
                                            corBarra = 'white'
                                        else:
                                            cor = BlueWhite
                                            corBarra = 'blue'

                                        atqTxt = f'{i+1}- {c['nome']} - {c['desc']}'
                                        infoTxt = f'{c['chance']}% de acerto, {c['taxa']}% de taxa crítica, {c['critico']}x de multiplicador crítico'

                                        print(f'{cor}{atqTxt:^72}{fecharcor}')

                                        print(f'{cor}{infoTxt:^72}{fecharcor}')
                                        espacoColorido(72, corBarra)

                                    self.ataqueRemovido = int(input('Escolha: '))

                                    limparTela()
                                    
                                    if 0 < self.ataqueRemovido < 5:
                                        selecionado = True
                                        self.efetuarRoubo(self.ataqueRoubado, self.ataqueRemovido)
                                        #Chance roubar ataque(ataqueRoubado, ataqueRemovido = None)- da prota.ataques.append(inimigo) print(sucesso/erro)

                                    else: raise ValueError

                                    limparTela()

                                elif certezaTrocar.upper() == 'N': 
                                    selecionado = False
                                    limparTela()

                                else: raise KeyError

                            else:
                                selecionado = True
                                self.efetuarRoubo(self.ataqueRoubado)
                        else:
                            print(f'{redBg}{'VOCÊ JÁ POSSUI ESSE ATAQUE!!!':^72}{fecharcor}')
                            sleep(1)
                            limparTela()

                            selecionado = False
                            
                    elif self.ataqueRoubado == 0:
                        limparTela()
                        break

                    else: raise ValueError
                    
                elif roubarEscolha.upper() == 'N':
                    print (f'{WhiteRed}{f'Tem certeza disso? [S/N]':^72}{fecharcor}')
                    if len(self.ataques) < 4:
                        print (f'{WhiteRed}{'Você ainda não tem todos os 4 ataques!!!':^72}{fecharcor}')

                    certeza = input('Escolha:')

                    if certeza.upper() == 'S':
                        selecionado = True
                        limparTela()

                    elif certeza.upper() == 'N': 
                        selecionado = False
                        limparTela()

                    else: raise KeyError

                else: raise KeyError

            except ValueError:
                print(f'{redBg}{'DIGITE UM NUMERO VALIDO!!!':^72}{fecharcor}') 

            except KeyError:
                print(f'{redBg}{'DIGITE UM VALOR VALIDO!!!':^72}{fecharcor}') 

            except:
                print(print(f'{redBg}{'ERRO!!!':^72}{fecharcor}') )

    def efetuarRoubo(self, roubado, removido = None):
        ganhou = False

        if inimigoAtual.lvl > self.lvl: chance = 75

        elif inimigoAtual.lvl == self.lvl: chance = 50

        else: chance = 25

        girarRoubo = randint(1, 100)

        if girarRoubo <= chance: ganhou = True

        rouboTxt = f'Chance de dar certo: {chance}%'
        print(f'{WhiteBlue}{rouboTxt:^72}{fecharcor}')

        if ganhou:
            for c in range(0, 20):
                if c%2 == 0:
                    roletaCor = WhiteRed
                    stdout.write(f"\r{roletaCor}{'Perdeu':^72}{fecharcor}")
                    stdout.flush()

                else:
                    roletaCor = WhiteGreen
                    stdout.write(f"\r{roletaCor}{'Ganhou':^72}{fecharcor}")
                    stdout.flush()

                sleep(0.05 + (c*0.02))

            if removido != None:
                prota.ataques.pop(removido-1)
                prota.ataques.append(inimigoAtual.ataques[roubado-1])

            else:
                prota.ataques.append(inimigoAtual.ataques[roubado-1])

            print()
            print(f'{greenBg}{'SUCESSO!!!':^72}{fecharcor}')
            

        else:
            for c in range(0, 20):
                if c%2 != 0:
                    roletaCor = WhiteRed
                    stdout.write(f"\r{roletaCor}{'Perdeu':^72}{fecharcor}")
                    stdout.flush()

                else:
                    roletaCor = WhiteGreen
                    stdout.write(f"\r{roletaCor}{'Ganhou':^72}{fecharcor}")
                    stdout.flush()

                sleep(0.05 + (c*0.02))

            print()
            print(f'{redBg}{'Fez o L':^72}{fecharcor}')

        sleep(1)

        limparTela()

        #Menor chance se o inimigo for lvl maior que vc
        pass

    def novaChamber(self):
        self.vida = self.vidaMax
        self.atq = self.atqMax
        self.speed = self.speedMax

    def morrer(self):
        prota.vivo = False
        sleep(1)
        limparTela()
        print(f'{blackBg}{redTxt}Voce morreu :( Camâra alcançada: {inimigoAtual.chamber}{fecharcor}')
        sleep(2)

        re = str(input(f'{blueTxt}Quer continuar?{fecharcor} [{greenTxt}S{fecharcor}/{redTxt}N{fecharcor}]: '))
        if re.upper() == 'S':
            iniciarJogo()
            pass
        else:
            print('Fim de jogo')


        

    def defender(self):
        self.curasSeguidas = 0
        #defesa tambem
        #80% de defender um golpe fisico
        #30% tentativa de parry(stunna inimigo 1 rodada)
        pass





class Inimigo(Combatente):
    def __init__(self, nome, base, comp, chamber):
        self.nome = nome
        self.base = base
        self.complemento = comp
        self.chamber = chamber

        super().__init__()

        
        self.vidaMax = self.vida
        self.atqMax = self.atq
        self.speedMax = self.speed

        self.lvlBaseado = 0
        self.decidirLvl()

        self.sp = self.lvl*3
        self.decidirStats()

        self.ataques = []
        self.ataquesPossiveis = []

        self.decidirAtaques()
        self.decidirMoveset()
            



    def decidirLvl(self):
        self.girarDado()

        if prota.lvl > self.chamber:
            self.lvlBaseado = prota.lvl
        else:
            self.lvlBaseado = self.chamber


        if self.dado6 == 3 or self.dado6 == 4:
            self.lvl = self.lvlBaseado

        elif self.dado6 > 4:
            self.lvl = self.lvlBaseado * (1+randint(1,3)*10/100)

        else:
            self.lvl = self.lvlBaseado * (1-randint(1,3)*10 / 100)

        if self.lvl < 1: self.lvl = 1 

        self.lvl = floor(self.lvl)
        
    def decidirAtaques(self):
        #OLHAR
        #talvez melhor guardar o items?
        for tipoC in self.tipos:
            for ataqueC in listaAtaques.values():
                if ataqueC['tipo'] == tipoC:
                    self.ataquesPossiveis.append(ataqueC)

    def decidirMoveset(self):

        for c in range(0, len(self.ataquesPossiveis)):
            pronto = False
            if c > 3:
                break

            while not pronto:
                moveTemp = choice(self.ataquesPossiveis)
                if moveTemp not in self.ataques:
                    self.ataques.append(moveTemp)
                    print('appendou')
                    pronto = True
                else:
                    pronto = False
        for c in self.ataques: print(c)
                

    def decidirStats(self):
        pass

    def atacar(self, ataque):
        super().atacarPai(self.ataques[ataque])

        prota.vida -= self.dano

        if prota.vida <= 0:
            prota.morrer()

    def curar(self):
        self.curaDecidida = randint(0, 1)
        super().curarPai()

    def defender(self):
        self.curasSeguidas = 0
        pass

    def morrer(self):
        print(f'{greenTxt}{self.nome} FOI MORTO{fecharcor}')
        self.vivo = False
        pass


class Aranha(Inimigo):
    def __init__(self, nome, base, comp, chamber):
        self.tipos = ['basico', 'venenoso', 'inseto']
        super().__init__(nome, base, comp, chamber)

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

class Paladino(Inimigo):
    def __init__(self, nome, base, comp, chamber):
        self.tipos = ['basico', 'humanoide', 'sagrado', 'devoto']
        super().__init__(nome, base, comp, chamber)

    def decidirStats(self):
        c = 1
        dadoStats = randint(1,100)

        for c in range (1, self.sp+1):
            if c%3 == 0:
                self.upHp()
            else:
                if dadoStats < 76:
                    self.upAtq()
                else:
                    self.upSpeed

class Urso(Inimigo):
    def __init__(self, nome, base, comp, chamber):
        self.tipos = ['basico', 'pesado', 'animal']
        super().__init__(nome, base, comp, chamber)

    def decidirStats(self):
        c = 1
        dadoStats = randint(1,100)

        for c in range (1, self.sp+1):
            if c%3 == 0:
                self.upAtq()
            else:
                if dadoStats < 51:
                    self.upAtq()
                else:
                    self.upHp()

class Goblin(Inimigo):
    def __init__(self, nome, base, comp, chamber):
        self.tipos = ['basico', 'bandido', 'pequeno', 'humanoide', 'perverso']
        super().__init__(nome, base, comp, chamber)

    def decidirStats(self):
        c = 1
        dadoStats = randint(1,100)

        for c in range (1, self.sp+1):
            if dadoStats < 51:
                self.upAtq()
            elif 50 < dadoStats < 76:
                self.upHp()
            else:
                self.upSpeed()

class Vampiro(Inimigo):
    def __init__(self, nome, base, comp, chamber):
        self.tipos = ['basico', 'voador', 'vampirismo', 'humanoide', 'perverso']
        super().__init__(nome, base, comp, chamber)

    def decidirStats(self):
        c = 1
        dadoStats = randint(1,100)

        for c in range (1, self.sp+1):
            if c%3 == 0:
                self.upHp()
            else:
                if dadoStats < 70:
                    self.upSpeed()
                elif 70 < dadoStats < 91:
                    self.upAtq()
                else:
                    self.upHp()
