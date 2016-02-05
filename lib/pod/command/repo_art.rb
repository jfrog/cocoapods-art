require 'cocoapods_repo_art'

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
      self.version = CocoaPodsRepoArt::VERSION
      self.description = 'Enables working with Artifactory as a Specs repo and as a repository for Pods.'\
                          "\n v#{CocoaPodsRepoArt::VERSION}\n"
      self.summary = <<-SUMMARY
        Artifactory support for CocoaPods
      SUMMARY

    end
  end
end
