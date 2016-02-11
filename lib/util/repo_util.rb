require 'fileutils'

module Pod
  class RepoArt
    class RepoUtil

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

