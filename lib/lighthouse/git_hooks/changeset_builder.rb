require 'fileutils'
require 'date'
module Lighthouse::GitHooks

  class ChangesetBuilder < Base
    def initialize(old_rev, new_rev, ref=nil)
      super()

      all_zeroes = "0000000000000000000000000000000000000000"
      return if old_rev == all_zeroes or new_rev == all_zeroes
      Dir.chdir Configuration[:repository_path] do
        @commits = `git log --name-status --pretty=format:"|%H|%cn|%ce|%ci|%s" #{old_rev}..#{new_rev}`
        # hash, committer name, commit date, message
      end

      current_commit = nil
      current_user = nil
      @commits.each_line do |l|
        unless l =~ /^\|/
          change_array = l.gsub("\t", " ").strip.split(' ',2)
          current_commit.changes << change_array
          next
        end
        save_commit current_commit
        data = l.split('|', 6)
        Configuration.login(data[3])
        current_commit = Lighthouse::Changeset.new(:project_id => Configuration[:project_id].to_i)
        current_commit.body = data[5].strip
        current_commit.title = "#{data[2]} committed changeset #{data[1]}"
        current_commit.revision = data[1][0..8]
        current_commit.changed_at = data[4]
        current_commit.changes = []
        current_user = data[3]
      end
      save_commit current_commit
    rescue Exception => e
      $stderr.puts "Failed to save lighthouse changeset #{current_commit.inspect} because:"
      $stderr.puts e.inspect
      $stderr.puts e.backtrace.join("\n")
      $stderr.puts "~~HOWEVER~~ the commits were accepted so that's okay"
    end

    def save_commit(commit)
      return unless commit
      commit.changes = commit.changes.reject{ |e| e == [] }.to_yaml
      if commit.save
        $stderr.puts "Saved lighthouse changeset #{commit.id}: #{commit.title}"
      else
        $stderr.puts "Failed to save changeset due to #{commit.errors.full_messages.join("\n")}"
      end
    end
  end
end

