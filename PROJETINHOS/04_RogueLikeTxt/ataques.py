#Ordem para o dicionario de cada ataque:
#NOME, DANO, CHANCE DE ACERTO, TAXA, DANO CRITICO, ELEMENTO, CLASSE, LISTA COM FRASES DE ATAQUE NORMAL, LISTA COM FRASES DE DANO CRITICO, LISTA DE ERROS
#SOCORRO.
#VOU ENDOIDAR.
#NAO IMAGINEI QUE SOFRERIA TANTO.
#MEU DEUS.


#O ERRO REFERE SE AO MESMO INDICE DO ACERTO
#Girar dado para escolher qual tentativa, tipo comeu doritos 0 x nao conseguiu abrir o pacote 0

listaAtaques = [

]


#Ordem para as curas:
#NOME, DESCRICAO, %VIDA, CHANCE DE ACERTO, FRASES ACERTO, ERRO

listaCuras = [
    {'nome': 'Cura Simples', 'desc': 'Cura 20%, de sua vida e tem 100% de chance de SUCESSO', 'vida': 20, 'chance': 100, 
    'acerto': 
    [
        'Curou 100% tomando uma xicara de café bem quentinho, queimou a lingua e perdeu 80% dos 100%',
        'Comeu um pacotão de doritos, ganhou 20% de cura e 10 anos a menos de expectativa de vida', 
        'Tentou meditar, escorregou, por sorte caiu de cara em uma poça deixada pela poção de cura que caiu de seu bolso, curou 20%'
    ]
    },

    {'nome': 'Cura Media', 'desc': 'Cura 60% de sua vida e tem 50% de chance de SUCESSO', 'vida': 60, 'chance': 50, 
    'acerto': 
    [
        'Dormiu por 5 horas, como o adversario era muito generoso, acabou por não atrapalhar, curou 60%% de vida',
        'Carregou seu ki e recuperou 60% de vida', 
        'Pesquisou metodos de como conquistar FÊMEAS, deu tudo errado, bebeu cachaça e recuperou 60%% de vida'
    ],
    'erro':
    [
        'Tentou dormir, o adversario obviamente não deixou, 0% de vida recuperada'
        'Tentou carregar seu ki, INACREDITAVELMENTE, ele não estava em Dragon Ball, nada aconteceu'
        'Pesquisou metodos de como conquistar FÊMEAS, percebeu que o problema estava nele, desistiu.'
    ]
    }
    ]

#Ordem para as defesas:
#NOME, DESCRICAO, CHANCE DE ACERTO, FRASES ACERTO, ERRO

listaDefesas = [

]


