require "pathname"

require "vagrant/action/builder"

module VagrantPlugins
  module Sync
    module Action
      # Include the built-in modules so we can use them as top-level things.
      include Vagrant::Action::Builtin

      # This action is called when `vagrant provision` is called.
      def self.action_sync
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use SyncFolders
        end
      end

      # The autoload farm
      action_root = Pathname.new(File.expand_path("../action", __FILE__))
      autoload :SyncFolders, action_root.join("sync_folders")
    end
  end
end
