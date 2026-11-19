class Porta:
    def abrir(self):
        print(f'Girar a macaneta e empurrar/puxar a porta')

class Empresa:
    def abrir(self):
        print(f'Faca tudo necessario para abrir a empresa')

class Ovo:
    def abrir(self):
        print(f'Bata o ovo na pia e tente abrir separando os lados')

class Pedra:
    pass


#METODO PYTHONICO POLIMORFICO DUCK TYPING

def tentarAbrir(objeto):
    try:
        objeto.abrir()
    except:
        print (f'Nao eh possivel abrir objeto tipo {objeto.__class__.__name__}')