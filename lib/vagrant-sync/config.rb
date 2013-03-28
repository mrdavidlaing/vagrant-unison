require "vagrant"

module VagrantPlugins
  module Sync
    class Config < Vagrant.plugin("2", :config)
      # The access key ID for accessing AWS.
      #
      # @return [String]
      attr_accessor :host_folder

      # The ID of the AMI to use.
      #
      # @return [String]
      attr_accessor :guest_folder

      def initialize(region_specific=false)
        @host_folder      = UNSET_VALUE
        @remote_folder    = UNSET_VALUE
      end

      #-------------------------------------------------------------------
      # Internal methods.
      #-------------------------------------------------------------------

      # def merge(other)
      #   super.tap do |result|
      #     # TODO - do something sensible; current last config wins
      #     result.local_folder = other.local_folder
      #     result.remote_folder = other.remote_folder
      #   end
      # end

      def finalize!
        # The access keys default to nil
        @host_folder    = nil if @host_folder    == UNSET_VALUE
        @guest_folder   = nil if @guest_folder   == UNSET_VALUE

        # Mark that we finalized
        @__finalized = true
      end

      def validate(machine)
        errors = []

        errors << I18n.t("vagrant_sync.config.host_folder_required") if @host_folder.nil?
        errors << I18n.t("vagrant_sync.config.guest_folder_required") if @guest_folder.nil?

        { "Sync" => errors }
      end
    end
  end
end
