# About Application.cr File
#
# This is Amber application main entry point. This file is responsible for loading
# initializers, classes, and all application related code in order to have
# Amber::Server boot up.
#
# > We recommend not modifying the order of the requires since the order will
# affect the behavior of the application.

require "amber"
require "asset_pipeline"

require "./settings"
require "./logger"
require "./i18n"
require "./database"
require "./initializers/**"

require "../src/controllers/application_controller"
require "../src/controllers/**"
require "../src/models/**"
require "../src/models/personas/**"
require "../src/pipes/**"
require "./routes"
