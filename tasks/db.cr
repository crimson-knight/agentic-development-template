#!/usr/bin/env crystal

require "micrate"
require "../config/database"

Micrate::DB.connection_url = ENV["DATABASE_URL"]? || "postgres://postgres:@localhost:5432/agentc_app_template_oss_development"
Micrate::Cli.run