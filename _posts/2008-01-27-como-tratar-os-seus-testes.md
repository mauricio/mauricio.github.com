---
layout: post
title: Como tratar os seus testes?
tags:
- useful
---
Já percebeu o quanto se fala em qualidade e testes de software nos últimos tempos? Testar software hoje não é mais apenas sentar o seu usuário (vulgo “cliente”) na frente de uma tela rodando o seu sistema pra que ele possa validar se as funcionalidades estão implementadas a contento. A algum o uso de testes unitários, de integração e funcionais se tornaram um fato corriqueiro para equipes que trabalham com software e prezam pela mínima qualidade (<a href="http://imasters.uol.com.br/artigo/6061/gerencia/qualidade_e_de_graca">até porque qualidade não é apenas falta de bugs</a>) e facilidade de se fazer alterações sem quebrar o sistema todo.

No caminhar da escrita de testes, os desenvolvedores aprenderam muitas coisas, sendo uma delas que o teste que você escreve já é o primeiro cliente do seu código. Quando você está escrevendo um teste pra um método ou função do seu programa, você está escrevendo também o primeiro código que vai fazer o uso dessa funcionalidade e vai poder perceber se é fácil ou difícil fazer uso desse método, se existem muitas dependências e se é necessário carregar estado demais para fazer com que o resultado final aconteça.

Você poderia, inclusive, escrever o teste antes do código que vai ser testado para guiar a sua implementação através do teste, assim você já escreve a sua funcionalidade partindo de um cliente real, que é o próprio teste, e não da sua imaginação, que acha que uma coisa deve ser de um jeito ou de outro. Com desenvolvimento orientado a testes você consegue caminhar mais rápido e escrever código que vai realmente ser utilizado, não apenas o que você “acha” que deveria escrever porque alguém pode vir algum dia a utilizar.

Com esse primeiro “cliente” do seu código você já pode perceber falhas na sua abstração e até mesmo na forma que você pensava que a funcionalidade deveria ser implementada. Você consegue descobrir falhas no seu design, no modo que você pensou que a funcionalidade deveria ser implementada e essa é uma característica que vai levar os nossos testes a um novo patamar, onde eles não vão mais ser testes.

<strong>Ora, mas se os meus testes não são testes, eles são o que?</strong>

Quando nós pensamos em um “teste”, o que vem a mente é alguma coisa que você faz a um objeto pra descobrir se ele “funciona” ou não. Normalmente você faz testes em um objeto que já está ou acredita-se que esteja “pronto”, você normalmente não testa objetos incompletos ou que já sejam conhecidamente falhos, porque você sabe que eles vão falhar de uma forma ou outra. E, principalmente, você não testa para melhorar, apenas para verificar.

No mundo do software você não precisa ter acesso ao que vai ser testado antes de escrever o teste, você pode já escrever o código do teste antes mesmo de ter a funcionalidade implementada, no seu teste você especificaria o que você espera passar como entrada e o que você espera receber na saída. O seu teste, neste momento, deixa de ser apenas um teste e se transforma em uma especificação, ele descreve como alguma coisa no sistema deve se comportar através de um conjunto finito de entradas e saídas (porque você não tem tempo infinito pra testar).

Ao deixar de encarar os testes como simples validadores de que o seu código funciona e assumir que eles definem as características do programa, você dá um passo além não apenas na questão de garantir a qualidade como também na própria documentação do sistema e gerência do projeto. Se você tem diversas “estórias” (ou “casos de uso”) pra serem implementados no sistema, eles se transformariam em diversas especificações do que o sistema faz e você teria, a cada especificação que passasse, a indicação de que alguma coisa está sendo produzida, você ganha de brinde, além das vantagens de ter software testado, um medidor de funcionalidades embutido.

A questão de deixar de tratar testes apenas como validadores do código chegou ao ponto de que até mesmo as ferramentas de testes unitários estão começando a ser suplantadas por ferramentas de desenvolvimento direcionado a comportamentos (ou Behaviour Driven Development – BDD).

É possível encontrar <a href="http://en.wikipedia.org/wiki/Behavior_driven_development">uma pequena definição sobre BDD na Wikipedia</a>:

“Behavior Driven Development (or BDD) is a software development technique that questions the behavior of an application before and during the development process. Created in response to the failings the founders perceived in Test Driven Development, Behavior Driven Development addresses requirements and specification in a way that is more textual than its predecessor. By asking questions such as "What should this application do?" or "What should this part do?" developers can identify gaps in their understanding of the problem domain and talk to their peers or domain experts to find the answers. By focusing on the behavior of applications, developers try to create a common language that's shared by all stakeholders: management, users, developers, project management and domain experts.”

A idéia é, além de tornar os testes, que agora são especificações, a documentação natural e a fonte de informações sobre o que o sistema faz e como faz. Cada especificação diz que “o sistema deveria fazer X” e se a especificação passa, é porque o sistema realmente faz “X”. Isso facilita a comunicação dentro da equipe, pois agora eles não se perguntam se o teste “Z” passou, mas se a funcionalidade “Z” foi implementada e também vai facilitar ainda mais para os especialistas de domínio que podem simplesmente chegar pra equipe e explicar o que o sistema deve fazer e as especificações garantindo que ele faz vão ser escritas.

Deixar de pensar em testes como validadores e passar a vê-los como definições facilita a comunicação entre todos os envolvidos no projeto, pois agora eles tendem a falar uma mesma língua (a “linguagem ubíqua” tanto pregada pelos defensores do <a href="http://domaindrivendesign.org/">Domain Driven Design</a>), já que as funcionalidades do sistema vão ser expressas através de especificações definidas pelo especialista do domínio e a equipe de desenvolvimento.

Vejamos um simples exemplo de especificação utilizando o framework <a href="http://rspec.info/">RSpec</a>, que é uma ferramenta de BDD para Ruby:

<pre class="brush:ruby">it 'Should not allow a not logged in user send an upload' do
    post :prepare
    response.should redirect_to( :action => 'login' )
end</pre>

A nossa especificação diz que “Usuários não logados não devem poder fazer um upload”, então o código dela deve comprovar que é isso que acontece e é exatamente isso que ele faz, ele primeiro faz uma requisição usando o método HTTP “POST” (na primeira linha da especificação) e depois garante que a resposta seja um “redirect” para a “ação” login. Mesmo que você não entenda Ruby ou RSpec, é fácil entender o que esse código quer dizer, as afirmações são claras e é essa facilidade de entendimento que faz com que BDD seja realmente uma ótima maneira de se expressar as funcionalidades que um software deve ter.

Então, se você continua vendo testes apenas como um modo de validar o seu sistema, está na hora de começar a mudar o pensamento e aproveitar melhor esses testes tranformando-os nas especificações de o que o seu sistema faz. Você iria escrever os testes de qualquer maneira, não vai custar nem um pouco a mais, vai?

<strong>Referências:</strong>
<ul>
      <li><a href="http://dannorth.net/introducing-bdd">Introducing BDD - Dan North</a></li>
      <li><a href="http://www.infoq.com/interviews/Dave-Astels-and-Steven-Baker">Dave Astels and Steven Baker on RSpec and Behavior-Driven Development</a></li>
</ul>
