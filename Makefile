#アプリ作時の初回のみ実行かつinuxでしか動かない。
#cloneして開発をする場合は不要です。
new:
	# 必要ファイルのセット
	touch Gemfile
	touch Gemfile.lock
	# 初回rakeが走るとコケるのでコメント
	sed -i s/'ENTRYPOINT'/'#ENTRYPOINT'/ Dockerfile

	# Rilsインストール(APIモード)
	docker compose run api rails new . --force --api --database=postgresql -T -B --skip-webpack-install
	
	# 所有者変更
	ls -la |sed 's/[\t ]\+/\t/g' | cut -f9 | xargs sudo chown -R ${USER}.${USER}

  # 必要な設定ファイルの作成
	cp init/temp/config/application.rb config/
	cp init/temp/config/environments/development.rb config/environments/
	cp init/temp/config/initializers/cors.rb config/initializers/
	cp init/temp/app/controllers/application_controller.rb app/controllers
	cp init/temp/lib/firebase_auth.rb lib/
	echo "$$_database_yml" > config/database.yml
	echo "$$_dot_env_development" > .env.development

  # 必要なgem、不要なgemの設定&インストール
	echo gem \'dotenv-rails\' >> Gemfile
	echo gem \'rack-cors\' >> Gemfile
	echo gem \'jwt\' >> Gemfile
	sed -i s/'gem "web-console"'/'# gem "web-console"'/ Gemfile
	sed -i s/'#ENTRYPOINT'/'ENTRYPOINT'/ Dockerfile
	docker compose run api bundle install

  # Railsの初期タスクの実行
	docker compose up -d
	docker compose run api sh -c 'sleep 3 && rake db:create'

  # サンプルアプリの作成
	docker compose run api rails g scaffold user
	docker compose run api rake db:migrate

  # 終了
	docker compose down

define _database_yml
default: &default
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  timeout: 5000

development:
  <<: *default
  host: <%= ENV['DATABASE_HOST'] %>
  username: <%= ENV['DATABASE_USER'] %>
  password: <%= ENV['DATABASE_PASSWORD'] %>
  database: <%= ENV['DATABASE_NAME'] %>

test:
  <<: *default
  host: <%= ENV['DATABASE_HOST'] %>
  username: <%= ENV['DATABASE_USER'] %>
  password: <%= ENV['DATABASE_PASSWORD'] %>
  database: <%= ENV['DATABASE_NAME_TEST'] %>

production:
  <<: *default
  host: <%= ENV['DATABASE_HOST'] %>
  username: <%= ENV['DATABASE_USER'] %>
  password: <%= ENV['DATABASE_PASSWORD'] %>
  database: <%= ENV['DATABASE_NAME_PRODUCTION'] %>
endef
export _database_yml

define _dot_env_development
RAILS_LOG_TO_STDOUT=true

DATABASE_HOST=db
DATABASE_USER=postgres
DATABASE_PASSWORD=password
DATABASE_NAME=local_db
DATABASE_NAME_TEST=test_db
DATABASE_NAME_PRODUCTION=prod_db

AWS_REGION=
AWS_ACCOUNT_ID=

FIREBASE_PROJECT_ID=
endef
export _dot_env_development

build:
	docker compose build

up:
	docker compose up

down:
	docker compose down
