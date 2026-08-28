import tkinter as tk

#CORES
AzulClaro = '#C3EBEE'
AzulMedio = "#77A8AC"
AzulEscuro = "#090E2B"
Vermelho = "#610808"
Verde = "#4D7E41"



class EscolherPalavra:
    def __init__(self):
        self.visibilidade = False
        self.frame = tk.Frame(menu, bg=AzulClaro)

    def colocarBotao(self):
        #BOTOES
        self.botaoPalavra = tk.Entry(self.frame, width=50, justify='center', font=fonte, show='*', fg=AzulEscuro)
        self.botaoPalavra.place(relx=0.5, rely=0.45, anchor='center')

        self.titulo = tk.Label(self.frame, text='SELECIONE A PALAVRA', width=23, justify='center', font=fonte, bg=AzulMedio, fg=AzulEscuro)
        self.titulo.place(relx=0.5, rely=0.2, anchor='center')

        self.visivel = tk.Button(self.frame, width=15, justify='center', font=fontePequena, text='VER PALAVRA', bg=AzulMedio, fg=AzulEscuro, command= lambda: self.verSenha())
        self.visivel.place(relx=0.5, rely=0.6, anchor='center')

        self.confirmar = tk.Button(self.frame, width=15, justify='center', font=fonte, text='CONFIRMAR', bg=AzulMedio, fg=AzulEscuro, command= lambda: self.confirmarPalavra())
        self.confirmar.place(relx=0.5, rely=0.7, anchor='center')

        self.fechar = tk.Button(menu, width=3, justify='center', font=fontePequena, text='X', bg=AzulEscuro, fg=AzulClaro, command= lambda: menu.destroy())
        self.fechar.place(relx=0.95, rely=0.05, anchor='center')

        self.frame.place(x=0, y=0, width=1000, height=700)


    def verSenha(self):
        #FUNCIONAR PARA ALTERNAR O VER SENHA
        
        if self.visibilidade == False:
            self.botaoPalavra.config(show='')
            self.visibilidade = True

        else:
            self.botaoPalavra.config(show='*')
            self.visibilidade = False

    def confirmarPalavra(self):
        global jogo
        palavraget = (((self.botaoPalavra.get()).strip()).upper())
        self.frame.destroy()

        jogo = Jogo(palavraget)
        jogo.textoTela()

        self.fechar.lift()



class Jogo:
    def __init__(self, palavra):
        self.vidas = 6
        self.palavra = palavra
        self.palavraFake = []
        self.letrasJogadas = []
        self.letrasErradas = []
        self.erros = ''
        self.frame = tk.Frame(menu, bg=AzulClaro)

        for c in self.palavra:
            print(c)
            if c is not ' ':
                self.palavraFake.append('_ ')
            else:
                self.palavraFake.append('  ')

    def textoTela(self):
        #TEXTOS COM RECEBIMENTO DO TECLADO
        menu.bind('<Key>', self.tecla_pressionada)

        self.textoVidas = tk.Label(self.frame, text=f'{self.vidas}/6 VIDAS', font=fonte, width=10, relief='groove', bg=AzulMedio, fg=AzulEscuro)
        self.textoVidas.place(relx=0.05, rely=0.05)

        self.textoPalavra = tk.Label(self.frame, text=' '.join(self.palavraFake), font=fonteGigante, justify='left', width=len(self.palavraFake)*2, relief='raised', borderwidth=3, bg=AzulEscuro, fg=AzulClaro)
        self.textoPalavra.place(relx=0.05, rely=0.7)

        self.textoErro = tk.Label(self.frame, text='LETRAS ERRADAS:', font=fonte, justify='left', width=15, relief='flat', fg=AzulEscuro, bg=AzulClaro)
        self.textoErro.place(relx=0.22, rely=0.05)

        self.frame.place(x=0, y=0, width=1000, height=700)

    def tecla_pressionada(self, event):
        #TECLADO
        letra = event.char.upper()
        if letra.isalpha():
            self.chutarLetra(letra)

    def chutarLetra(self, letra):
        #RECEBER A LETRA CLICADA E USAR ELA
        acertos=0

        self.letraChutada = letra
        #SE AINDA NAO FOI JOGADA
        if self.letraChutada not in self.letrasJogadas:
            #ENTRA NAS JOGADAS
            self.letrasJogadas.append(self.letraChutada)
            #VER SE ALGUMA LETRA BATER E SE BATER, COLOCAR NA PALAVRA
            for i in range(len(self.palavra)):
                if self.letraChutada == self.palavra[i]:
                    acertos += 1
                    self.palavraFake[i] = self.letraChutada

            if acertos == 0:
                #SE NAO TIVER NENHUMA LETRA BATENDO COM A CLICADA
                self.vidas -= 1

                #CRIAR O LABEL NO PRIMEIRO ERRO
                if self.vidas == 5:
                    self.erros = tk.Label(self.frame, text=''.join(self.letrasErradas), font=fonte, justify='left', width=len(self.letrasErradas)*2, relief='flat', bg=AzulClaro, fg=AzulEscuro)
                    self.erros.place(relx=0.46, rely=0.05)

                self.letrasErradas.append(f'{self.letraChutada}, ')

                #ATUALIZAR TEXTO DE VIDA E ERROS
                self.textoVidas.config(text=(f'{self.vidas}/6 VIDAS'))

                self.erros.config(text='')
                self.erros.config(text=''.join(self.letrasErradas), width=len(self.letrasErradas)*2)

                #CASO DE DERROTA
                if self.vidas == 0:
                    self.fimdeJogo()

            #CASO DE VITORIA
            elif self.palavraFake.count('_ ') == 0:
                print ('ganhou', self.palavraFake)
                self.fimdeJogo()


        self.textoPalavra.config(text=' '.join(self.palavraFake))

    def fimdeJogo(self):
        menu.unbind('<Key>')
        self.palavraFim = tk.Label(text=f'A palavra era: {self.palavra}', font=fonte, justify='center', width=len(self.palavra)+20, bg=AzulMedio, fg=AzulClaro, relief='sunken')
        self.palavraFim.place(relx=0.5, rely=0.6, anchor='center')
        if self.vidas == 0:
            self.frame.destroy()
            self.perdeu = tk.Label(text='VOCE PERDEU KKKKKK', font=fonteGigante, justify='center', width=20, height=2, bg=AzulMedio, fg=Vermelho, relief='sunken')
            self.perdeu.place(relx=0.5, rely=0.4, anchor='center')

        else:
            self.frame.destroy()
            self.venceu = tk.Label(text='PARABENS, VOCE VENCEU', font=fonteGigante, justify='center', width='23', height=2, bg=AzulMedio, fg=Verde, relief='sunken')
            self.venceu.place (relx=0.5, rely=0.4, anchor='center')


    
fonte= ('Segoe UI', 22)
fontePequena= ('Segoe UI', 16)
fonteGigante= ('Segoe UI', 40)


menu = tk.Tk()
menu.title('Jogo da forca')
menu.geometry('1000x700')
menu.config(bg=AzulClaro)

EscolhaPalavra = EscolherPalavra()
EscolhaPalavra.colocarBotao()

menu.mainloop()
