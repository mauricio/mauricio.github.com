---
layout: post
title: De many-to-many para many-to-one com JPA
tags:
- hibernate
- java
- jpa
- pt_BR
status: publish
type: post
published: true
meta:
  _su_keywords: ''
  _edit_last: '1'
  _wp_old_slug: ''
  dsq_thread_id: '218136673'
  _su_description: ''
  _efficient_related_posts: a:0:{}
  _relation_threshold: ''
---
<strong>Introdução</strong>

Relacionamentos em bancos de dados dificilmente são tão simples quanto parecem, especialmente quando você começa a utilizar relacionamentos “N:N” (muitos-para-muitos), esse tipo de relacionamento, um extremamente comum no mundo real, normalmente é um pouco mais complicado quando é abstraído para um banco de dados relacional. Neste material você vai entender como transformar um relacionamento N:N em um N:1 utilizando JPA.

Para continuar você deve ter conhecimentos da biblioteca de persistência do Java, a JPA, e do framwework <a href="http://hibernate.org/">Hibernate</a>. Os exemplos mostrados são, na verdade, testes do <a href="http://junit.org/">JUnit</a>, então ter conhecimento conhecimento básico de o que ele é e para que serve vão lhe ajudar a entender melhor os exemplos. Você pode fazer o download do projeto de exemplo <a href="http://www.mediafire.com/?7bix11t309o">aqui</a>, o projeto é um projeto comum do Eclipse mas também é um projeto do Maven.

<h3>Relacionamento “muitos-para-muitos”</h3>

Quando estamos iniciando a análise dos nossos sistemas orientados a objetos e começando a montar o banco de dados que vai dar suporte e persistência a esse modelo, é comum que encontremos relacionamentos do tipo “muitos-pra-muitos” (many-to-many – N:N). Nesse tipo de relacionameto entre duas tabelas, nós criamos uma tabela de ligação, que contém sempre um par de colunas, onde cada uma aponta para uma chave primária de uma das tabelas que fazem parte do relacionamento, como no diagrama do nosso exemplo abaixo:

<em>Imagem 1 – Diagrama de exemplo com many-to-many</em>
<a href='http://techbot.me/wp-content/uploads/2008/01/many-to-many-example.jpeg' title='many-to-many-example.jpeg'><img src='http://techbot.me/wp-content/uploads/2008/01/many-to-many-example.jpeg' alt='many-to-many-example.jpeg' /></a>

O nosso relacionamento demonstra que um cliente pode ter vários produtos, algo que poderia ser utilizado em um sistema de inventário.

Vejamos o código em Java utilizando JPA que exemplifica esse diagrama:

<em>Listagem 1 – Persistivel.java</em>
<pre class="brush:java">package alinhavado;

import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.MappedSuperclass;

@MappedSuperclass
public class Persistivel {
	@Id
	@GeneratedValue(strategy=GenerationType.IDENTITY)
	private Long id;
	// métodos get/set
}</pre>

A nossa primeira classe não é exatamente uma classe do sistema, mas uma classe básica para evitar a repetição de código desnecessária, nela nós declaramos o código que define a propriedade “id” que é o identificador de cada linha das tabelas no banco de dados e também definimos o tipo de gerador para a coluna como sendo “identity”, que auto-incrementa automaticamente o valor da coluna.

Como essa classe não representa uma tabela ou uma entidade no sistema mas nós queremos que as suas propriedades existam para as suas subclasses, nós definimos ela com a annotation “@MappedSuperclass”, assim, qualquer objeto que herdar dela vai automaticamente herdar os campos que foram definidos com as anotações do JPA, portanto nenhum dos objetos do nosso exemplo precisa definir uma propriedade “id”, ela já foi definida na superclasse. Usando @MappedSuperclass você evita repetição de código desnecessária par seus objetos e ainda garante que todos vão ter as mesmas propriedades e comportamentos, graças a herança.

Listagem 2 – Cliente.java
<pre class="brush:java">package alinhavado;

import java.util.HashSet;
import java.util.Set;

import javax.persistence.CascadeType;
import javax.persistence.Entity;
import javax.persistence.JoinColumn;
import javax.persistence.JoinTable;
import javax.persistence.ManyToMany;
import javax.persistence.OneToMany;

@Entity
@Table(name=”clientes”)
public class Cliente extends Persistivel {
	private String nome;
	@ManyToMany(cascade=CascadeType.ALL)
	@JoinTable(name="clientes_produtos",
			   joinColumns=  @JoinColumn( name = "cliente_id"),
			   inverseJoinColumns= @JoinColumn(name = "produto_id") )
	private Set<produto> produtos = new HashSet</produto><produto>();
	// métodos get/set
}</pre>

A classe Cliente herda de Persistivel (e consequentemente tem como @Id a propriedade “id” de Persistivel) além de ter uma coleção de produtos relacionados a ela na forma de um relacionamento N:N.

