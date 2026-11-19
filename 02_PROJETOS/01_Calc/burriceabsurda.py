import tkinter as tk

#CONTAGEM DE DIGITOS E QUAL PARTE DA CONTA ESTAMOS
algarismo = 0
operando = 1
#NUMEROS EM STRING
num1 = ''
num2 = ''
#TECLA
tecla = ''
#NUMEROS OPERANDO E RESULTADO
numop1 = 0
numop2 = 0
negativo = False
resultado = 0.0
#OPERACAO ESCOLHIDA
operacao = ''
#STR PRA MOSTRAR NA TELA
fazendo = ''
#CONTA RECEM FEITA OU NAO
res_pronto = False
#CORES
COR_FUNDO = "#00040D"        
COR_VISOR = "#0A0F1E"        
COR_TEXTO = "#E8EAF0"      

COR_NUMERO = "#141B2E"       
COR_NUMERO_HOVER = "#1E2740" 

COR_OPERADOR = "#3D5AFE"     
COR_OPERADOR_HOVER = "#5472FF"

COR_ESPECIAL = "#FF5252"     
COR_ESPECIAL_HOVER = "#FF7676"

COR_IGUAL = "#00E5A0" 
COR_IGUAL_HOVER = "#33F0B8"

FONTE_BOTAO = ("Segoe UI", 12, "bold")

def debug():
    print (f'DEBUG\n OPERANDO: {operando}\n OPERACAO: {operacao}\n NEGATIVO: {negativo}\n ALGARISMO: {algarismo}\n NUM1: {num1}\n NUM2: {num2}\n NUMOP1: {numop1}\n NUMOP2: {numop2}\n ')

def reset():
    principal.config(text=fazendo)

def clear():
    global num1, num2, fazendo, operando, algarismo, negativo, res_pronto, operacao
    num1 = num2 = fazendo = operacao = ''
    operando = 1
    algarismo = 0
    negativo = res_pronto = False

def botoes():
    clica = []
    cx = 50
    cy = 130

    for c in range(1, 10):
        clica.append(tk.Button(text=c, width=13, height=3, font=FONTE_BOTAO, bg= COR_NUMERO, fg=COR_TEXTO, activebackground=COR_NUMERO_HOVER, borderwidth=0, relief='f', command= lambda mandei=c: clicou(str(mandei))))
        clica[c-1].place(x=cx, y=cy) 

        cx += 150
        if c%3 == 0:
            if c == 3:
                mais = tk.Button(text='+', width=13, height=3, font=FONTE_BOTAO, bg=COR_OPERADOR, fg=COR_TEXTO, activebackground=COR_OPERADOR_HOVER, borderwidth=0, relief='raised', command= lambda: clicou('+'))
                mais.place(x=cx, y=cy)
            if c == 6:
                menos = tk.Button(text='-', width=13, height=3, font=FONTE_BOTAO, bg=COR_OPERADOR, fg=COR_TEXTO, activebackground=COR_OPERADOR_HOVER, borderwidth=0, relief='raised', command= lambda: clicou('-'))
                menos.place(x=cx, y=cy)
            if c == 9:
                vezes = tk.Button(text='*', width=13, height=3, font=FONTE_BOTAO, bg=COR_OPERADOR, fg=COR_TEXTO, activebackground=COR_OPERADOR_HOVER, borderwidth=0, relief='raised', command= lambda: clicou('*'))
                vezes.place(x=cx, y=cy)
            
            cx = 50
            cy += 100

        if c == 9:
            clica.append(tk.Button(text=0, width=13, height=3, font=FONTE_BOTAO, bg= COR_NUMERO, fg=COR_TEXTO, activebackground=COR_NUMERO_HOVER, borderwidth=0, relief='raised', command= lambda: clicou(str(0))))
            clica[9].place(x=50, y=cy)

    clr = tk.Button(text='CLEAR', width=13, height=3, font=FONTE_BOTAO, bg=COR_ESPECIAL, fg=COR_TEXTO, activebackground=COR_ESPECIAL_HOVER, borderwidth=0, relief='raised', command= lambda: clicou('limpar'))
    clr.place(x=350, y=530)

    igual = tk.Button(text='=', width=13, height=3, font=FONTE_BOTAO, bg=COR_IGUAL, fg=COR_TEXTO, activebackground=COR_IGUAL_HOVER, borderwidth=0, relief='raised', command= lambda: clicou('='))
    igual.place(x=200, y=530)

    porc = tk.Button(text='%', width=13, height=3, font=FONTE_BOTAO, bg=COR_OPERADOR, fg=COR_TEXTO, activebackground=COR_OPERADOR_HOVER, borderwidth=0, relief='raised', command= lambda: clicou('%'))
    porc.place(x=200, y=430)

    potencia = tk.Button(text='^', width=13, height=3, font=FONTE_BOTAO, bg=COR_OPERADOR, fg=COR_TEXTO, activebackground=COR_OPERADOR_HOVER, borderwidth=0, relief='raised', command= lambda: clicou('^'))
    potencia.place(x=350, y=430)

    dividido = tk.Button(text='/', width=13, height=3, font=FONTE_BOTAO, bg=COR_OPERADOR, fg=COR_TEXTO, activebackground=COR_OPERADOR_HOVER, borderwidth=0, relief='raised', command= lambda: clicou('/'))
    dividido.place(x=500, y=430)

