require "vagrant"

module VagrantPlugins
  module Sync
    module Errors
      class UnisonError < VagrantAWSError
        error_key(:unison_error)
      end
    end
  end
end
