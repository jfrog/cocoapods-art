require 'fileutils'

module Pod
  class RepoArt
    class RepoUtil

      # @return list of Artifactory repos, read from the ~/.cocoapods/repos-art
      #
      def self.get_art_repos
        repos_art_dir = UTIL.get_repos_art_dir()
        dirs = Dir.glob "#{repos_art_dir}/*/"
        repos = []
        for dir in dirs
          if UTIL.artpodrc_file_exists(dir)
            url = UTIL.get_art_url(dir)
            repos.push ArtifactoryRepo.new(dir, url)
          end
        end
        repos
      end

      # @return [Source] The Artifactory source with the given name.
      #
      # @param  [String] name The name of the source.
      #
      def self.get_art_repo(name)
        #specified_source = Pod::Config.instance.sources_manager.aggregate.sources.find { |s| s.name == name }
        repos = get_art_repos()
        art_repo = nil
        for repo in repos
          if repo.name == name
            art_repo = repo
          end
        end

        unless art_repo
          raise Informative, "Unable to find the Artifactory-backed repo called `#{name}`."
        end
        art_repo
      end

      # @return whether a source is an Artifactory backed repo.
      #
      # @param  [Pathname] repo_root_path root directory of the repo.
      #
      def self.art_repo?(repo_root_path)
        true if File.exist?("#{repo_root_path}/.artpodrc")
      end

      # @return the url of this Artifactory repo which is stored in the .artpodrc file in it's root
      #
      # @param  [Pathname] repo_root_path root directory of the repo.
      #
      def self.get_art_url(repo_root_path)
        File.read("#{repo_root_path}/.artpodrc")
      end

      # @return if the .artpodrc file exists in the given dir
      #
      # @param  [Pathname] dir root directory of the repo.
      #
      def self.artpodrc_file_exists(dir)
        File.exist?("#{dir}/.artpodrc")
      end

      # @return the full path to the repos-art directory
      #
      def self.get_repos_art_dir()
        "#{Pod::Config.instance.home_dir}/repos-art"
      end

      # Cleans up all of the junk left over from using the Downloader
      #
      def self.cleanup_index_download(tmp_file_dir)
        # The downloader names every file it gets file.<ext>
        temp_file = "#{tmp_file_dir}/file.tgz"
        File.delete(temp_file) if File.exist?(temp_file)
      end

      def self.del_redundant_spec_dir(redundant_specs_dir)
        # The default flattening the Downloader uses for tgz makes this screwy
        Dir.delete(redundant_specs_dir) if (Dir.exist?(redundant_specs_dir) && Dir.glob(redundant_specs_dir + '/' + '*').empty?)
      end
    end
  end
end