<em>Listagem 3 – Produto.java</em>
<pre class="brush:java">package alinhavado;

import javax.persistence.Entity;
import javax.persistence.Table;

@Entity
@Table(name="produtos")
public class Produto extends Persistivel {
	private String nome;
	//métodos get/set
}</pre>

O nosso objeto Produto também herda de Persistivel e não tem nada além de uma única propriedade, ele não precisa estar relacionado diretamente nem a Cliente nem a Item. Quando estiver fazendo o mapeamento de relacionamentos, evite utilizar relacionamentos bidirecionais, só faça com que os dois lados de um relacionamento se conheçam se isso for estritamente necessário para que o código esteja correto, no nosso exemplo não interessa a um produto saber quais clientes o tem, interessa apenas ao cliente saber quais produtos ele possui, então o melhor a se fazer é não colocar o relacionamento também em Produto.

<h3>Transformando um “muitos-para-muitos” em um “muitos-para-um”</h3>

Continuando com o nosso exemplo, também é comum que conforme o nosso conhecimento sobre o problema em si aumente e a modelagem evolua, esses relacionamentos N:N comecem a tomar corpo de forma que eles deixam de ser apenas um simples relacionamento e se transformam em uma entidade própria, com suas próprias informações e ciclo de vida. Relacionamentos N:N são, no fim, incomuns em sistemas reais, porque na maior parte das vezes nós temos que guardar informações sobre o relacionamento em si e simplesmente colocar novos atributos na tabela de qualquer forma torna o modelo do banco de dados difícil de se lidar e complica o modelo de objetos que vai agir sobre ele. Vejamos um teste de exemplo do código que faria uso dessa modelagem:

<em>Listagem 4 – Teste do relacionamento many-to-many</em>
<pre class="brush:java">Cliente cliente = new Cliente();
cliente.setNome( "José" );

Produto produto = new Produto();
produto.setNome("Camisa de banda");

cliente.getProdutos().add(produto);

EntityManager manager = HibernateLoader.createEntityManager();

manager.getTransaction().begin();
manager.persist( cliente );
manager.getTransaction().commit();

Assert.assertTrue(
	 mensagem( "clientes" ) ,
	 contarClientes(manager) > quantidadeDeClientes );

Assert.assertTrue(
	mensagem( "produtos" ) ,
	contarProdutos(manager) > quantidadeDeProdutos );
manager.close();

manager = HibernateLoader.createEntityManager();
Cliente clienteDoBanco = manager.find( Cliente.class , cliente.getId());
Assert.assertTrue(
	"A quantidade de produtos do cliente deve ser maior que zero",
clienteDoBanco.getProdutos().size() > 0 );
manager.close();</pre>

Testar o código que se escreve é não apenas normal, como também obrigatório pra que se consiga software de qualidade nos dias de hoje, por isso o nosso exemplo é um teste escrito utilizando a biblioteca de testes JUnit. O código cria um Cliente, um Produto e relaciona o produto ao cliente, após isso nós começamos a testar as funcionalidades implementadas, primeiro nós testamos se a quantidade de clientes e produtos no banco de dados se alterou (os métodos “contarProdutos()“ e “contarClientes()”, “mensagem()” são métodos utilitários da nossa classe de testes que você pode conferir nos arquivos desse tutorial, a classe HibernateLoader é apenas uma classe utilitária criada no exemplo para criar os EntityManagers), após garantir que as quantidades foram alteradas, nós vemos se o produto realmente foi relacionado ao cliente. Para fazer esse último teste, nós criamos um novo EntityManager, isso foi necessário porque algumas implementações da JPA (como o Hibernate) mantém os objetos em um cache no próprio EntityManager, portanto se eu tentasse carregar o Cliente com o mesmo EntityManager que o salvou ele simplesmente me retornaria o objeto “cliente” que estava no seu cache em vez de fazer uma nova consulta no banco de dados.

Tomando como base o nosso exemplo anterior, digamos que agora nós precisemos saber exatamente qual a quantidade de um produto específico um cliente tem, com o nosso diagrama anterior nós precisaríamos fazer uma contagem dos produtos relacionados ao cliente específico, o que é possível mas pouco prático, o melhor seria se o próprio relacionamento entre produtos e clientes já trouxesse esse relacionamento, dessa forma nós não precisaríamos ter produtos repetidos no relacionamento como também não seria necessário fazer contagens manuais, no próprio relacionamento a contagem já estaria feita. Vejamos como esse diagrama ficaria agora:

<em>Imagem 2 – Diagrama de exemplo com many-to-one</em>
<a href='http://techbot.me/wp-content/uploads/2008/01/many-to-one-example.jpeg' title='many-to-one-example.jpeg'><img src='http://techbot.me/wp-content/uploads/2008/01/many-to-one-example.jpeg' alt='many-to-one-example.jpeg' /></a>

