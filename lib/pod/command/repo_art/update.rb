require 'util/repo_util'

module Pod
  class Command
    class RepoArt
      class Update < RepoArt
        UTIL = Pod::RepoArt::RepoUtil

        self.summary = 'Update an Artifactory-backed Specs repo.'

        self.description = <<-DESC
          Updates the Artifactory-backed spec-repo `NAME`.
        DESC

        self.arguments = [
            CLAide::Argument.new('NAME', true)
        ]

        def initialize(argv)
          @name = argv.shift_argument
          super
        end

        def validate!
          super
          unless @name
            help! 'This command requires a repo name to run.'
          end
        end

        def run
          update(@name, true)
        end

        private

        # Update command for Artifactory sources.
        #
        # @param  [String] source_name name
        #
        def update(source_name = nil, show_output = false)
          if source_name
            sources = [art_source_named(source_name)]
          else
            sources = art_sources
          end
          sources.each do |source|
            UI.section "Updating spec repo `#{source.name}`" do
              Dir.chdir(source.repo) do
                begin
                  # TODO HEAD to api/updateTime
                  # TODO unless .lastupdated >= api/updateTime do
                  # TODO Until we support delta downloads, update is actually add if not currently up tp date
                  url = UTIL.get_art_url(source.repo)
                  repo_update_tmp = "#{source.repo}_update_tmp"
                  begin
                    system("mv", source.repo.to_s, repo_update_tmp)
                    argv = CLAide::ARGV.new([source_name, url, '--silent'])
                    Pod::Command::RepoArt::Add.new(argv).run
                  rescue => e
                    FileUtils.remove_entry_secure(source.repo.to_s, :force => true)
                    system("mv", repo_update_tmp, source.repo.to_s)
                    raise Informative, "Error getting the index from Artifactory at: '#{url}' : #{e.message}"
                  end
                  FileUtils.remove_entry_secure(repo_update_tmp, :force => true)
                  UI.puts "Successfully updated repo #{source.name}".green if show_output && !config.verbose?
                rescue => e
                  UI.warn "Unable to update repo `#{source.name}`: #{e.message}"
                end
              end
            end
          end
        end

        # @return [Source] The Artifactory source with the given name. 
        #
        # @param  [String] name The name of the source.
        #
        def art_source_named(name)
          specified_source = SourcesManager.aggregate.sources.find { |s| s.name == name }
          unless specified_source
            raise Informative, "Unable to find the repo called `#{name}`."
          end
          unless UTIL.art_repo?(specified_source.repo)
            raise Informative, "Repo `#{name}` is not an Artifactory-backed repo."
          end
          specified_source
        end

        # @return [Source] The list of the Artifactory sources.
        #
        def art_sources
          SourcesManager.all.select do |source|
            UTIL.art_repo?(source.repo)
          end
        end

      end
    end
  end
end
