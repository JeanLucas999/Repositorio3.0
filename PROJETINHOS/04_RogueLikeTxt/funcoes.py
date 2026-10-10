#CORES TEXTO
redTxt = '\33[091m'
blueTxt = '\033[094m'
yellowTxt = '\033[093m'
purpleTxt = '\033[095m'
greenTxt = '\033[092m'
blackTxt = '\033[030m'

#CORES BACKGROUND
blackBg = '\033[040m'
whiteBg = '\033[047m'
redBg = '\33[041m'
blueBg = '\033[044m'
yellowBg = '\033[043m'
purpleBg = '\033[045m'
greenBg = '\033[042m'

#BG + TXT

#CORES COM SEMANTICA
#ruim
#muitoruim
#pessimo

#bom
#muitobom
#perfeito
#\033[1;37;44m

def limparTela():
    print('\033[2J')

def linha():
    print('-'*40)

fecharcor = '\33[m'
