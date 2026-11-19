class Gamer:
    def __init__(self, nome = '', nick = ''):
        self.nome = nome
        self.nick = nick
        self.favs = []
    def favoritos(self, jogo = ''):
        self.favs.append(jogo)
    def dados(self):
        print (f'Seu nick eh {self.nick}, seu nome real eh {self.nome} e seus jogas favoritos sao: {self.favs}')

juego = Gamer('Jean', 'JeanLucas999')
juego.favoritos('Terraria')
juego.favoritos('Elden Ring')
juego.dados()
