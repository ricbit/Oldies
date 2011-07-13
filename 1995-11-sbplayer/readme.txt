PLY2FM Pack
By Ricardo Bittencourt

        Estes sao dois programinhas que fiz ha' muito tempo, tres dias apos
ter comprado minha SoundBlaster. Eu fiquei quase tres anos sem ouvir a boa
velha musica FM, e quis aprender a programar a placa o mais rapido possivel.
        Aproveitando a oportunidade, peguei uma das minhas MSX-FAN velhas e
achei o fonte FM-BASIC de uma musica do YS3. Achei que seria divertido 
fazer um conversor FM-BASIC para SoundBlaster, ainda mais considerando que
seria minha primeira oportunidade de ouvir as musicas do FM-PAC que saiam
nas revistas.
        Eventualmente todo esse know-how foi utilizado na construcao do
PSG Player (que e' muito mais rapido e fiel ao som original). Mas estes
programas ainda podem ser uteis, principalmente se voce for compor uma 
musica, e, como eu, odeia aqueles editores MIDI para Windows.

        O primeiro programa, PLAY, converte um arquivo texto .PLY para um
formato .FM, que nada mais e' que uma lista de eventos da Adlib. O formato
.PLY suporta os comandos A B C D E F G R L V . < > # + - .Eu adicionei ainda 
o comando | para mudar para o proximo canal (ele permite tocar mais de
tres canais simulataneos).
        O segundo programa, PLAYER, toca um arquivo .FM em uma Adlib 
compativel. Voce pode ainda observar uma linda sequencia de numeros primos
enquanto a musica toca :-> So' para avisar: a frequencia que ele pede
nao e' a frequencia de amostragem, e sim a frequencia da seminima. Tente 
valores baixos, entre 20 e 80.

        Como eu nao tinha um FM-PAC, nao implementei varios dos comandos
que vi nas listagens. Se voce tiver um manual de programacao do FM-BASIC, 
mande para mim, assim poderei melhorar este pacote.
        Mais uma aviso: esses programas sao realmente velhos, e so' 
compilarao no Borland C++. Os fontes sao GNU-GPL, e' claro.

Ricardo Bittencourt
