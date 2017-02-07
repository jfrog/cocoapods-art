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
            sources = [UTIL.get_art_repo(source_name)]
          else
            sources = UTIL.get_art_repos()
          end

          sources.each do |source|
             UI.section "Updating spec repo `#{source.name}`" do
               Dir.chdir(source.path) do
                 begin
                   # TODO HEAD to api/updateTime
                   # TODO unless .lastupdated >= api/updateTime do
                   # TODO Until we support delta downloads, update is actually add if not currently up tp date
                   url = UTIL.get_art_url(source.path)
                   if @prune
                   hard_update(source.name, source.path, url)
                   else
                     soft_update(source.path, url)
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
        def soft_update(path, url)
          downloader = Pod::Downloader::Http.new("#{path}", "#{url}/index/fetchIndex", :type => 'tgz', :indexDownload => true)
          downloader.download
          UTIL.cleanup_index_download("#{path}")
          UTIL.del_redundant_spec_dir("#{path}/Specs/Specs")
          system "cd '#{path}' && git add . && git commit -m 'Artifactory repo update specs'"
        end

        # Performs a 'hard' update which prunes all index entries which are not sync with the remote (override)
        #
        def hard_update(name, path, url)
          UI.puts path
          begin
            repos_path = "#{Pod::Config.instance.home_dir}/repos/#{name}"
            repos_art_path = "#{Pod::Config.instance.home_dir}/repos-art/#{name}"

            repo_update_tmp = "#{repos_path}_update_tmp"
            repo_art_update_tmp = "#{repos_art_path}_update_tmp"

            system("mv", repos_path.to_s, repo_update_tmp)
            system("mv", repos_art_path.to_s, repo_art_update_tmp)

            argv = CLAide::ARGV.new([name, url, '--silent'])
            Pod::Command::RepoArt::Add.new(argv).run

            FileUtils.remove_entry_secure(repo_update_tmp, :force => true)
            FileUtils.remove_entry_secure(repo_art_update_tmp, :force => true)
          rescue => e
            FileUtils.remove_entry_secure(path.to_s, :force => true)
            system("mv", repo_update_tmp, repos_path.to_s)
            system("mv", repo_art_update_tmp, repos_art_path.to_s)
            raise Informative, "Error getting the index from Artifactory at: '#{url}' : #{e.message}"
          end
        end
      end
    end
  end
end
