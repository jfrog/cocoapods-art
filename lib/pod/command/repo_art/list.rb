require 'util/repo_util'
require 'pod/artifactory_repo'

module Pod
  class Command
    class RepoArt
      class List < RepoArt

        UTIL = Pod::RepoArt::RepoUtil

        self.summary = 'List Artifactory-backed repos.'

        self.description = <<-DESC
            List the Artifactory repos from the local spec-repos directory at `~/.cocoapods/repos-art/.`
        DESC

        def self.options
          [
              ['--count-only', 'Show the total number of repos']
          ].concat(super)
        end

        def initialize(argv)
          init
          @count_only = argv.flag?('count-only')
          super
        end

        def run
          repos = UTIL.get_art_repos
          print_art_repos(repos) unless @count_only
          print_art_repos_count(repos)
        end

        def print_art_repos(repos)
          for repo in repos
            UI.title repo.name do
              UI.puts "- URL: #{repo.url}"
              UI.puts "- Path: #{repo.path}"
            end
          end
          UI.puts "\n"
        end

        def print_art_repos_count(repos)
          number_of_repos = repos.length
          repo_string = number_of_repos != 1 ? 'repos' : 'repo'
          UI.puts "#{number_of_repos} #{repo_string}\n".green
        end

      end
    end
  end
end
