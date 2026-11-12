ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Kein paralleles Testen: Die Website hat keine Datenbanktabellen (kein db/schema.rb),
    # und ab 50 Tests würden die Worker-Prozesse beim Anlegen ihrer Test-Datenbank
    # abbrechen — der Testlauf hängt dann. Die Suite läuft ohnehin in wenigen Sekunden.
    parallelize(workers: 1)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
