---
layout: post
title: Implementando uma hashtable em Java
subtitle: é mais fácil do que você imagina
keywords: java, estruturas de dados, hashtables
tags:
- useful
---

*Você encontra o código fonte completo discutido aqui em [github.com/mauricio/hashtable](https://github.com/mauricio/hashtable).*

Hashtable, aquela estrutura de dados mágica, que a gente usa todo dia mas pensa que é alguma magia que faz ela funcionar,
é na verdade bem mais simples de ser implementada do que se imagina. Comentamos um pouco dos usos e também de como
se implementa essa estrutura de dados [nesse episódio do hipsters.tech](https://hipsters.tech/) então vamos ver agora direto no código 
como seria implementar isso na mão em Java.

A primeira coisa a fazer é entender a estrutura básica que vamos usar, como falamos no podcast, a implementação mais 
simples de hashtables é usar um array de arrays, onde o primeiro array define os buckets onde vamos distribuir os objetos 
e o array interno é o bucket onde adicionamos objetos. Do lado de fora, estamos usando mais memória, já que vamos ter 
espaços vazios no primeiro array, mas ganhamos na velocidade de se encontrar os objetos dentro da estrutura.

## Implementando o objeto entry

Como estamos falando de um objeto que vai salvar pares de chave/valor, precisamos de um objeto que represente esses
pares. Java já define uma interface pra isso, `java.util.Map.Entry`, então vamos implementar essa interface pra representar
os nossos pares de chave/valor:

```java
public class Entry<K, V> implements Map.Entry<K, V> {

    private final K key;
    private V value;

    public Entry(K key, V value) {
        this(key);
        this.value = value;
    }

    public Entry(K key) {
        if (key == null) {
            throw new IllegalArgumentException("key can't be null");
        }
        this.key = key;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof Entry)) return false;
        Entry<?, ?> entry = (Entry<?, ?>) o;
        return key.equals(entry.key) &&
                Objects.equals(value, entry.value);
    }

    @Override
    public int hashCode() {
        return this.key.hashCode();
    }

    @Override
    public K getKey() {
        return this.key;
    }

    @Override
    public V getValue() {
        return this.value;
    }

    @Override
    public V setValue(V value) {
        var oldValue = this.value;
        this.value = value;
        return oldValue;
    }

}
```

A implementação é uma classe com dois atributos, `key` e `value`, onde `key` nunca muda e não pode ser `null`, a única coisa
que vai mudar é o valor pro qual cada chave vai apontar. Essa classe é a que vamos usar como conteúdo da nossa hashtable, 
então vamos ter um array de arrays de `Entry<K,V>`.

## Iniciando a hashtable

O ponto de entrada principal da nossa hashtable vai ser a implementação do método `put`, que coloca um par de chave/valor
na nossa tabela, então vamos construir ele da forma mais simples possível no momento:

```java
package tech.hipsters;

import java.util.ArrayList;
import java.util.List;

public class Hashtable<K, V> {

    private List<List<Entry<K, V>>> buckets;

    public Hashtable() {
        this(16);
    }

    public Hashtable(int s) {
        this.buckets = new ArrayList<>(s);
        for (int x = 0; x < s; x++) {
            buckets.add(null);
        }
    }

    public V put(K key, V value) {
        throwIfNull(key);

        var entry = this.findOrCreateEntry(key);
        var oldValue = entry.getValue();
        entry.setValue(value);

        return oldValue;
    }

    private int bucketIndexFor(K key) {
        return key.hashCode() % this.buckets.size();
    }

    private Entry<K, V> findOrCreateEntry(K key) {
        var bucketIndex = this.bucketIndexFor(key);
        var bucket = this.buckets.get(bucketIndex);
        if (bucket == null) {
            bucket = new ArrayList<>();
            this.buckets.set(bucketIndex, bucket);
        }

        for (var entry : bucket) {
            if (key.equals(entry.getKey())) {
                return entry;
            }
        }

        var entry = new Entry<K,V>(key);
        bucket.add(entry);
        return entry;
    }

    static void throwIfNull(Object key) {
        if (key == null) {
            throw new NullPointerException("key must not be null");
        }
    }

}
```

Falamos várias vezes sobre usar arrays de arrays pra nossa tabela e aqui temos um `List<List<Entry<K, V>>>`, por que?

Porque trabalhar com arrays genéricos (e arrays de arrays genéricos) em Java é terrível, então aqui tomamos um atalho
pra deixar o código um pouco mais legível, mas vamos usar as listas quase como se fossem arrays.

Temos dois métodos privados importantes aqui, `bucketIndexFor` e `findOrCreateEntry`. O primeiro serve pra descobrir em 
qual bucket a chave em questão vai ser encontrada. Nossa lógica aqui é usar o resto da divisão do resultado do
`hashCode` da chave pelo tamanho do nosso array de buckets (que nesse momento é 16). Vamos receber um número de 0 a 15,
exatamente a posição no array onde a chave deve ficar. Essa é a grande vantagem de usar hashtables, em vez de percorrer 
as 16 posicões, com uma única operarão matemática (que é barata) nós já sabemos onde procurar a nossa chave.

Já em `findOrCreateEntry` procuramos se já existe um array na posição onde a chave vai estar, se ele não existir,
criamos um novo array e colocamos ele na posição. Depois navegamos o array pra tentar achar um par com a chave que estamos 
procurando, se ela for encontrada, é retornada. Se sairmos do laço, não encontramos um par pra essa chave então
ela precisa ser adicionada no bucket pra ser retornada.

Com isso a implementacão de `put` fica mínima, usamos `findOrCreateEntry` pra encontrar o par, colocamos o novo valor nele
e retornamos o valor anterior, que vai ser `null` pra novas chaves. Veja que esse método serve tanto pra novas chaves 
como chaves que já existem, não precisamos de um caso especial pra novas chaves.

Agora vamos implementar mais alguns métodos necessários a nossa tabela, `get` (pra pegar um valor dada uma chave), `containsKey` (pra saber se uma chave existe na tabela) e `remove` (pra remover uma chave da tabela):

```java
package tech.hipsters;

import java.util.ArrayList;
import java.util.List;

public class Hashtable<K, V> {
    
    // métodos anteriores 

    private Entry<K, V> findEntry(K key) {
        var bucket = this.findBucket(key);
        if (bucket == null || bucket.isEmpty()) {
            return null;
        }

        for (var entry : bucket) {
            if (key.equals(entry.getKey())) {
                return entry;
            }
        }

        return null;
    }

    private List<Entry<K, V>> findBucket(K key) {
        return this.buckets.get(this.bucketIndexFor(key));
    }

    public V get(K key) {
        throwIfNull(key);

        var entry = this.findEntry(key);

        if (entry != null) {
            return entry.getValue();
        }

        return null;
    }

    public boolean containsKey(K key) {
        throwIfNull(key);

        return this.findEntry(key) != null;
    }

    public V remove(K key) {
        throwIfNull(key);

        var bucket = this.findBucket(key);
        if (bucket == null || bucket.isEmpty()) {
            return null;
        }

        for (var it = bucket.iterator(); it.hasNext();) {
            var next = it.next();
            if (key.equals(next.getKey())) {
                it.remove();
                return next.getValue();
            }
        }

        return null;
    }

}
```

Temos agora dois novos métodos privados, `findBucket` e `findEntry`. O primeiro é um atalho pra achar um bucket
dado uma chave específica, usando `bucketIndexFor`. O segundo já é um pouco mais complexo, porque agora queremos encontrar
um par dado uma chave mas não queremos adicionar essa chave se ela não existir. Isso serve pra métodos que precisam saber
se uma chave está na tabela sem alterá-la como fazemos em `findOrCreateEntry`. 

No método, começamos procurando o bucket, se ele for `null` ou vazio, já podemos desistir da busca e simplesmente retornar
`null`. Se o bucket não for vazio, navegamos nele pra tentar encontrar a chave e retornar o par se ele for encontrado.

Temos então os pedacos necessários pra construir os métodos `containsKey`, `get` e `remove` na tabela. `containsKey` é
o mais simples, só precisamos saber se já existe um objeto `Entry` pra chave procurada, então
é simplesmente saber se o `Entry` que `findEntry` retornou é `null` ou não.

Já em `get` temos um pouco mais de lógica porque precisamos saber se o `Entry` retornado é diferente de `null` pra poder 
chamar `getValue`, senão simplesmente retornamos `null`. Um efeito colateral do retorno desse método é que é impossível
saber se a chave existe ou não usando somente `get` já que é possível ter uma chave com `null` como valor, então você
teria que usar `containsKey` e `get` pra ter certeza que o valor não existe de verdade na tabela.

`remove` é o caso mais complexo dos 3 métodos que implementamos aqui. Primeiro buscamos pelo bucket onde a chave
estaria, se ele existir e não for vazio, usamos um `Iterator` pra encontrar exatamente onde a chave está e removemos ela,
retornando o valor que estava atualmente na chave. Poderíamos usar `findEntry` e então `findBucket` pra descobrir onde está
o objeto específico e usar `remove` no próprio bucket se ele existisse, mas isso aumenta as operações que precisamos executar.
A implementação usando `Iterator` é mais rápida (mesmo que seja quase impossível de medir a diferença).

## Implementando uma hashtable que cresce dinamicamente 

Temos então uma hashtable implementada de forma simples usando um array de arrays de pares chave/valor. Dá pra parar 
por aqui, mas a nossa tabela tem um problema, ela tem um tamanho fixo e o ideal seria que ela crescesse conforme novos
objetos fossem adicionados a ela pra que não tenhamos um excesso de colisões com buckets muito grandes.

Uma das formas de definir isso é usar uma razão entre a quandidade de objetos na tabela e a quantidade de buckets. Aqui temos
que considerar mais uma vez o espaco em memória versus a quantidade de operacões que queremos fazer ao chamar métodos na nossa
tabela. Por padrão, o `HashMap` no Java usa 75% como valor base pra essa razão, o que quer dizer que no geral a quantidade 
de buckets é 75% do total de objetos. Ou seja, se a sua tabela tem 100 objetos, ela teria pelo menos 75 buckets.

Então, sempre que houver adição de chaves na tabela, devemos verificar se é necessário aumentá-la. Nosso código precisa de algumas adicões:

* Um contador pra quantidade de chaves que temos na tabela;
* Aumentar ou diminuir esse contador sempre que uma alteracão acontecer;
* Método pra reconstruir toda a tabela quando a razão entre a quantidade de buckets e chaves na tabela ultrapassar um valor definido;

Vamos assumir o mesmo valor do Java, 75%, como a quantidade de buckets que vamos ter pra quantidade de chaves na tabela, 
sempre que ultrapassarmos esse valor, a tabela vai ser recriada com o dobro do tamanho atual. Vejamos como seria a implementacão
dessas mudancas no código:

```java
package tech.hipsters;

import java.util.ArrayList;
import java.util.List;

public class Hashtable<K, V> {

    private static final float loadFactor = 0.75F;

    private List<List<Entry<K, V>>> buckets;
    private int count;

    public Hashtable(int s) {
        this.buckets = new ArrayList<>(s);
        fill(this.buckets, s);
    }

    public V put(K key, V value) {
        throwIfNull(key);

        var entry = this.findOrCreateEntry(key);
        var oldValue = entry.getValue();
        entry.setValue(value);

        this.rehashIfNeeded();

        return oldValue;
    }

    public V remove(K key) {
        throwIfNull(key);

        var bucket = this.findBucket(key);
        if (bucket == null || bucket.isEmpty()) {
            return null;
        }

        for (var it = bucket.iterator(); it.hasNext();) {
            var next = it.next();
            if (key.equals(next.getKey())) {
                it.remove();
                this.count--;
                return next.getValue();
            }
        }

        return null;
    }

    private Entry<K, V> findOrCreateEntry(K key) {
        var bucketIndex = this.bucketIndexFor(key);
        var bucket = this.buckets.get(bucketIndex);
        if (bucket == null) {
            bucket = new ArrayList<>();
            this.buckets.set(bucketIndex, bucket);
        }

        for (var entry : bucket) {
            if (key.equals(entry.getKey())) {
                return entry;
            }
        }

        var entry = new Entry<K,V>(key);
        bucket.add(entry);
        this.count++;

        return entry;
    }

    private void rehashIfNeeded() {
        if (this.count > 0 && ((this.buckets.size() / (float) this.count) < loadFactor)) {
            var oldBuckets = this.buckets;
            this.count = 0;
            var capacity = oldBuckets.size() * 2;
            this.buckets = new ArrayList<>(capacity);
            fill(this.buckets, capacity);

            for (var bucket : oldBuckets) {
                if (bucket != null) {
                    for (var entry : bucket) {
                        this.put(entry.getKey(), entry.getValue());
                    }
                }
            }
        }
    }

    static <E> void fill(List<E> items, int count) {
        for (int x = 0; x < count; x++) {
            items.add(null);
        }
    }

}

```

`rehashIfNeeded` é a mudança principal aqui. O método começa verificando se a razão entre o número de objetos e o número 
de buckets passa de `0.75`, que acontece quando temos 22 objetos adicionados (16 dividido por 22 é `0.72...`). Copiamos os
buckets atuais pra uma variável temporária, zeramos o contador e criamos uma nova coleção de buckets, com o dobro do tamanho 
atual, preenchemos ela com `nulls`, depois adicionamos todos os itens que existiam na coleção anterior nela, um a um.

Fazer o rehash de uma hashtable é uma operação cara, então se você vai trabalhar com tabelas grandes, o ideal é criar elas
já com o tamanho que você vai utilizar pra evitar várias operações de rehash conforme os objetos são adicionados na tabela.

E cá estamos com uma tabela de hash funcional, que cresce conforme adicionamos objetos nela!
