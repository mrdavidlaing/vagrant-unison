require "log4r"
require "vagrant"
require 'listen'
require 'net/ssh'
require 'net/scp'

module VagrantPlugins
  module Unison
    class Command < Vagrant.plugin("2", :command)
      
      def execute
        
        with_target_vms do |machine|
          hostpath, guestpath = init_paths machine
          
          ssh_info = machine.ssh_info
          
          # Create the guest path
          machine.communicate.sudo("mkdir -p '#{guestpath}'")
          machine.communicate.sudo("chown #{ssh_info[:username]} '#{guestpath}'")

          #copy up everything at the beginning
          Net::SCP.start(ssh_info[:host], ssh_info[:username], 
                        { :port => ssh_info[:port], 
                          :keys => [ ssh_info[:private_key_path],
                          :paranoid => false ] }) do |scp|
            scp.upload! hostpath, guestpath, :recursive => true 
          end

          @env.ui.info "Watching #{hostpath} for changes..."

          Listen.to(hostpath) do |modified, added, removed|
            Net::SCP.start(ssh_info[:host], ssh_info[:username], 
                        { :port => ssh_info[:port], 
                          :keys => [ ssh_info[:private_key_path],
                          :paranoid => false ] }) do |scp|
              (modified_list << added_list).flatten.each do |file|
                remote_file = file.gsub(hostpath, guestpath)
                @env.ui.info "Uploading #{file} to #{remote_file}"
                scp.upload! file, remote_file
              end
              removed.each do |file|
                remote_file = file.gsub(hostpath, guestpath)
                @env.ui.info "Deleting #{remote_file}"
                machine.communicate.sudo("rm #{remote_file}")
              end
            end

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
          "-ignore=Name {.git*,.vagrant/,*.DS_Store}",
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