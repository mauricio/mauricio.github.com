---
layout: post
title: Explicando optimistic locking
subtitle: Escrever SQL na mão continua sendo muito complicado
keywords: golang, sql, orm
tags:
- useful
---

[O código listado aqui está nesse repositório do github](https://github.com/mauricio/optimistic-locking).

Dia desses depois de ver outra treta na comunidade Golang dizendo que tem que escrever SQL na mão mesmo mandei:

<blockquote class="twitter-tweet"><p lang="pt" dir="ltr">Oi você bichão fodão que não usa ORM porque é ninja demais, lembrou de implementar optimistic locking pros seus objetos ou nem sabe o que é isso? 🤡</p>&mdash; Maurício Linhares (@mauriciojr) <a href="https://twitter.com/mauriciojr/status/1433468333752475653?ref_src=twsrc%5Etfw">September 2, 2021</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

E tinha gente perguntando o que era _optimistic locking_, que é um conceito importante pra quem usar bancos de dados, 
ainda mais nos ambientes de sistemas distribuídos que muita gente trabalha hoje em dia. A idéia de _optimistic locking_ (também conhecido como [Optimistic concurrency control](https://en.wikipedia.org/wiki/Optimistic_concurrency_control) - OCC) é que em muitos casos, conflitos na hora de alterar dados em sistemas são incomuns, então incorrer no custo e complexidade de usar transações diretamente nos bancos de dados não vale a pena. 

A implementação mais comum é a de que os objetos que você vai alterar durante uma transação tenham um numero/valor de versão associados a eles e sempre que você for fazer uma alteração, você verificaria se o numero de versão que você tem externamente é o mesmo que está salvo no banco de dados. Se ambos forem iguais, você tem a versão atual do objeto e pode alterar ele sem correr o risco de perder dados, se não forem, você sabe que a versão que você tem está desatualizada e não é seguro fazer a alteração.

Um dos usos principais desse tipo de solução é pra aplicações web, onde não é viável manter uma transação do banco de dados aberta enquanto o usuário está entrando informações pra um dado específico. Imagine alguém atualizando os dados de um usuário X no sistema, essa pessoa pode abrir o formulário, sair pra tomar um café, conversar com um colega ou simplesmente ir pra casa no fim do expediente e deixar o formulário aberto no seu navegador. Se você mantivesse uma transação no banco de dados aberta pra esses dados durante esse tempo todo, rapidamente seria impossível fazer qualquer alteração no banco.

Então, transações pra operações longas ou que nós não temos controle sobre quanto tempo elas vão durar são inviáveis e é aqui que temos outro problema, onde quem desenvolve simplesmente ignora a transação longa e simplesmente deixa o código fazer a alteração somente quando o usuário envia o formulário do navegador. Vejamos a sequência:

* Usuário 1: Abre o formulário do cliente X;
* Usuário 1: Sai pra almoçar;
* Usuário 2: Abre o formulário do cliente X;
* Usuário 2: Altera informações do cliente X e envia o formulário;
* Usuário 1: Volta do almoço, altera informações do cliente X e envia o formulário;

Nesse momento, se você não tem transações longas e simplemente grava tudo na hora que o formulário foi enviado, é bem provável que todas as mudanças feitas pelo *Usuário 2* foram perdidas, é um problema comum com bancos de dados que é chamado de _atualização perdida_ (lost update). E é nesse caso que uma solução de _optimistic locking_ é a solução ideal, onde temos uma transação longa fora do banco de dados e ainda queremos perceber quando alguém está mandando informações desatualizadas pro sistema.

# Implementação

```go
package optimistic_locking

import (
	"context"
	"io"
)

const (
	PostsTable       = "posts"
	CreatePostsTable = `DROP TABLE IF EXISTS posts;
CREATE TABLE posts (uuid VARCHAR NOT NULL PRIMARY KEY, title TEXT NOT NULL, content TEXT NOT NULL, version VARCHAR NOT NULL);`
)

type Post struct {
	UUID    string
	Title   string
	Content string
	Version string
}

type Posts interface {
	io.Closer
	// Find tries to find a post, returns an error if the post does not exist
	Find(ctx context.Context, uuid string) (*Post, error)
	Save(ctx context.Context, post *Post) error
	List(ctx context.Context) ([]*Post, error)
	// Delete deletes a post and returns whether it actually found the post to be deleted or not.
	Delete(ctx context.Context, uuid string) (bool, error)
	Migrate(ctx context.Context) error
}
```

Temos aqui a classe que vamos usar como exemplo e a interface que define como vamos mapear essa classe pro banco de dados. O tipo de banco de dados que vai ser utilizado não tem muita relevância, você vai enfrentar esse tipo de problema em praticamente qualquer banco de dados, seja SQL ou NoSQL. Alguns, entretanto, tem suporte direto a _optimistic locking_ então a solução ficaria mais simples.

Vejamos uma implementação que *não* faz uso de _optimistic locking_ primeiro:

```go
package optimistic_locking

import (
	"context"
	"database/sql"
	"fmt"
	sq "github.com/Masterminds/squirrel"
	"github.com/google/uuid"
	_ "github.com/mattn/go-sqlite3"
	"github.com/pkg/errors"
)

func NewBrokenPosts(path string) (*BrokenSqlitePosts, error) {
	db, err := sql.Open("sqlite3", path)
	if err != nil {
		return nil, err
	}

	return &BrokenSqlitePosts{
		db: db,
	}, err
}

type BrokenSqlitePosts struct {
	db *sql.DB
}

// outros métodos

func findWith(ctx context.Context, runner sq.BaseRunner, uuid string) (*Post, error) {
	scanner := sq.Select("uuid", "title", "content", "version").
		From(PostsTable).
		Where("uuid = ?", uuid).
		RunWith(runner).
		QueryRowContext(ctx)

	post := &Post{}

	if err := scanner.Scan(&post.UUID, &post.Title, &post.Content, &post.Version); err != nil {
		if err == sql.ErrNoRows {
			return nil, errors.Wrapf(err, "could not find post with UUID: %v", uuid)
		}

		return nil, err
	}

	return post, nil
}

func (s *BrokenSqlitePosts) Save(ctx context.Context, post *Post) (err error) {
	if post.UUID == "" {
		post.UUID = uuid.New().String()

		return assertAffected(sq.Insert(PostsTable).
			Columns("uuid", "title", "content", "version").
			Values(post.UUID, post.Title, post.Content, post.Version).
			RunWith(s.db).
			PlaceholderFormat(sq.Dollar).
			ExecContext(ctx))
	}

	return assertAffected(sq.Update(PostsTable).
		Where(sq.Eq{"uuid": post.UUID}).
		Set("title", post.Title).
		Set("content", post.Content).
		Set("version", post.Version).
		RunWith(s.db).
		ExecContext(ctx))
}

func assertAffected(r sql.Result, err error) error {
	if err != nil {
		return err
	}

	affected, err := r.RowsAffected()
	if err != nil {
		return err
	}

	if affected != 1 {
		return fmt.Errorf("expected only %v row to be affected but %v rows were affected", 1, affected)
	}

	return nil
}
```

O método mais importante aqui é o `Save`, quando é um objeto sem `UUID`, colocamos um UUID nele e inserimos ele no banco com um 
`INSERT`. Quando ele tem um UUID assumimos que ele já existe no banco de dados e geramos um `UPDATE`. Em ambos os casos, verificamos
que uma linha foi modificada no banco, pra garantir que ambos os comandos realmente causaram uma alteração. Aqui não fazemos nenhuma
verificação pra garantir que estamos atualizando a versão correta da linha na tabela, então esse código vai sofrer do problema
de *atualizações perdidas*.

Vejamos então uma implementação que faz a verificação de versões antes de atualizar a linha da tabela:

```go
package optimistic_locking

import (
	"context"
	"database/sql"
	"fmt"
	sq "github.com/Masterminds/squirrel"
	"github.com/google/uuid"
	"github.com/rs/zerolog/log"
)

func NewVersionedPosts(path string) (*VersionedPosts, error) {
	posts, err := NewBrokenPosts(path)
	if err != nil {
		return nil, err
	}

	return &VersionedPosts{
		BrokenSqlitePosts: posts,
	}, nil
}

type VersionedPosts struct {
	*BrokenSqlitePosts
}

func (s *VersionedPosts) Save(ctx context.Context, post *Post) (err error) {
	if post.UUID == "" {
		post.Version = uuid.New().String()
		return s.BrokenSqlitePosts.Save(ctx, post)
	}

	tx, err := s.db.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelSerializable})
	if err != nil {
		return err
	}

	defer func() {
		if err != nil {
			if txErr := tx.Rollback(); txErr != nil {
				log.Err(txErr).Str("uuid", post.UUID).Msg("failed to rollback transaction")
			}
		}
	}()

	result, err := findWith(ctx, tx, post.UUID)
	if err != nil {
		return err
	}

	if result.Version != post.Version {
		return fmt.Errorf("version mismatch: you're trying to update post with version %v but the current DB version is %v", post.Version, result.Version)
	}

	post.Version = uuid.New().String()

	if err := assertAffected(sq.Update(PostsTable).
		Where(sq.Eq{"uuid": post.UUID}).
		Set("title", post.Title).
		Set("content", post.Content).
		Set("version", post.Version).
		RunWith(tx).
		ExecContext(ctx)); err != nil {
		return err
	}

	return tx.Commit()
}
```

Aqui, quando vamos executar um `UPDATE`, iniciamos uma transação no banco, carregamos o objeto atual do banco de dados e 
verificamos se o valor de `Version` no banco de dados é o mesmo do objeto que recebemos pra atualizar. Se as versões
não forem as mesmas, retornamos um erro e fazemos `rollback` na transação, se elas forem iguais, alteramos a versão atual
e atualizamos o objeto no banco.

A implementação da solução vai ser dependente do banco de dados que você estiver utilizando. Como o SQLite não tem suporte
a operações como `SELECT ... FOR UPDATE` pra travar uma ou um grupo de linhas da tabela durante uma transação, a única
opção é fazer com que a transação seja `SERIALIZABLE`, mas cada banco de dados vai ter uma forma específica de lidar com 
esse problema. O ideal é procurar como funciona o travamento de linhas/documentos específicos em uma tabela/coleção pro
seu banco de dados e usar essa funcionalidade pra implementar esse método.

Podemos verificar o comportamento com um teste de integração:

```go
package optimistic_locking

import (
	"context"
	"encoding/base64"
	"fmt"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"io/ioutil"
	"math/rand"
	"os"
	"testing"
)

var (
	testCtx = context.Background()
)

func withPosts(t *testing.T, factory func(path string) (Posts, error), callback func(t *testing.T, p Posts)) {
	file, err := ioutil.TempFile("", "prefix")
	if err != nil {
		t.Fatalf("failed to create tmp file: %v", err)
	}
	defer os.Remove(file.Name())

	posts, err := factory(file.Name())
	if err != nil {
		t.Fatalf("failed to create Posts: %v", err)
	}

	if err := posts.Migrate(testCtx); err != nil {
		t.Fatalf("failed to migrate database: %v", err)
	}

	callback(t, posts)
}

func randomString(t *testing.T) string {
	bytes := make([]byte, 128)
	_, err := rand.Read(bytes)
	require.NoError(t, err)

	return base64.StdEncoding.EncodeToString(bytes)
}

func samplePost(t *testing.T) *Post {
	return &Post{
		Title:   randomString(t),
		Content: randomString(t),
	}
}

func TestVersionedPosts_Save(t *testing.T) {
	tt := []struct {
		name    string
		err     string
		factory func(path string) (Posts, error)
	}{
		{
			name: "with versioned posts",
			err:  "version mismatch: you're trying to update post with version",
			factory: func(path string) (Posts, error) {
				return NewVersionedPosts(path)
			},
		},
		{
			name: "with broken posts",
			factory: func(path string) (Posts, error) {
				return NewBrokenPosts(path)
			},
		},
	}

	for _, ts := range tt {
		t.Run(ts.name, func(t *testing.T) {
			withPosts(t, ts.factory, func(t *testing.T, p Posts) {
				post := samplePost(t)

				require.NoError(t, p.Save(testCtx, post))

				post.Title = "new title"
				require.NoError(t, p.Save(testCtx, post))

				savedPost, err := p.Find(testCtx, post.UUID)
				require.NoError(t, err)

				savedPost.Content = "new content"
				require.NoError(t, p.Save(testCtx, savedPost))

				post.Content = "this will overwrite"
				err = p.Save(testCtx, post)

				if ts.err != "" {
					require.NotNil(t, err)
					assert.Contains(t, err.Error(), ts.err)
				} else {
					require.NoError(t, err)
				}
			})
		})
	}
}
```

No teste, quando usamos a implementação `VersionedPosts`, ele tem que falhar com o erro avisando que as versões não são
as mesmas, já na implementação que usa `BrokenSqlitePosts` ele simplesmente ignora que está atualizando a versão errada
do objeto e sobrescreve a alteração que aconteceu antes. 

Se você implementou código que faz esse mapeamento de objetos pra qualquer tipo de banco de dados em uma aplicação que
tem esse uso de transações longas ou alterações concorrentes dos mesmos recursos (o que é extremamente comum na maior
parte dos sistemas atuais), o ideal é ter algum tipo de _optimistic locking_ implementado pra esses objetos. Essa é 
uma das maiores vantagens de se usar ferramentas de mapeamento objeto-relacional (ou até pra outros bancos de objetos/documentos), 
já que elas geralmente tem uma implementação desse tipo de solução.

É sempre importante lembrar que existe uma barreira de tradução (_impedance mismatch_) entre a sua aplicação que geralmente
trabalha com objetos/estruturas de dados em memória e onde os dados estão realmente persistidos no banco. O trabalho de 
escrever uma camada que faz essa tradução é grande e complexo, porque ele precisa considerar todos esses casos especiais
que não ficam visíveis quando estamos escrevendo o código que interage com o banco de dados até termos que considerar os
diversos modos diferentes de uso que vão acontecer, então no geral é melhor usar uma ferramenta que faça esse mapeamento
do que escrever todo o código de tradução, seja SQL ou algum outro banco, na mão, porque muitas vezes podemos não considerar
problemas que já foram resolvidos por outras pessoas.

# Outras soluções

Apesar de ser uma solução comum, _optimistic locking_ não é a melhor solução pra todos os problemas de concorrência em 
transações longas, existem outras soluções conhecidas, especialmente os 
[conflict-free replicated data type (CRDTs)](https://en.wikipedia.org/wiki/Conflict-free_replicated_data_type),
que são tipos que operam de forma comutativa, onde a ordem das operações não afeta o produto final. Serviços como 
Google Docs implementam estruturas de dados parecidas pra garantir a edição paralela de documentos e a maior parte dos 
carrinhos de compra de comércio eletrônico também precisam implementar soluções parecidas pra que as várias alterações no
carrinho pareçam atômicas mesmo que elas não sejam.
