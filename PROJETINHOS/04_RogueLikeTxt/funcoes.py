#CORES TEXTO
redTxt = '\33[091m'
blueTxt = '\033[094m'
yellowTxt = '\033[093m'
purpleTxt = '\033[095m'
greenTxt = '\033[092m'

#CORES BACKGROUND
blackBg = '\033[040m'
whiteBg = '\033[047m'
redBg = '\33[041m'
blueBg = '\033[044m'
yellowBg = '\033[043m'
purpleBg = '\033[045m'
greenBg = '\033[042m'

#BG + TXT
#Primeiro cor do BG depois TXT
BlackRed = '\033[040;091m'
BlackGreen = '\033[040;092m'
BlackPurple = '\033[040;095m'
BlackBlue = '\033[040;094m'
BlackYellow = '\033[040;093m'

RedBlack = '\033[041;090m'

BlueYellow = '\033[044;093m'

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

def linha(bg='sem'):
    if bg == 'sem':
        print('-'*40)
    if bg == 'white':
        print(f'{whiteBg}{'-'*40}{fecharcor}')



fecharcor = '\33[m'
