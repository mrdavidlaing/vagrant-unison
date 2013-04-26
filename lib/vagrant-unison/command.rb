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
          
          # Create empty guestpath
          machine.communicate.sudo("rm -rf '#{guestpath}'")
          machine.communicate.sudo("mkdir -p '#{guestpath}'")
          machine.communicate.sudo("chown #{ssh_info[:username]} '#{guestpath}'")

          Net::SCP.start(ssh_info[:host], ssh_info[:username], 
                        { :port => ssh_info[:port], 
                          :keys => [ ssh_info[:private_key_path] ],
                          :paranoid => false }) do |scp|

            #copy up everything at the beginning
            @env.ui.info "Uploading {host}::#{hostpath} to {guest}::#{guestpath}"
            Dir.glob("#{hostpath}**/*", File::FNM_DOTMATCH).each do |file|
              remote_file = file.gsub(hostpath, guestpath)
              if File.stat(file).file?  
                scp.upload!( file, remote_file ) do |ch, name, sent, total|
                  @env.ui.info "\r#{name}: #{(sent.to_f * 100 / total.to_f).to_i}%"
                end
              end
              if File.directory?(file)
                machine.communicate.sudo("mkdir -p '#{remote_file}'")
                machine.communicate.sudo("chown #{ssh_info[:username]} '#{remote_file}'")
              end
            end

            @env.ui.info "Watching {host}::#{hostpath} for changes..."

            Listen.to(hostpath) do |modified, added, removed|
              (modified << added).flatten.each do |file|
                remote_file = file.gsub(hostpath, guestpath)
                @env.ui.info "Uploading {host}::#{file} to {guest VM}::#{remote_file}"
                scp.upload!( file, remote_file ) do |ch, name, sent, total|
                  @env.ui.info "\r#{name}: #{(sent.to_f * 100 / total.to_f).to_i}%"
                end
              end
              removed.each do |file|
                remote_file = file.gsub(hostpath, guestpath)
                @env.ui.info "Deleting {guest VM}::#{remote_file}"
                machine.communicate.sudo("rm #{remote_file}")
              end
            end # Listen
          end # Net::SCP.start

        end

        0  #all is well
      end

      def init_paths(machine)
          hostpath  = File.expand_path(machine.config.sync.host_folder, @env.root_path)
          guestpath = machine.config.sync.guest_folder

          # Make sure there is a trailing slash both paths
          hostpath = "#{hostpath}/" if hostpath !~ /\/$/
          guestpath = "#{guestpath}/" if guestpath !~ /\/$/

          [hostpath, guestpath]
      end
     
    end
  end
end