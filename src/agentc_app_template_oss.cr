require "../config/application"
require "./runtime/memory_trace"

Amber::Support::ClientReload.new if Amber.settings.auto_reload?

# One fiber writing one `memory.trace` line per interval, started after the
# environment is configured and before the server blocks. Default-on in
# production, opt-in elsewhere via MEMORY_TRACE_INTERVAL_SECONDS.
AgentC::MemoryTrace.perform_for_environment(Amber.env.production?)

Amber::Server.start
