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
BlueGreen = '\033[044;092m'
BlueRed = '\033[044;091m'
BlueWhite = '\033[044;097m'
BluePurple = '\033[044;095m'

PurpleYellow = '\033[045;093m'
PurpleGreen = '\033[045;092m'
PurpleRed = '\033[045;091m'
PurpleWhite = '\033[045;097m'
PurpleBlue = '\033[045;094m'


WhiteYellow = '\033[047;093m'
WhiteGreen = '\033[047;092m'
WhiteRed = '\033[047;091m'
WhiteBlue = '\033[047;094m'
WhitePurple = '\033[047;095m'

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

def linha(num = 40):
        print('-'*num)

def espacoColorido(num = 40, cor = 'white', linhas = 1):
    if cor.lower() == 'white':
        for c in range(0, linhas):
            print(f'{whiteBg}{' '*num}{fecharcor}')

    if cor.lower() == 'black':
        for c in range(0, linhas):
            print(f'{blackBg}{' '*num}{fecharcor}')

    if cor.lower() == 'purple':
        for c in range(0, linhas):
            print(f'{purpleBg}{' '*num}{fecharcor}')

    if cor.lower() == 'blue':
        for c in range(0, linhas):
            print(f'{blueBg}{' '*num}{fecharcor}')

    if cor.lower() == 'yellow':
        for c in range(0, linhas):
            print(f'{yellowBg}{' '*num}{fecharcor}')

    if cor.lower() == 'red':
        for c in range(0, linhas):
            print(f'{redBg}{' '*num}{fecharcor}')
        




fecharcor = '\33[m'
