---
layout: post
title: Implementando uma hashtable em Java
subtitle: é mais fácil do que você imagina
keywords: java, estruturas de dados, hashtables
tags:
- useful
---

Hashtable, aquela estrutura de dados mágica, que a gente usa todo dia mas pensa que é alguma magia que faz ela funcionar,
é na verdade bem mais simples de ser implementada do que se imagina. Comentamos um pouco dos usos e também de como
se implementa essa estrutura de dados no [hipsters.tech](https://hipsters.tech/) então vamos ver agora direto no código 
como seria implementar isso na mão em Java.

A primeira coisa a fazer é entender a estrutura básica que vamos usar, como falamos no podcast, a implementação mais 
simples de hashtables é usar um array de arrays, onde o primeiro array define os buckets onde vamos distribuir os objetos 
e o array interno é o bucket onde adicionamos objetos. Do lado de fora, estamos usando mais memória, já que vamos, 
possívelmente, ter espaços vazios no primeiro array, mas ganhamos na velocidade de se encontrar os objetos dentro da 
estrutura.

