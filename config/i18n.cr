require "i18n"

# The path from where the translations should be loaded
I18n.load_path += ["./src/locales"]

I18n.init
I18n.default_locale = "en"
