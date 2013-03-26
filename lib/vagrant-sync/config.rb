require "vagrant"

module VagrantPlugins
  module Sync
    class Config < Vagrant.plugin("2", :config)
      # The access key ID for accessing AWS.
      #
      # @return [String]
      attr_accessor :local_folder

      # The ID of the AMI to use.
      #
      # @return [String]
      attr_accessor :remote_folder

      def initialize(region_specific=false)
        @local_folder      = UNSET_VALUE
        @remote_folder     = UNSET_VALUE
      end

      #-------------------------------------------------------------------
      # Internal methods.
      #-------------------------------------------------------------------

      def merge(other)
        super.tap do |result|
          # TODO - do something sensible; current last config wins
          result.local_folder = other.local_folder
          result.remote_folder = other.remote_folder
        end
      end

      def finalize!
        # The access keys default to nil
        @local_folder     = nil if @local_folder    == UNSET_VALUE
        @remote_folder    = nil if @remote_folder   == UNSET_VALUE

        # Mark that we finalized
        @__finalized = true
      end

      def validate(machine)
        errors = []

        errors << I18n.t("vagrant_sync.config.local_folder_required") if @local_folder.nil?
        errors << I18n.t("vagrant_sync.config.remote_folder_required") if @remote_folder.nil?

        { "Sync" => errors }
      end
    end
  end
end
