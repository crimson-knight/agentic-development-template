# AgentC App Template OSS Version 1.0.0

[![Amber Framework](https://img.shields.io/badge/using-amber_framework-orange.svg)](https://amberframework.org)

This is a project written using [Amber](https://amberframework.org) and [Crystal](https://crystal-lang.org/).

This application template is meant to get you started using Amber to create AI powered modern applications that take advantage of modern hardware.

By using AI, and clever prompt engineering, this template is meant to empower _technically dangerous_ people.

## Are you a _technically dangerous_ person?

You may be a _technically dangerous_ person if you:
- Feel comfortable trying new apps out. YouTube or content creator videos are a great source of ideas and inspiration.
- Maybe you've tried no-code tools ranging from Zapier to Webflow and thought "this is great, but I want more than what this kind of tool can do".
- You're hyped about what AI means for changing how we write applications.
- You're willing to question long-held beliefs about how software is built.
- You have technical ideas, but you're just not a "software engineer".
- You may or may not have tried following some free coding classes to try and figure out simple things. (Psst! Have you made something run? 🤨 You have?! Yay! 👏)

You're in the right place. Welcome, fellow _technically dangerous_ person!

## Before Getting Started - Write Code Without Writing Any Code

This template works around a few ideas that [AgentC](https://agentc.consulting) has been cooking up in the lab for a while now. Here's three core principles that we've been exploring:
1. **We can already accurately describe software functionalityfrom within natural language.**
2. **We can use AI to generate code that will help us build the kind of application we want.**
3. **Most SaaS application structures are well understood and stable, aka there are no new problems to solve here.**
4. **We can use strong opinions on how to solve a problem to make it easier for AI to generate complete, working code.**

Conclusion: We can use AI to generate code that will help us build the kind of application we want, faster and more robust than ever before.

This application template serves to fullfil that conclusion.

## Prerequisites

This project requires [Cursor](https://www.cursor.sh/). 
Everything is based around you being on a Mac [with Apple Silicon](https://support.apple.com/en-us/HT211849).
You've installed [Homebrew](https://brew.sh/), and you're comfortable with using it to install other dependencies.

Never heard of some of these things? _Technically dangerous_ people don't let things stop them 😉 also, hop into the [Amber Discord](https://discord.gg/JKCczAEh4D) and ask questions so we can improve these docs.

## Nerdy Technical Details

_You can skip this section if you're not interested in the nitty gritty details._ This application template uses a specific set of highly capable, strongly opinionated and enterprise tested tools and design patterns. Here are some of the top level ones that most nerds love to talk about.

- Underlying language: [Crystal](https://crystal-lang.org/) - The programming language used to build this application.
- Web app framework: [Amber](https://amberframework.org) - The web app framework used to build this application.
- Database: [PostgreSQL](https://www.postgresql.org/) - The database used to store this application's data.
- Frontend Styling: [CSS3](https://developer.mozilla.org/en-US/docs/Web/CSS) - The styling language used to style this application's frontend. Nothing special here actually.
- Frontend Framework: [HTML5](https://developer.mozilla.org/en-US/docs/Web/HTML) - The markup language used to build this application's frontend. Nothing special here actually.
- Frontend JavaScript: [StimulusJS](https://stimulus.hotwired.dev/) - The JavaScript library used to add interactivity to this application's frontend.
- AI inference interface: [Llamero](https://github.com/crimson-knight/llamero) - The library used to interface with the AI models that generate code for this application.

# Getting Started
For the rest of this section, it is assumed that you have Cursor installed and whichever account level you chose allows you to use the Composer and `agent` sidebar features.

## How This Application Template Works

This template is meant for you to use the Agent feature that Cursor provides to generate code for you. There are lots of `md` files in each directory that contain instructions on how to generate code for that part of the application. There are also help documents that can be used by the Agent or yourself to increase your understand of how the application works under the hood. This is helpful in case the agent has made a mistake or gotten stuck.

The two most important document structures are as follows:
- `src/` - This is where the code for the application lives.
- `help/` - This is where you can put any helpful documents that can be used by the Agent or yourself to increase your understand of how the application works under the hood. This is helpful in case the agent has made a mistake or gotten stuck.

Each directory with `src/` has it's own docs and they follow the naming convention of `src/`**`directory_name`**/`i_want_to_{action name to perform}.md`.
Each directory with `help/` has it's own docs and they follow the naming convention of `help/`**`action name`**/`help_with_i_want_to_{action name to perform}.md`.

If you're not sure which document to look with, you can always have the agent look it up for you! 😉

## Workflow For Programming Using An Agent

1. If you've just forked this repo, you'll want to start by updating the app details to the name of your project.
  In the cursor sidebar, CMD+SHIFT+O (the letter O, not the number `0`) and then type `I want you to perform @files/initial_application_configuration using the application name <your application name> and my github username <`.



To start your Amber server:

1. Install dependencies with `shards install`
2. Build executables with `shards build`
3. Create and migrate your database with `bin/amber db create migrate`. Also see [creating the database](https://docs.amberframework.org/amber/guides/create-new-app#creating-the-database).
4. Start Amber server with `bin/amber watch`

Now you can visit http://localhost:3000/ from your browser.

Getting an error message you need help decoding? Check the [Amber troubleshooting guide](https://docs.amberframework.org/amber/troubleshooting), post a [tagged message on Stack Overflow](https://stackoverflow.com/questions/tagged/amber-framework), or visit [Amber on Gitter](https://gitter.im/amberframework/amber).

Using Docker? Please check [Amber Docker guides](https://docs.amberframework.org/amber/guides/docker).

## Tests

To run the test suite:

```
crystal spec
```

## Contributing

1. Fork it ( https://github.com/your-github-user/agentc_app_template_oss/fork )
2. Create your feature branch ( `git checkout -b my-new-feature` )
3. Commit your changes ( `git commit -am 'Add some feature'` )
4. Push to the branch ( `git push origin my-new-feature` )
5. Create a new Pull Request

## Contributors

- [your-github-user](https://github.com/your-github-user) crimson-knight - creator, maintainer
