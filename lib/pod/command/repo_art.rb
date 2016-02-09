require 'cocoapods_art'

module Pod
  class Command
    class RepoArt < Command
      require 'pod/command/repo_art/add'
      require 'pod/command/repo_art/lint'
      require 'pod/command/repo_art/push'
      require 'pod/command/repo_art/remove'
      require 'pod/command/repo_art/update'
      require 'pod/command/repo_art/list'

      self.abstract_command = true
      self.version = CocoaPodsArt::VERSION
      self.description = 'Enables working with JFrog Artifactory as a Specs repo and as a repository for Pods.'\
                          "\n v#{CocoaPodsArt::VERSION}\n"
      self.summary = <<-SUMMARY
        Artifactory support for CocoaPods
      SUMMARY

      self.default_subcommand = 'list'

    end
  end
end
