# Database tasks
db-create:
	createdb agentc_app_template_oss_development

db-drop:
	dropdb agentc_app_template_oss_development

db-migrate:
	micrate up

db-rollback:
	micrate down

db-seed:
	crystal run db/seeds.cr

db-reset: db-drop db-create db-migrate db-seed

# Application tasks
install:
	shards install

build:
	shards build

run:
	crystal run src/agentc_app_template_oss.cr

test:
	crystal spec

.PHONY: db-create db-drop db-migrate db-rollback db-seed db-reset install build run test