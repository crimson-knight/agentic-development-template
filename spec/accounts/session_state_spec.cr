require "spec"
require "../../src/app/accounts/session_state"

module AccountStateSpec
  alias Failure = App::Accounts::Failure
  alias Profile = App::Accounts::Profile
  alias Session = App::Accounts::Session
  alias State = App::Accounts::SessionState
  alias Error = Amber::Native::ServiceError
  TOKEN   = "s" * 43
  ORIGIN  = "https://account.example.test"
  PROFILE = Profile.new(1_i64, "native@example.test", "regular", "Android 雪")

  class Operation < Amber::Native::Operation
    getter cancelled = false

    def cancel : Nil
      @cancelled = true
    end
  end

  record Pending(T), completion : Proc(T, Nil), operation : Operation

  class Remote < App::Accounts::Remote
    getter origin : String = ORIGIN
    getter logins = [] of Pending(Session | Failure)
    getter accounts = [] of Pending(Profile | Failure)
    getter renames = [] of Pending(Profile | Failure)
    getter logouts = [] of Pending(Nil | Failure)
    getter logout_tokens = [] of String
    getter names = [] of String
    property reject_next = false

    def login(email : String, password : String, &completion : Session | Failure ->) : Amber::Native::Operation
      reject!
      operation = Operation.new
      @logins << Pending(Session | Failure).new(completion, operation)
      operation
    end

    def account(token : String, &completion : Profile | Failure ->) : Amber::Native::Operation
      reject!
      operation = Operation.new
      @accounts << Pending(Profile | Failure).new(completion, operation)
      operation
    end

    def rename(token : String, name : String, &completion : Profile | Failure ->) : Amber::Native::Operation
      reject!
      @names << name
      operation = Operation.new
      @renames << Pending(Profile | Failure).new(completion, operation)
      operation
    end

    def logout(token : String, &completion : Nil | Failure ->) : Amber::Native::Operation
      reject!
      @logout_tokens << token
      operation = Operation.new
      @logouts << Pending(Nil | Failure).new(completion, operation)
      operation
    end

    private def reject!
      if @reject_next
        @reject_next = false
        raise Error.new(Error::Code::Unavailable, "private failure")
      end
    end
  end

  record Read, completion : Proc(String | Nil | Error, Nil), operation : Operation
  record Mutation, kind : Symbol, value : String?, completion : Proc(Nil | Error, Nil), operation : Operation

  class Secrets < Amber::Native::Secrets
    getter reads = [] of Read
    getter mutations = [] of Mutation
    property stored : String?
    property reject_next = false

    def read(key : String, &completion : String | Nil | Error ->) : Amber::Native::Operation
      check_key(key)
      operation = Operation.new
      @reads << Read.new(completion, operation)
      operation
    end

    def write(key : String, value : String, &completion : Nil | Error ->) : Amber::Native::Operation
      check_key(key)
      operation = Operation.new
      @mutations << Mutation.new(:write, value, completion, operation)
      operation
    end

    def delete(key : String, &completion : Nil | Error ->) : Amber::Native::Operation
      check_key(key)
      operation = Operation.new
      @mutations << Mutation.new(:delete, nil, completion, operation)
      operation
    end

    def finish_read(value : String | Nil | Error = @stored)
      @reads.shift.completion.call(value)
    end

    # A failed/cancelled completion may follow a committed side effect. The
    # coordinator must serialize its next delete instead of assuming rollback.
    def finish_mutation(error : Error? = nil, commit = true)
      mutation = @mutations.shift
      @stored = mutation.kind == :delete ? nil : mutation.value if commit
      mutation.completion.call(error)
    end

    private def check_key(key)
      raise "Unexpected secret key" unless key == State::SECRET_KEY
      if @reject_next
        @reject_next = false
        raise Error.new(Error::Code::Unavailable, "private vault failure")
      end
    end
  end

  class Fixture
    getter remote = Remote.new
    getter secrets = Secrets.new
    getter state : State
    getter changes = 0
    property now = 100_i64

    def initialize
      @state = State.new(@remote, @secrets, -> { @now }) { @changes += 1; nil }
    end

    def empty
      state.start
      secrets.finish_read(nil)
      state.phase.should eq State::Phase::SignedOut
    end

    def issued
      Session.new(TOKEN, 1000_i64, PROFILE)
    end

    def credential(origin = ORIGIN, expires = 1000_i64)
      App::Accounts::Credential.new(origin, TOKEN, expires).encode
    end

    def sign_in
      empty
      state.login("native@example.test", "synthetic-password")
      remote.logins.shift.completion.call(issued)
      secrets.finish_mutation
      state.phase.should eq State::Phase::SignedIn
    end
  end
end

