---
layout: post
title: Porque é importante saber como o protocolo HTTP funciona
tags:
- useful
---

É interessante perceber que há tantas pessoas trabalhando escrevendo aplicações web que não entendem o básico sobre a internet e o protocolo HTTP. Você pode encontrar aplicações que demonstram comportamentos bizarros em qualquer lugar, as pessoas simplesmente esquecem de ler as especificações ou dormiram durante as aulas sobre o protocolo HTTP na universidade.

Um dos casos mais infelizes dessa falta de conhecimento é a “febre do POST”. Todos so formulários na aplicação usam o método POST para se comunicar com o servidor, não importa o que ele está fazendo ou se existem ou não “efeitos colaterais” envolvidos no caso. Simplesmente funciona dessa forma e as pessoas aparentemente não tem nenhum motivo pra não fazer dessa forma. Se você pergunta a alguém, eles vão provavelmente soltar a pérola, “ah, me disseram que o GET tem o limite no tamanho dos parâmetros que você pode mandar, então é melhor prevenir do que remediar”.

Mas o que é que há de tão mal nisso?

Se você der uma olhada no <a href="http://www.w3.org/Protocols/rfc2616/rfc2616-sec9.html#sec9.1.1">RFC do HTTP</a>, vai descrobrir que o método GET é descrito como “seguro” ('safe'). Seguro, no contexto do HTTP, significa que você deveria ser capaz de fazer vários GETs para uma aplicação web e isso não deveria causar efeitos colaterais, como apagar um cliente ou coisas do gênero, ele não deve causar alterações no recurso que está sendo requisitado, porque toda a idéia do método GET é de que você deveria simplesmente receber uma cópia (bem no estilo copiar-colar) do recurso que está naquela URL específica. Você não está fazendo nada de especial com o recurso, você deveria ser capaz de recebê-lo em qualqure lugar e a qualquer momento que desejasse.

Mas se você olhar a descrição do método POST vai descobrir que ele é um método “inseguro” ('unsafe'). Se você manda um POST pra uma URL, você pode estar definitivamente alterando alguma coisa no servidor e causando efeitos colaterais malignos, como libertar a Skynet e os Exterminadores que vão trazer o armagedom para a Terra. Ou você pode simplesmente estar criando um novo recurso naquela aplicação, como esse post de blog que você está lendo.

A diferença óbvia é que POSTs podem (e normalmente devem) alterar o estado de alguma coisa do lado do servidor, enquanto um GET nunca deveria ser capaz de fazer uma coisa dessas. Comparando com bancos de dados que usam SQL, GETs seriam como “selects” e POSTs como “inserts”. Você já viu um “insert” que retornava uma tabela de resultados ou um “select” que inseria dados no banco? Nem eu :)

Mas é claro que tudo ainda pode ficar pior. Imagine que você é o dono daquele site maligno que usa apenas POSTs em todos os seus formulários e um desses é um formulário de pesquisa. Usuários vão usá-lo para buscar produtos e adicioná-los as seus carrinhos de compra. Um usuário está interessado em comprar o novo disco do AC/DC, mas ele não tem certeza do nome, então ele simplesmente digita AC/DC e aperta “enter” no teclado.

Voila!

Lá, no topo da página, está “Black Ice”, o novo album deles (Já comprou o seu? Deveria!). Ele clica no link e enquanto ele está vendo a página, se lembra que não comprou o album antes desse, “Stiff Upper Lip”. “Vou apertar no botão voltar e procurar por ele na lista de discos do AC/DC”, pensa o incauto usuário e quando ele clica no botão, o navegador mostra uma mensagem interessante:

<blockquote>“O navegador precisa enviar dados para o servidor para executar esta ação. Você tem certeza que deseja fazer isso?”</blockquote>

O usuário olha aterrorizado para a mensagem. “O que foi que eu fiz? Será que eles vão me cobrar por isso? Vão me mandar o novo disco da Britney Spears porque eu estou tentando apertar no botão de voltar?”.

Como protocolo HTTP define, POSTs não são métodos “seguros” e as ferramentas (normalmente os navegadores) devem avisar o usuário de que alguma coisa ruim pode acontecer se eles tentarem dar um POST por acidente em uma página e é exatamente isso que acontece se você tenta clicar no botão voltar após um POST. Nesse exemplo, o usuário não estaria fazendo nada de errado, mas imagine se em vez de estar voltando pra uma página de busca, ele poderia estar voltando para o formulário de “adicionar cliente” e um “voltar” poderia muito bem fazer com que ele re-criasse o cliente no banco de dados, o que não é exatamente a idéia.

Pior, se você está usando POST em um formulário de busca, os usuários nunca vão poder usar o botão voltar (os mestres da usabilidade dizem que ele é a coisa mais usada nos navegadores) e eles também não vão poder colocar aquela página de resultado nos seus favoritos! Você consegue imaginar algo pior do que isso? Você está evitando que as pessoas possam expressar todo o seu amor pelo seu site postando links pra eles no del.icio.us!

A idéia é bem simples, se você não está alterando nada no servidor, você deveria sempre usar GETs, seja lá o que for. Eles não quebram o botão voltar ou atualizar, deixam os usuários colocar as páginas requisitadas nos favoritos e não vão fazer com que os navegadores mostrem mensagens assustadoras para os usuários. Se você estiver alterando o estado de alguma coisa no servidor, você deve usar POST (e os outros métodos do HTTP que são definidos como “inseguros”, como PUT e DELETE), requisições que usam GET NUNCA deveriam alterar coisas no servidor (sabe aquele link que você fez que apaga um registro no banco de dados? Foi uma péssima idéia!).

E antes que eu me esqueça, depois de um POST com sucesso você deve sempre REDIRECIONAR o usuário para a página de sucesso, nunca, por motivo nenhum do universo, mostre a página de sucesso como resultado do POST. Ao redirecionar o usuário após um POST com sucesso você evita que ele reenvie os dados usando um “atualizar” ou clicando no botão voltar do navegador.

<strong>PS</strong>: Tradução de <a href="http://blog.codevader.com/2008/11/02/why-learning-http-does-matter/">"Why learning HTTP does matter"</a>, prometo que eu vou traduzir mais posts de lá, é só ter tempo o suficiente, de qualquer forma, se você sabe inglês, pode ler lá antes :)
