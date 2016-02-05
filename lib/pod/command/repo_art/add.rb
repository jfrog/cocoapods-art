module Pod
  class Command
    class RepoArt
      class Add < RepoArt
        self.summary = 'Add a Specs repo from Artifactory.'

        self.description = <<-DESC
          Retrieves the index from an Artifactory instance at 'URL' to the local spec repos
          directory at `~/.cocoapods/repos/'NAME'`.
        DESC

        self.arguments = [
            CLAide::Argument.new('NAME', true),
            CLAide::Argument.new('URL', true)
        ]

        def initialize(argv)
          @name, @url = argv.shift_argument, argv.shift_argument
          super
        end

        def validate!
          super
          unless @name && @url
            help! 'This command requires both a repo name and a url.'
          end
        end

        def run
          UI.section("Retrieving index from `#{@url}` into local spec repo `#{@name}`") do
            config.repos_dir.mkpath
            repo_dir_root = "#{config.repos_dir}/#{@name}"
            raise Informative, "Path #{repo_dir_root} already exists - remove it first, "\
            "or run 'pod repo-art update #{@name}' to update it" if File.exist?(repo_dir_root)

            repo_dir_specs = "#{repo_dir_root}/Specs"
            begin
              downloader = Pod::Downloader::Http.new(repo_dir_specs, "#{@url}/index/fetchIndex", :type => 'tgz')
              downloader.download
            rescue => e
              raise Informative, "Error getting the index from Artifactory at: '#{@url}' : #{e.message}"
            end

            # The downloader names every file it gets file.<ext>
            temp_file = "#{repo_dir_specs}/file.tgz"
            File.delete(temp_file) if File.exist?(temp_file)

            begin
              artpodrc_path = create_artpodrc_file(repo_dir_root)
            rescue => e
              raise Informative, "Cannot create file '#{artpodrc_path}' because : #{e.message}."\
                                  '- your Artifactory-backed Specs repo will not work correctly without it!'
            end
          end
        end

        # Creates the .artpodrc file which contains the repository's url in the root of the Spec repo
        #
        # @param [String] repo_dir_root root of the Spec repo
        #
        def create_artpodrc_file(repo_dir_root)
          artpodrc_path = "#{repo_dir_root}/.artpodrc"
          artpodrc = File.new(artpodrc_path, "wb")
          artpodrc << @url
          artpodrc.close
          artpodrc_path
        end

      end
    end
  end
end