describe App::Accounts::SessionState do
  it "reads once and never publishes a signed-in account until protected persistence succeeds" do
    f = AccountStateSpec::Fixture.new
    f.state.start
    f.state.start
    f.secrets.reads.size.should eq 1
    f.secrets.finish_read(nil)
    f.state.login("native@example.test", "synthetic-password")
    f.remote.logins.shift.completion.call(f.issued)
    f.state.phase.should eq App::Accounts::SessionState::Phase::SavingSession
    f.state.account.should be_nil
    stored = f.secrets.mutations.first.value.not_nil!
    parsed = JSON.parse(stored).as_h
    parsed.keys.sort.should eq ["expires_at", "origin", "token"]
    stored.should_not contain "synthetic-password"
    stored.should_not contain "native@example.test"
    f.secrets.finish_mutation
    f.state.signed_in?.should be_true
    f.state.account.not_nil!.display_name.should eq "Android 雪"
  end

  it "restores from protected credentials but fetches account data from the actual API contract" do
    f = AccountStateSpec::Fixture.new
    f.secrets.stored = f.credential
    f.state.start
    f.secrets.finish_read
    f.state.phase.should eq App::Accounts::SessionState::Phase::OpeningAccount
    f.state.account.should be_nil
    f.remote.accounts.shift.completion.call(AccountStateSpec::PROFILE)
    f.state.signed_in?.should be_true
    f.secrets.mutations.should be_empty
  end

  it "preserves corrupt or wrong-origin credentials without sending them to a server" do
    ["bad-json", "x" * 2049, AccountStateSpec::Fixture.new.credential("https://other.example.test")].each do |value|
      f = AccountStateSpec::Fixture.new
      f.secrets.stored = value
      f.state.start
      f.secrets.finish_read
      f.state.phase.should eq App::Accounts::SessionState::Phase::StorageFailure
      f.remote.accounts.should be_empty
      f.remote.logouts.should be_empty
      f.state.login("another", "password")
      f.remote.logins.should be_empty
      f.secrets.stored.should eq value
      f.secrets.mutations.should be_empty
    end
  end

  it "clears and revokes an expired stored session without loading private account data" do
    f = AccountStateSpec::Fixture.new
    f.secrets.stored = f.credential(expires: 100_i64)
    f.state.start
    f.secrets.finish_read
    f.remote.accounts.should be_empty
    f.state.phase.should eq App::Accounts::SessionState::Phase::SigningOut
    f.secrets.finish_mutation
    f.remote.logout_tokens.should eq [AccountStateSpec::TOKEN]
    f.remote.logouts.shift.completion.call(AccountStateSpec::Failure::Unauthorized)
    f.state.phase.should eq App::Accounts::SessionState::Phase::SignedOut
    f.secrets.stored.should be_nil
  end

  it "keeps a failed network restore retryable without deleting protected credentials" do
    f = AccountStateSpec::Fixture.new
    f.secrets.stored = f.credential
    f.state.start
    f.secrets.finish_read
    f.remote.accounts.shift.completion.call(AccountStateSpec::Failure::Unavailable)
    f.state.phase.should eq App::Accounts::SessionState::Phase::Unavailable
    f.state.account.should be_nil
    f.secrets.stored.should eq f.credential
    f.state.retry
    f.remote.accounts.shift.completion.call(AccountStateSpec::PROFILE)
    f.state.signed_in?.should be_true
  end

  it "serializes logout after a pending sign-in write, including a committed failure" do
    [nil, AccountStateSpec::Error.new(AccountStateSpec::Error::Code::Cancelled, "cancelled")].each do |write_result|
      f = AccountStateSpec::Fixture.new
      f.empty
      f.state.login("native@example.test", "password")
      f.remote.logins.shift.completion.call(f.issued)
      writing = f.secrets.mutations.first.operation
      f.state.sign_out
      f.secrets.mutations.size.should eq 1
      writing.cancelled.should be_false
      f.secrets.finish_mutation(write_result, commit: true)
      f.state.signed_in?.should be_false
      f.secrets.mutations.first.kind.should eq :delete
      f.secrets.finish_mutation
      f.secrets.stored.should be_nil
      f.remote.logouts.shift.completion.call(nil)
      f.state.phase.should eq App::Accounts::SessionState::Phase::SignedOut
    end
  end

  it "cannot resurrect sign-in after logout finishes before a late HTTP completion" do
    f = AccountStateSpec::Fixture.new
    f.empty
    f.state.login("native@example.test", "password")
    login = f.remote.logins.shift
    f.state.sign_out
    login.operation.cancelled.should be_true
    f.secrets.finish_mutation
    f.state.phase.should eq App::Accounts::SessionState::Phase::SignedOut
    login.completion.call(f.issued)
    f.secrets.mutations.should be_empty
    f.state.account.should be_nil
    f.remote.logout_tokens.should eq [AccountStateSpec::TOKEN]
    f.remote.logouts.shift.completion.call(nil)
    f.state.phase.should eq App::Accounts::SessionState::Phase::SignedOut
  end

  it "serializes a clear request after a pending protected read and revokes the discovered token" do
    f = AccountStateSpec::Fixture.new
    f.secrets.stored = f.credential
    f.state.start
    f.state.sign_out
    f.secrets.mutations.should be_empty
    f.secrets.finish_read
    f.remote.accounts.should be_empty
    f.secrets.finish_mutation
    f.remote.logout_tokens.should eq [AccountStateSpec::TOKEN]
    f.remote.logouts.shift.completion.call(nil)
    f.state.phase.should eq App::Accounts::SessionState::Phase::SignedOut
  end

  it "retains an incomplete logout on protected delete failure and retries deletion before new sign-in" do
    f = AccountStateSpec::Fixture.new
    f.sign_in
    f.state.sign_out
    f.secrets.finish_mutation(AccountStateSpec::Error.new(AccountStateSpec::Error::Code::IO, "private"), commit: false)
    f.state.phase.should eq App::Accounts::SessionState::Phase::StorageFailure
    f.state.account.should be_nil
    f.state.notice.should contain "Sign-out is incomplete"
    f.state.login("other", "password")
    f.remote.logins.should be_empty
    f.state.retry
    f.secrets.mutations.first.kind.should eq :delete
    f.secrets.finish_mutation
    f.remote.logouts.each { |pending| pending.completion.call(nil) }
    f.remote.logouts.clear
    f.state.phase.should eq App::Accounts::SessionState::Phase::SignedOut
    f.secrets.stored.should be_nil
  end

  it "acknowledges local logout but discloses failure to reach server revocation" do
    f = AccountStateSpec::Fixture.new
    f.sign_in
    f.state.sign_out
    f.secrets.finish_mutation
    f.remote.logouts.shift.completion.call(AccountStateSpec::Failure::Unavailable)
    f.state.phase.should eq App::Accounts::SessionState::Phase::SignedOut
    f.state.notice.should contain "on this device"
    f.secrets.stored.should be_nil
  end

  it "shares name validation and rejects account-identity replacement in an edit response" do
    f = AccountStateSpec::Fixture.new
    f.sign_in
    f.state.rename("a" * 65)
    f.remote.renames.should be_empty
    f.state.rename("  New 雪  ")
    f.remote.names.should eq ["New 雪"]
    other = AccountStateSpec::Profile.new(2_i64, "other@example.test", "regular", "Other")
    f.remote.renames.shift.completion.call(other)
    f.state.account.not_nil!.id.should eq 1
    f.state.notice.should contain "invalid account"
    f.state.rename("New 雪")
    f.remote.renames.shift.completion.call(AccountStateSpec::Profile.new(1_i64, "native@example.test", "regular", "New 雪"))
    f.state.account.not_nil!.display_name.should eq "New 雪"
  end

  it "ignores late edits after logout and clears expired authorization on edit" do
    f = AccountStateSpec::Fixture.new
    f.sign_in
    f.state.rename("new")
    pending = f.remote.renames.shift
    f.state.sign_out
    pending.operation.cancelled.should be_true
    pending.completion.call(AccountStateSpec::PROFILE)
    f.state.account.should be_nil
    f.secrets.finish_mutation
    f.remote.logouts.shift.completion.call(nil)
    f.state.phase.should eq App::Accounts::SessionState::Phase::SignedOut

    f = AccountStateSpec::Fixture.new
    f.sign_in
    f.state.rename("new")
    f.remote.renames.shift.completion.call(AccountStateSpec::Failure::Unauthorized)
    f.state.account.should be_nil
    f.secrets.mutations.first.kind.should eq :delete
  end

  it "contains synchronous service submission rejection and permits retry" do
    f = AccountStateSpec::Fixture.new
    f.secrets.reject_next = true
    f.state.start
    f.state.phase.should eq App::Accounts::SessionState::Phase::StorageFailure
    f.state.retry
    f.secrets.finish_read(nil)
    f.remote.reject_next = true
    f.state.login("e", "p")
    f.state.phase.should eq App::Accounts::SessionState::Phase::SignedOut
    f.state.notice.should_not contain "private"
  end

  it "does not publish after terminal stop, even when cancelled work completes later" do
    f = AccountStateSpec::Fixture.new
    f.empty
    f.state.login("native@example.test", "password")
    pending = f.remote.logins.shift
    changes = f.changes
    f.state.stop
    pending.operation.cancelled.should be_true
    pending.completion.call(f.issued)
    f.state.start
    f.state.login("e", "p")
    f.state.phase.should eq App::Accounts::SessionState::Phase::Stopped
    f.state.account.should be_nil
    f.changes.should eq changes
    f.secrets.mutations.should be_empty
    f.remote.logouts.should be_empty
  end
end

describe App::Accounts::Credential do
  it "rejects duplicate, missing and unknown fields without including secrets in errors" do
    token = AccountStateSpec::TOKEN
    [%({"origin":"#{AccountStateSpec::ORIGIN}","token":"#{token}","token":"#{token}","expires_at":1000}),
     %({"origin":"#{AccountStateSpec::ORIGIN}","token":"#{token}"}),
     %({"origin":"#{AccountStateSpec::ORIGIN}","token":"#{token}","expires_at":1000,"password":"no"})].each do |value|
      expect_raises(ArgumentError) { App::Accounts::Credential.decode(value, AccountStateSpec::ORIGIN) }
    end
  end
end
