require "log4r"
require "vagrant"

module VagrantPlugins
  module Unison
    class Command < Vagrant.plugin("2", :command)
      def execute

        with_target_vms do |machine|

          ssh_info = machine.ssh_info

          hostpath  = File.expand_path(machine.config.sync.host_folder, @env.root_path)
          guestpath = machine.config.sync.guest_folder

          # Make sure there is a trailing slash on the host path to
          # avoid creating an additional directory with rsync
          hostpath = "#{hostpath}/" if hostpath !~ /\/$/

          @env.ui.info "Unisoning {host}::#{hostpath} --> {guest VM}::#{guestpath}"

          # Create the guest path
          #machine.communicate.sudo("mkdir -p '#{guestpath}'")
          #machine.communicate.sudo("chown #{ssh_info[:username]} '#{guestpath}'")

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

        0
      end
     
    end
  end
end