require 'util/repo_util'

module Pod
  class Command
    class RepoArt
      class List < RepoArt

        UTIL = Pod::RepoArt::RepoUtil

        self.summary = 'List Artifactory-backed repos.'

        self.description = <<-DESC
            List the Artifactory repos from the local spec-repos directory at `~/.cocoapods/repos/.`
        DESC

        def self.options
          [
              ['--count-only', 'Show the total number of repos']
          ].concat(super)
        end

        def initialize(argv)
          @count_only = argv.flag?('count-only')
          super
        end

        def run
          sources = art_sources
          print_art_sources(sources) unless @count_only
          print_source_count(sources)
        end

        def print_art_sources(sources)
          sources.each do |source|
            UI.title source.name do
              print_source(source)
            end
          end
          UI.puts "\n"
        end

        def print_source(source)
          UI.puts '- Type: Artifactory'
          UI.puts "- URL:  #{UTIL.get_art_url(source.repo)}" if UTIL.artpodrc_file_exists(source.repo)
          UI.puts "- Path: #{source.repo}"
        end

        # @return [Source] The list of the Artifactory sources.
        #
        def art_sources
          Pod::Config.instance.sources_manager.all.select do |source|
            UTIL.art_repo?(source.repo)
          end
        end

        def print_source_count(sources)
          number_of_repos = sources.length
          repo_string = number_of_repos != 1 ? 'repos' : 'repo'
          UI.puts "#{number_of_repos} #{repo_string}\n".green
        end

      end
    end
  end
end
