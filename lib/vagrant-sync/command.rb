require "log4r"
require "vagrant"

module VagrantPlugins
  module Sync
    class Command < Vagrant.plugin("2", :command)
      def execute
        puts @env.inspect
        puts @config
        0
      end
     # with_target_vms(argv, :reverse => true) do |machine|
     #   puts machine.inspect
     # end
    end
  end
end