def clicou(clicado = ''):
    global num1, num2, numop1, numop2, operacao, operando, fazendo, resultado, algarismo, negativo, res_pronto
    debug()
    #SE TIVER ACABADO DE TERMINAR UMA CONTA
    if res_pronto:
        num1 = num2 = fazendo = ''
        algarismo = 0
        res_pronto = False

    if clicado.isnumeric():
        #SE TIVER NO SEGUNDO NUMERO
        if operando == 3:
            algarismo = 1
        #SE VIER NUMERO
        algarismo += 1
        #PRIMEIRO DIGITO
        if algarismo == 1:
            algarismo += 1
            if operando == 1:
                num1 = clicado
                fazendo += clicado
            elif operando == 3:
                num2 = clicado
                fazendo += clicado
        

        #PROXIMOS DIGITOS
        elif algarismo>1:
            if operando == 1:
                num1 += clicado
                fazendo += clicado
            if operando == 3:
                num2 += clicado
                fazendo += clicado      
        reset()
    else:
        #SE NAO VIER NUMERO
        if clicado in '*/+-=limpar^%':
            #RESOLVER A BOSTA DO IGUAL SEM OS 2 OPERANDO
            if clicado != '=' and operando != 3 and num1 != '':
                operando += 1

            if clicado == 'limpar':
                clear()

            if clicado in '*/+^%':
                operando += 1
                operacao = clicado
                fazendo += clicado

            if clicado == '-':
                if operando == 1:
                    negativo = True
                    fazendo += clicado
                elif operando == 2:
                    operando += 1
                    operacao = clicado
                    fazendo += clicado
            reset()

            if clicado == '=':
                try:
                    if operando == 3 and operacao != 'limpar':
                        if negativo == True:
                            numop1 = -int(num1)
                        else:
                            numop1 = int(num1)
                        numop2 = int(num2)

                        operando = 1
                        if operacao == '+':
                            resultado = str(numop1+numop2)

                        elif operacao == '-':
                            resultado = str(numop1-numop2)

                        elif operacao == '/':
                            resultado = str(numop1/numop2)

                        elif operacao == '*':
                            resultado = str(numop1*numop2)

                        elif operacao == '%':
                            resultado = str(numop1*numop2/100)

                        elif operacao == '^':
                            resultado = str(numop1**numop2)

                        negativo = False
                        res_pronto = True
                        fazendo = (f'{resultado}')
                        if resultado == '67':
                            fazendo = ('Six Seveeeeeeeen')
                
                except Exception as e:
                    print (e)
            reset()

def tecla_pressionada(event):
    tecla = event.char
    if tecla.isnumeric() or tecla in '+-*/^%' and tecla != '':
        clicou(tecla)
    elif tecla in '\r':
        clicou('=')
    elif event.keysym == 'BackSpace':
        clicou('limpar')

menu = tk.Tk()
menu.title('CALCULADORA')
menu.geometry('700x650')
menu.config(bg=COR_FUNDO)

principal = tk.Label(menu, text=fazendo, font=FONTE_BOTAO, bg=COR_VISOR, fg=COR_TEXTO,  borderwidth=0, width=58, height=5, relief='raised')
principal.place(x=52, y=10)
botoes()
menu.bind('<Key>', tecla_pressionada)


menu.mainloop()