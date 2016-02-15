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

        def self.options
          [
              ['--prune', 'Prunes entries which do not exist in the remote this index was pulled from.']
          ].concat(super)
        end

        self.arguments = [
            CLAide::Argument.new('NAME', true)
        ]

        def initialize(argv)
          @name = argv.shift_argument
          @prune = argv.flag?('prune', false)
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
                  if @prune
                    hard_update(source, source_name, url)
                  else
                    soft_update(source, url)
                  end
                  UI.puts "Successfully updated repo #{source.name}".green if show_output && !config.verbose?
                rescue => e
                  UI.warn "Unable to update repo `#{source.name}`: #{e.message}"
                end
              end
            end
          end
        end

        # Performs a 'soft' update which appends any changes from the remote without deleting out-of-sync entries
        #
        def soft_update(source, url)
          downloader = Pod::Downloader::Http.new("#{source.repo}", "#{url}/index/fetchIndex", :type => 'tgz', :indexDownload => true)
          downloader.download
          UTIL.cleanup_index_download("#{source.repo}")
          UTIL.del_redundant_spec_dir("#{source.repo}/Specs/Specs")
        end

        # Performs a 'hard' update which prunes all index entries which are not sync with the remote (override)
        #
        def hard_update(source, source_name, url)
          begin
            repo_update_tmp = "#{source.repo}_update_tmp"
            system("mv", source.repo.to_s, repo_update_tmp)
            argv = CLAide::ARGV.new([source_name, url, '--silent'])
            Pod::Command::RepoArt::Add.new(argv).run
            FileUtils.remove_entry_secure(repo_update_tmp, :force => true)
          rescue => e
            FileUtils.remove_entry_secure(source.repo.to_s, :force => true)
            system("mv", repo_update_tmp, source.repo.to_s)
            raise Informative, "Error getting the index from Artifactory at: '#{url}' : #{e.message}"
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
