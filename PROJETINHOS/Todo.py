import tkinter as tk
#NAO DA PRA USAR O DELETE SE FOR LISTA, TEM QUE SER DICIONARIO


class lista():
    def __init__(self):
        self.check  = False
        self.botao = ''
        self.botaoApagar = ''
        self.botaoCheck = ''
        self.corTxt = ''
        self.corBg = ''
        self.indiceBotao = ''

    def taskcreate(self, texto):
        #Nome aletorio, aqui vou organizar tudo em um dicionario
        global contagem
    
        if self.check == False:
            self.corTxt = "#3F0303"
            self.corBg = "#F58888"
        else:
            self.corTxt = "#2C4105"
            self.corBg = "#D3F09E"

        self.indiceBotao = contagem
        self.botao = tk.Label(text=texto, width=75, font=fonte, relief='solid', anchor='w', fg=self.corTxt, bg=self.corBg)
        self.botaoCheck = tk.Button(text='/', width=1, font=fonte, bg="#D3F09E",fg="#2C4105", relief='solid', command= lambda i=self.indiceBotao: checarBotao(i))
        self.botaoApagar = tk.Button(text='DEL', width=1, font=fonte, bg="#080808", fg="#F31010", relief='solid', command= lambda i=self.indiceBotao: apagarObjeto(i))

        objetos.append(novinho)

        self.botao.grid(padx=(5,0), row=contagem+1, column=1)
        self.botaoCheck.grid(padx=(5, 0), row=contagem+1, column=0)
        self.botaoApagar.grid(padx=(5, 0), row=contagem+1, column=2)

        contagem += 1


def checarBotao(indice):
    print ('CHECAR BOTAO')
    print (objetos[indice].check)
    objetos[indice].botaoCheck.config(fg=objetos[indice].corTxt, bg=objetos[indice].corBg)
    if objetos[indice].check == False:
        objetos[indice].check = True

        objetos[indice].corTxt = "#2C4105"
        objetos[indice].corBg = "#D3F09E"
    else:
        objetos[indice].check = False

        objetos[indice].corTxt = "#3F0303"
        objetos[indice].corBg = "#F58888"

    objetos[indice].botao.config(fg=objetos[indice].corTxt, bg=objetos[indice].corBg)

    pass


def apagarObjeto(indice):
    objetos[indice].botao.destroy()
    objetos[indice].botaoCheck.destroy()
    objetos[indice].botaoApagar.destroy()
    
    del objetos[indice]
    pass


def criarbotoes():
    global escrever
    escrever = tk.Entry(menu, justify='center', width=75, font=fonte)
    escrever.grid(padx=(5, 0), row=0, column=1)
    add = tk.Button(menu, text='+', command= addtxt, relief='solid', bg="#E6D8E9", fg='#000000')
    add.grid(padx=(5, 0), row=0, column=0)


def addtxt():
    #PUXA O DIABO DO TEXTO E MANDA O OBJETO PRA CLASSE
    print("ADDTXT")
    global novinho
    txt = escrever.get()
    novinho = lista()
    novinho.taskcreate(txt)

objetos = []
fonte = ('Segoe UI', 12)  
contagem = 0

menu = tk.Tk()
menu.title('To-Do')
menu.geometry('800x600')
criarbotoes()

menu.mainloop()