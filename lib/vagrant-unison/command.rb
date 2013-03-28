require "log4r"
require "vagrant"
require 'listen'

module VagrantPlugins
  module Unison
    class Command < Vagrant.plugin("2", :command)
      
      def execute
        
        with_target_vms do |machine|
          hostpath, guestpath = init_paths machine

          trigger_unison_sync machine

          @env.ui.info "Watching #{hostpath} for changes..."

          Listen.to(hostpath) do |modified, added, removed|
            @env.ui.info "Detected modifications to #{modified.inspect}" unless modified.empty?
            @env.ui.info "Detected new files #{added.inspect}" unless added.empty?
            @env.ui.info "Detected deleted files #{removed.inspect}" unless removed.empty?
            
            trigger_unison_sync machine
          end
        end

        0  #all is well
      end

      def init_paths(machine)
          hostpath  = File.expand_path(machine.config.sync.host_folder, @env.root_path)
          guestpath = machine.config.sync.guest_folder

          # Make sure there is a trailing slash on the host path to
          # avoid creating an additional directory with rsync
          hostpath = "#{hostpath}/" if hostpath !~ /\/$/

          [hostpath, guestpath]
      end

      def trigger_unison_sync(machine)
        hostpath, guestpath = init_paths machine

        @env.ui.info "Unisoning changes from {host}::#{hostpath} --> {guest VM}::#{guestpath}"

        ssh_info = machine.ssh_info

        # Create the guest path
        machine.communicate.sudo("mkdir -p '#{guestpath}'")
        machine.communicate.sudo("chown #{ssh_info[:username]} '#{guestpath}'")

        # Unison over to the guest path using the SSH info
        command = [
          "unison", "-batch",
          "-ignore=Name {git*,.vagrant/,*.DS_Store}",
          "-sshargs", "-p #{ssh_info[:port]} -o StrictHostKeyChecking=no -i #{ssh_info[:private_key_path]}",
          hostpath,
          "ssh://#{ssh_info[:username]}@#{ssh_info[:host]}/#{guestpath}"
         ]

        r = Vagrant::Util::Subprocess.execute(*command)
        if r.exit_code != 0
          raise Vagrant::Errors::UnisonError,
            :command => command.inspect,
            :guestpath => guestpath,
            :hostpath => hostpath,
            :stderr => r.stderr
        end
      end
     
    end
  end
end