Agora nós não temos apenas uma tabela que liga os dois objetos, mas uma entidade própria, que tem seus próprios atributos e representação dentro do sistema. O nosso item representa o relacionamento entre as tabelas clientes e produtos, além de conter informações que caracterizam o relacionamento, que no nosso caso é a quantidade de produtos que o cliente tem. A tabela de relacionamento “clientes_produtos” não precisa mais existir, pois a nova tabela “itens” já faz o trabalho dela. Vejamos agora como ficariam os códigos para esse nosso novo modelo:

<em>Listagem 5 – Novo Cliente.java</em>
<pre class="brush:java">package alinhavado;

import java.util.HashSet;
import java.util.Set;

import javax.persistence.CascadeType;
import javax.persistence.Entity;
import javax.persistence.JoinColumn;
import javax.persistence.JoinTable;
import javax.persistence.ManyToMany;
import javax.persistence.OneToMany;
import javax.persistence.Table;

@Entity
@Table(name="clientes")
public class Cliente extends Persistivel {
	private String nome;
	@OneToMany(mappedBy="cliente", cascade=CascadeType.ALL)
	private Set<item> items = new HashSet</item><item>();
	// métodos get/set
}</pre>

O nosso cliente agora não mais se relaciona diretamente com os produtos, agora ele se relaciona com os itens, que por fim vão ser o relacionamento com os produtos. E já que falamos neles, vejamos a nossa classe Item:

<em>Listagem 6 – Item.java</em>
<pre class="brush:java">package alinhavado;

import javax.persistence.CascadeType;
import javax.persistence.Entity;
import javax.persistence.JoinColumn;
import javax.persistence.ManyToOne;
import javax.persistence.Table;
@Entity
@Table(name="itens")
public class Item extends Persistivel {
	private Integer quantidade;
	@ManyToOne(cascade=CascadeType.ALL)
	@JoinColumn(name="produto_id")
	private Produto produto;
	@ManyToOne(cascade=CascadeType.ALL)
	@JoinColumn(name="cliente_id")
	private Cliente cliente;
	// métodos get/set
}</pre>

É na classe Item que reside agora o nosso relacionamento, ela contém uma referência para um Cliente e também para um Produto, além de guardar a quantidade de produtos que esse Item representa. Vejamos o exemplo de código que mostra esse relacionamento sendo utilizado:

<em>Listagem 7 – Exemplo do relacionamento many-to-one</em>
<pre class="brush:java">Cliente cliente = new Cliente();
cliente.setNome( "José" );

Produto produto = new Produto();
produto.setNome("Camisa de banda");

Item item = new Item();
item.setQuantidade( 10 );

item.setCliente(cliente);
item.setProduto(produto);

EntityManager manager = HibernateLoader.createEntityManager();
manager.getTransaction().begin();
manager.persist( item );
manager.getTransaction().commit();

Assert.assertTrue(
	 mensagem( "clientes" ) ,
	 contarClientes(manager) > quantidadeDeClientes );
Assert.assertTrue(
	mensagem( "produtos" ) ,
	contarProdutos(manager) > quantidadeDeProdutos );
Assert.assertTrue(
	mensagem( "itens" ) ,
	contarProdutos(manager) > quantidadeDeItens );

manager.close();

manager = HibernateLoader.createEntityManager();
Cliente clienteDoBanco = manager.find( Cliente.class, cliente.getId());
Assert.assertTrue(
	"A quantidade de itens deve ser maior do que zero",
	clienteDoBanco.getItems().size() > 0);
manager.close();</pre>

Como você pode perceber, as diferenças do código são pequenas, nós criamos um Cliente, um Produto e em vez de simplesmente relacionar os dois, nós criamos um novo objeto, o Item, que guarda uma referência para o Cliente e outra para o Produto, além disso ele também conta com uma propriedade, a quantidade. Seguindo no teste nós validamos que agora existem mais clientes e produtos que antes, além de ver se o item foi realmente relacionado ao cliente em questão no último teste.

<h3>Conclusão</h3>

Relacionamentos N:N podem ser transformados de forma simples em relacionamentos N:1 quando você precisa guardar informações sobre a relação em si, você não deve, em momento algum, criar uma nova coluna em uma tabela de ligação e continuar tratando ela como sendo apenas uma tabela de ligação, se o relacionamento começar a ter propriedades próprias, é porque ele não é mais apenas um relacionamento, mas uma entidade real do seu sistema e deve começar a ser tratado como tal.

<h3>Referencias</h3>

Documentação oficial do Hibernate. Disponível em: <a href="http://hibernate.org/">http://hibernate.org/</a>, acesso em 30/12/2007.</item></produto>
