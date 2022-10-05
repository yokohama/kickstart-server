# kickstart-server

## 目次
1. 前提
2. リポジトリをforkする
3. プロジェクトの作成
4. .env.developmentの準備
5. 動作確認
6. imageをECR( local / dev / prod )にアップロード
7. CDKでインフラを構築をする
8. シークレットをセット
9. 初回のdb:migrate
10. aws上のdev prodに変更のデプロイ

## 1. 前提
- [こちら](https://github.com/yokohama/kickstart#kickstart-1)で、awsの以下の情報が取得されている必要が有ります。
- [こちら](https://github.com/yokohama/kickstart-front#kickstart-front-3-1)で、firebaseの以下の情報が取得されている必要が有ります。
- [こちら](https://github.com/yokohama/kickstart-cdk)で、`7. aws上にECRのリポジトリ( local / dev / prod )作成`までが完了していることが前提となります。

| 参照名 | 使用箇所 | 取得方法 | ステータス |
| :--- | :--- | :--- | :--- |
| aws_access_key_id | api / github / actions / secretes と、.env.development |  | 取得済 |
| aws_secret_access_key | api / github / actions / secretes |  | 取得済 |
| aws_region | api / github / actions / secretes と、.env.development |  | 取得済 |
| firebase projectId | api / github / actions / secretes と、.env.development |  | 取得済 |

## 2. リポジトリをforkする
### 1. githubからforkする。fork先名は解りやすく同じ名前にして下さい。もし変更する場合は、以降`kickstart-server`を`変更した名前`に読み替えて作業をおこなって下さい。
### 2. forkした先のリポジトリに、`development`ブランチを作成して下さい。

## 3. プロジェクトの作成
```
$ cd ./kickstart-server
$ make new
```

## 4. .env.developmentの準備
- .env.developmentの各変数に、1で取得した情報を記入します。
```
RAILS_LOG_TO_STDOUT=true                                                           

DATABASE_HOST=db                                                                   
DATABASE_USER=postgres                                                             
DATABASE_PASSWORD=password                                                         
DATABASE_NAME=local_db                                                             
DATABASE_NAME_TEST=test_db                                                         

AWS_REGION=＜1で取得した情報＞                                                         
AWS_ACCOUNT_ID=＜1で取得した情報＞                                                        

FIREBASE_PROJECT_ID=＜1で取得した情報＞
```

## 5. 動作確認
```
$ docker comopse up
```
- これで、localhost:3000にアクセスして動作していることを確認して下さい。

<a id="kickstart-server-6" />

## 6. imageをECR( local / dev / prod )にアップロード
```
$ cd ./kickstart-server
$ TARGET_ENV=local ./ops/ecr_push.sh
$ TARGET_ENV=dev ./ops/ecr_push.sh
$ TARGET_ENV=prod ./ops/ecr_push.sh
```

## 7. CDKでインフラを構築をする
- [kickstart-cdk](https://github.com/yokohama/kickstart-cdk#kickstart-cdk-8)から来た方は、これでimageがアップされたので、[こちら](https://github.com/yokohama/kickstart-cdk#kickstart-cdk-8)に戻り、引き続きインフラ構築を進めることが出来ます。
- このチュートリアルから開始した方は、8に進む前に[kickstart-cdk](https://github.com/yokohama/kickstart-cdk)からインフラの構築を進めて、指示に従い戻ってきて下さい。

## 8. シークレットをセット
### 1. GitHub Actionsにシークレットをセット

<img src="https://user-images.githubusercontent.com/1023421/193737973-d14919b0-a00f-484c-9709-87bb569bd264.png" width="400" />

### 2. 以下の変数名と値をセットします。
| 変数名 | 参照名 |
| :--- | :--- |
| AWS_ACCESS_KEY_ID | aws_access_key_id |
| AWS_SECRET_ACCESS_KEY | aws_secret_access_key |
| AWS_REGION | aws_region  |

<img src="https://user-images.githubusercontent.com/1023421/193738601-26371df1-7baa-4376-800e-8977d4fb8b82.png" width="400" />

## 9. 初回のdb:migrate
- 初回はaws上の、`local`、`dev`、`prod`全ての環境に対して、`db:migrate`を実行します。
- 2度目以降は、`dev`、`prod`の`db:migrate`は、各ブランチへのマージの際にGitHub Actionsにより自動で行われます。
- `local`は、kickstart-server(Rails)というよりかCDKの実験場の様なものなので、GitHub Actionsに乗ったデプロイはしません。
- Railsで開発したimageをaws上の`local`にRailsをデプロイしたい場合は、手動で上記[kickstart-server-6](#kickstart-server-6)の、`TARGET_ENV=local`のコマンドを実行した後に、以下のコマンドで`db:migrate`を実行します。
- 
```
$ cd ./kickstart-server
$ TARGET_ENV=local ./ops/rails_db_migrate.sh
$ TARGET_ENV=dev ./ops/rails_db_migrate.sh
$ TARGET_ENV=prod ./ops/rails_db_migrate.sh
```

## 10. aws上のdev prodに変更のデプロイ
- こちらは、上記のlocalと違い、GitHub Actionsでデプロイされます。

### 1. ローカルのコンテナを起ち上げます。
```
$ cd ./kickstart-server
$ cd docker compose up
```

### 2. productリソースを作成する
```
$ docker compose run --rm api rails g scaffold product
$ docker compose run --rm api rails db:migrate
```

### 3. development環境にデプロイする
```
$ git add .
$ git commit -m 'デプロイテスト'
$ git push origin development
```

### 4. GitHub Action上でデプロイの進捗確認

<img src="https://user-images.githubusercontent.com/1023421/193828653-7d3ca48b-e696-43bf-badf-5e39f034f9fa.png" width="400" />

### 5. ローカルでfargate上（dev）のログを確認
```
$ ./ops/rails-log.sh dev
```




```

